import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:br_thp_meubenapp/app/core/config/api_config.dart';
import 'package:br_thp_meubenapp/app/core/navigation/app_navigator.dart';
import 'package:br_thp_meubenapp/app/core/network/api_client.dart';
import 'package:br_thp_meubenapp/app/core/network/api_exception.dart';
import 'package:br_thp_meubenapp/app/core/network/i_api_client.dart';
import 'package:br_thp_meubenapp/app/core/storage/token/token_storage.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/archive_endpoints.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/fouls_endpoints.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/local/meeting_archives_offline_datasource.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/local/meeting_fouls_local_datasource.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/local/meeting_offline_datasource.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/meeting_endpoints.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/models/meeting_create_model.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/models/meeting_detail_model.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/models/meeting_item_model.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/repositories/i_meeting_repository.dart';
import 'package:br_thp_meubenapp/app/feature/mobile_store/data/repositories/mobile_store_repository.dart';
import 'package:br_thp_meubenapp/app/feature/sync/data/local/sync_queue_local_datasource.dart';
import 'package:br_thp_meubenapp/app/feature/sync/data/models/sync_queue_item_model.dart';
import 'package:http/http.dart' as http;

class MeetingRepository implements IMeetingRepository {
  MeetingRepository({IApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      _mobileStoreRepository = MobileStoreRepository(
        apiClient: apiClient ?? ApiClient(),
      ),
      _foulsLocalDatasource = MeetingFoulsLocalDatasource(),
      _archivesOfflineDatasource = MeetingArchivesOfflineDatasource(),
      _meetingOfflineDatasource = MeetingOfflineDatasource(),
      _syncQueueLocalDatasource = SyncQueueLocalDatasource(),
      _tokenStorage = TokenStorage();

  final IApiClient _apiClient;
  final MobileStoreRepository _mobileStoreRepository;
  final MeetingFoulsLocalDatasource _foulsLocalDatasource;
  final MeetingArchivesOfflineDatasource _archivesOfflineDatasource;
  final MeetingOfflineDatasource _meetingOfflineDatasource;
  final SyncQueueLocalDatasource _syncQueueLocalDatasource;
  final TokenStorage _tokenStorage;
  final Random _random = Random();

  @override
  Future<List<MeetingItemModel>> getMeetingsByClassroom({
    required int year,
    required String socialTechnologyId,
    required String projectId,
    required String classroomId,
  }) async {
    final snapshot = await _mobileStoreRepository.getSnapshot(year: year);
    final socialTechnology = snapshot.where(
      (item) => item.id.toString() == socialTechnologyId,
    );
    if (socialTechnology.isEmpty) return const [];

    final project = socialTechnology.first.project.where(
      (item) => item.id.toString() == projectId,
    );
    if (project.isEmpty) return const [];

    final classroom = project.first.classrooms.where(
      (item) => item.id.toString() == classroomId,
    );
    if (classroom.isEmpty) return const [];

    final apiMeetings = classroom.first.meeting
        .map(
          (meeting) => MeetingItemModel(
            id: meeting.id,
            name: meeting.name,
            fouls: _extractFoulsCount(meeting.fouls),
            classroomId: classroom.first.id,
            projectId: project.first.id,
            socialTechnologyId: socialTechnology.first.id,
            createdAt: meeting.createdAt,
          ),
        )
        .toList();

    final pendingMeetings = await _meetingOfflineDatasource
        .getPendingByClassroom(classroom.first.id);

    final pendingItems = pendingMeetings
        .map(
          (meeting) => MeetingItemModel(
            id: -meeting.localId,
            name: '${meeting.name} (pendente)',
            fouls: 0,
            isPendingSync: true,
            classroomId: classroom.first.id,
            projectId: project.first.id,
            socialTechnologyId: socialTechnology.first.id,
            createdAt: meeting.meetingDate,
          ),
        )
        .toList();

    return [...pendingItems, ...apiMeetings];
  }

  @override
  Future<MeetingDetailModel?> getMeetingDetail({
    required int year,
    required String socialTechnologyId,
    required String projectId,
    required String classroomId,
    required String meetingId,
  }) async {
    final parsedMeetingId = int.tryParse(meetingId);
    if (parsedMeetingId != null && parsedMeetingId < 0) {
      return _getPendingMeetingDetail(
        year: year,
        socialTechnologyId: socialTechnologyId,
        projectId: projectId,
        classroomId: classroomId,
        meetingLocalId: parsedMeetingId.abs(),
      );
    }

    final snapshot = await _mobileStoreRepository.getSnapshot(year: year);
    final socialTechnology = snapshot.where(
      (item) => item.id.toString() == socialTechnologyId,
    );
    if (socialTechnology.isEmpty) return null;

    final project = socialTechnology.first.project.where(
      (item) => item.id.toString() == projectId,
    );
    if (project.isEmpty) return null;

    final classroom = project.first.classrooms.where(
      (item) => item.id.toString() == classroomId,
    );
    if (classroom.isEmpty) return null;

    final meeting = classroom.first.meeting.where(
      (item) => item.id.toString() == meetingId,
    );
    if (meeting.isEmpty) return null;

    final currentMeeting = meeting.first;
    final students = (classroom.first.registerClassroom)
        .map(
          (item) => MeetingStudentModel(
            id: item.registration.id,
            name: item.registration.name,
          ),
        )
        .toList();

    final localFouls = await _foulsLocalDatasource.getFoulsByMeeting(
      currentMeeting.id,
    );
    final apiFouls = _extractAbsentStudentIds(currentMeeting.fouls);
    final initialFouls = localFouls.isNotEmpty ? localFouls : apiFouls;

    final apiArchives = currentMeeting.meetingArchives
        .map(
          (archive) => MeetingArchiveModel(
            id: archive.id,
            originalName: archive.originalName,
            archiveUrl: archive.archiveUrl,
          ),
        )
        .toList();
    final cachedRemoteArchives =
        (await _archivesOfflineDatasource.getRemoteCacheByMeeting(
              currentMeeting.id,
            ))
            .map(
              (archive) => MeetingArchiveModel(
                id: archive.archiveId,
                originalName: archive.originalName,
                archiveUrl: archive.archiveUrl,
              ),
            )
            .toList();

    final online = await _isOnline();
    List<MeetingArchiveModel> fetchedArchives = const [];
    if (online) {
      fetchedArchives = await _fetchMeetingArchivesFromApi(
        meetingId: currentMeeting.id,
      );
      await _archivesOfflineDatasource.replaceRemoteCacheByMeeting(
        meetingId: currentMeeting.id,
        archives: fetchedArchives
            .map(
              (archive) => MeetingArchiveRemoteCacheItem(
                localId: 0,
                meetingId: currentMeeting.id,
                archiveId: archive.id,
                originalName: archive.originalName,
                archiveUrl: archive.archiveUrl,
                updatedAt: DateTime.now(),
              ),
            )
            .toList(),
      );
    }

    final mergedApiArchives = _mergeArchives(
      apiArchives,
      _mergeArchives(cachedRemoteArchives, fetchedArchives),
    );

    final localArchives = await _archivesOfflineDatasource.getPendingByMeeting(
      currentMeeting.id,
    );
    final pendingArchives = localArchives
        .map(
          (archive) => MeetingArchiveModel(
            id: -archive.localId,
            originalName: archive.originalName,
            archiveUrl: '',
            isPendingSync: true,
            localPath: archive.filePath,
          ),
        )
        .toList();

    return MeetingDetailModel(
      id: currentMeeting.id,
      name: currentMeeting.name,
      createdAt: currentMeeting.createdAt,
      students: students,
      absentStudentIds: initialFouls,
      archives: [...pendingArchives, ...mergedApiArchives],
    );
  }

  Future<MeetingDetailModel?> _getPendingMeetingDetail({
    required int year,
    required String socialTechnologyId,
    required String projectId,
    required String classroomId,
    required int meetingLocalId,
  }) async {
    final snapshot = await _mobileStoreRepository.getSnapshot(year: year);
    final socialTechnology = snapshot.where(
      (item) => item.id.toString() == socialTechnologyId,
    );
    if (socialTechnology.isEmpty) return null;

    final project = socialTechnology.first.project.where(
      (item) => item.id.toString() == projectId,
    );
    if (project.isEmpty) return null;

    final classroom = project.first.classrooms.where(
      (item) => item.id.toString() == classroomId,
    );
    if (classroom.isEmpty) return null;

    final pendingMeeting = await _meetingOfflineDatasource.getByLocalId(
      meetingLocalId,
    );
    if (pendingMeeting == null) return null;

    final localMeetingId = -meetingLocalId;
    final students = classroom.first.registerClassroom
        .map(
          (item) => MeetingStudentModel(
            id: item.registration.id,
            name: item.registration.name,
          ),
        )
        .toList();

    final localFouls = await _foulsLocalDatasource.getFoulsByMeeting(
      localMeetingId,
    );
    final localArchives = await _archivesOfflineDatasource.getPendingByMeeting(
      localMeetingId,
    );
    final pendingArchives = localArchives
        .map(
          (archive) => MeetingArchiveModel(
            id: -archive.localId,
            originalName: archive.originalName,
            archiveUrl: '',
            isPendingSync: true,
            localPath: archive.filePath,
          ),
        )
        .toList();

    return MeetingDetailModel(
      id: localMeetingId,
      name: '${pendingMeeting.name} (pendente)',
      createdAt: pendingMeeting.meetingDate,
      students: students,
      absentStudentIds: localFouls,
      archives: pendingArchives,
    );
  }

  @override
  Future<void> saveMeetingFouls({
    required int meetingId,
    required Set<int> absentStudentIds,
  }) async {
    final allFouls = absentStudentIds.toList()..sort();

    await _foulsLocalDatasource.saveFoulsByMeeting(
      meetingId: meetingId,
      studentIds: absentStudentIds,
    );

    final online = await _isOnline();
    if (online && meetingId > 0) {
      try {
        await _apiClient.post(
          FoulsEndpoints.foulsBff,
          withAuthToken: true,
          body: {'meeting': meetingId, 'registration': allFouls},
        );
        await _syncQueueLocalDatasource.removeByTypeAndMeeting(
          type: SyncQueueType.fouls,
          meetingId: meetingId,
        );
        return;
      } on ApiException {
        // Em qualquer falha no envio direto, mantemos a garantia de sync local.
      } catch (_) {}
    }

    // Remove registros antigos (pending/failed/synced) desse mesmo encontro
    // para manter só o estado mais recente das faltas na fila.
    await _syncQueueLocalDatasource.removeByTypeAndMeeting(
      type: SyncQueueType.fouls,
      meetingId: meetingId,
    );

    await _syncQueueLocalDatasource.enqueue(
      type: SyncQueueType.fouls,
      payload: {'meetingId': meetingId, 'registrationIds': allFouls},
      description: 'Sincronizar faltas do encontro $meetingId',
      createdBy: await _resolveCurrentUser(),
    );
  }

  @override
  Future<MeetingArchiveModel?> uploadMeetingArchive({
    required int meetingId,
    required File imageFile,
  }) async {
    final online = await _isOnline();
    if (online && meetingId > 0) {
      try {
        return await _uploadArchiveOnlineDirect(
          meetingId: meetingId,
          imageFile: imageFile,
        );
      } on ApiException catch (e) {
        if (_isUnauthorized(e.statusCode)) rethrow;
      } catch (_) {}
    }

    final originalName = imageFile.path.split(Platform.pathSeparator).last;
    final localArchiveId = await _archivesOfflineDatasource.addPendingArchive(
      meetingId: meetingId,
      filePath: imageFile.path,
      originalName: originalName,
    );

    await _syncQueueLocalDatasource.enqueue(
      type: SyncQueueType.archives,
      payload: {'meetingId': meetingId, 'archiveLocalId': localArchiveId},
      description: 'Sincronizar arquivo "$originalName" do encontro $meetingId',
      createdBy: await _resolveCurrentUser(),
    );

    return MeetingArchiveModel(
      id: -localArchiveId,
      originalName: originalName,
      archiveUrl: '',
      isPendingSync: true,
      localPath: imageFile.path,
    );
  }

  Future<MeetingArchiveModel?> _uploadArchiveOnlineDirect({
    required int meetingId,
    required File imageFile,
  }) async {
    final token = await _tokenStorage.getToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ArchiveEndpoints.uploadByMeetingId(meetingId)}',
    );
    final request = http.MultipartRequest('POST', uri);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (_isUnauthorized(streamedResponse.statusCode)) {
      await _handleUnauthorized();
      throw const ApiException(
        'Sessao expirada. Faca login novamente.',
        statusCode: 401,
      );
    }

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      throw ApiException(
        'Falha ao enviar arquivo (${streamedResponse.statusCode}).',
        statusCode: streamedResponse.statusCode,
      );
    }

    if (responseBody.isEmpty) {
      return MeetingArchiveModel(
        id: 0,
        originalName: imageFile.path.split(Platform.pathSeparator).last,
        archiveUrl: '',
      );
    }

    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      return MeetingArchiveModel(
        id: int.tryParse(decoded['id']?.toString() ?? '') ?? 0,
        originalName:
            decoded['original_name']?.toString() ??
            imageFile.path.split(Platform.pathSeparator).last,
        archiveUrl: decoded['archive_url']?.toString() ?? '',
      );
    }

    return null;
  }

  @override
  Future<void> deleteMeetingArchive({required int archiveId}) async {
    if (archiveId < 0) {
      await _archivesOfflineDatasource.deleteByLocalId(archiveId.abs());
      return;
    }

    final token = await TokenStorage().getToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ArchiveEndpoints.deleteById(archiveId)}',
    );
    final response = await http.delete(
      uri,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (_isUnauthorized(response.statusCode)) {
      await _handleUnauthorized();
      throw const ApiException(
        'Sessao expirada. Faca login novamente.',
        statusCode: 401,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Falha ao excluir arquivo (${response.statusCode}).');
    }

    await _archivesOfflineDatasource.deleteRemoteCacheByArchiveId(archiveId);
  }

  @override
  Future<List<MeetingAssigneeModel>> getMeetingAssignableUsers() async {
    final response = await _apiClient.get(
      MeetingEndpoints.usersBff,
      withAuthToken: true,
    );

    final items = _extractListMaps(response.data);
    final users = items
        .map((item) {
          final id = int.tryParse(item['id']?.toString() ?? '');
          if (id == null) return null;
          return MeetingAssigneeModel(
            id: id,
            name: item['name']?.toString() ?? 'Usuário',
            role: item['role']?.toString() ?? '',
            active: item['active'] == true,
          );
        })
        .whereType<MeetingAssigneeModel>()
        .where((user) => user.active)
        .toList();

    users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return users;
  }

  @override
  Future<MeetingCreateResult> createMeeting({
    required MeetingCreateRequestModel request,
  }) async {
    final requestWithId =
        request.requestId == null || request.requestId!.isEmpty
        ? MeetingCreateRequestModel(
            requestId: _generateRequestId(),
            name: request.name,
            meetingDate: request.meetingDate,
            workload: request.workload,
            classroomId: request.classroomId,
            theme: request.theme,
            users: request.users,
          )
        : request;

    final online = await _isOnline();

    if (online) {
      try {
        await _createMeetingOnline(requestWithId);
        return const MeetingCreateResult(
          createdOnline: true,
          queuedOffline: false,
          message: 'Encontro criado com sucesso.',
        );
      } on ApiException catch (e) {
        if (_isUnauthorized(e.statusCode)) rethrow;
        if (e.statusCode != null && e.statusCode! < 500) rethrow;
      }
    }

    await _enqueueMeetingCreate(requestWithId);
    return const MeetingCreateResult(
      createdOnline: false,
      queuedOffline: true,
      message: 'Encontro salvo localmente e aguardando sincronização.',
    );
  }

  @override
  Future<List<SyncQueueItemModel>> getSyncQueueItems() {
    return _syncQueueLocalDatasource.getAll();
  }

  @override
  Future<SyncExecutionResult> syncPendingActions() async {
    final online = await _isOnline();
    if (!online) {
      final remaining = await _syncQueueLocalDatasource.getPendingAndFailed();
      return SyncExecutionResult(
        successCount: 0,
        failedCount: 0,
        remainingCount: remaining.length,
        requiresLogin: false,
        lastError: 'Sem conexao com a internet.',
      );
    }

    final items = await _syncQueueLocalDatasource.getPendingAndFailed();
    var successCount = 0;
    var failedCount = 0;
    var requiresLogin = false;
    String? lastError;

    for (final item in items) {
      await _syncQueueLocalDatasource.markAsProcessing(item.localId);

      try {
        switch (item.type) {
          case SyncQueueType.fouls:
            await _syncFouls(item);
            break;
          case SyncQueueType.archives:
            await _syncArchive(item);
            break;
          case SyncQueueType.meetingCreate:
            await _syncMeetingCreate(item);
            break;
        }

        await _syncQueueLocalDatasource.markAsSynced(item.localId);
        successCount += 1;
      } on ApiException catch (e) {
        failedCount += 1;
        lastError = e.message;
        if (_isUnauthorized(e.statusCode)) {
          requiresLogin = true;
        }
        await _syncQueueLocalDatasource.markAsFailed(
          item.localId,
          errorMessage: e.message,
        );
        if (requiresLogin) break;
      } catch (e) {
        failedCount += 1;
        lastError = e.toString();
        await _syncQueueLocalDatasource.markAsFailed(
          item.localId,
          errorMessage: e.toString(),
        );
      }
    }

    final remaining = await _syncQueueLocalDatasource.getPendingAndFailed();
    return SyncExecutionResult(
      successCount: successCount,
      failedCount: failedCount,
      remainingCount: remaining.length,
      requiresLogin: requiresLogin,
      lastError: lastError,
    );
  }

  @override
  Future<void> deleteSyncQueueItem(SyncQueueItemModel item) async {
    await _syncQueueLocalDatasource.deleteByLocalId(item.localId);

    final meetingId = int.tryParse(item.payload['meetingId']?.toString() ?? '');
    switch (item.type) {
      case SyncQueueType.fouls:
        if (meetingId != null) {
          await _foulsLocalDatasource.clearFoulsByMeeting(meetingId);
        }
        break;
      case SyncQueueType.archives:
        final archiveLocalId = int.tryParse(
          item.payload['archiveLocalId']?.toString() ?? '',
        );
        if (archiveLocalId != null) {
          await _archivesOfflineDatasource.deleteByLocalId(archiveLocalId);
        }
        break;
      case SyncQueueType.meetingCreate:
        final meetingOfflineId = int.tryParse(
          item.payload['meetingOfflineId']?.toString() ?? '',
        );
        if (meetingOfflineId != null) {
          final localMeetingId = -meetingOfflineId;
          await _meetingOfflineDatasource.deleteByLocalId(meetingOfflineId);
          await _foulsLocalDatasource.clearFoulsByMeeting(localMeetingId);
          await _archivesOfflineDatasource.deleteByMeetingId(localMeetingId);
          await _syncQueueLocalDatasource.removeByTypeAndMeeting(
            type: SyncQueueType.fouls,
            meetingId: localMeetingId,
          );
          await _syncQueueLocalDatasource.removeByTypeAndMeeting(
            type: SyncQueueType.archives,
            meetingId: localMeetingId,
          );
        }
        break;
    }
  }

  Future<void> _syncFouls(SyncQueueItemModel item) async {
    final meetingId = int.tryParse(item.payload['meetingId']?.toString() ?? '');
    final registrationIds = _extractIntList(item.payload['registrationIds']);

    if (meetingId == null) {
      throw const ApiException('meetingId invalido na fila de sync.');
    }
    if (meetingId < 0) {
      // Meeting ainda não sincronizado; o pacote será enviado em meetingCreate.
      return;
    }

    await _apiClient.post(
      FoulsEndpoints.foulsBff,
      withAuthToken: true,
      body: {
        'meeting': meetingId,
        'registration': registrationIds,
        'source': 'OFFLINE_SYNC',
      },
    );
  }

  Future<void> _syncArchive(SyncQueueItemModel item) async {
    final meetingId = int.tryParse(item.payload['meetingId']?.toString() ?? '');
    final archiveLocalId = int.tryParse(
      item.payload['archiveLocalId']?.toString() ?? '',
    );

    if (meetingId == null || archiveLocalId == null) {
      throw const ApiException('Payload invalido na fila de arquivos.');
    }
    if (meetingId < 0) {
      // Meeting ainda não sincronizado; o pacote será enviado em meetingCreate.
      return;
    }

    final archive = await _archivesOfflineDatasource.getByLocalId(
      archiveLocalId,
    );
    if (archive == null) {
      return;
    }

    final file = File(archive.filePath);
    if (!await file.exists()) {
      throw ApiException(
        'Arquivo local nao encontrado: ${archive.originalName}',
      );
    }

    await _uploadArchiveOnline(meetingId: meetingId, imageFile: file);
    await _archivesOfflineDatasource.deleteByLocalId(archiveLocalId);
  }

  Future<void> _syncMeetingCreate(SyncQueueItemModel item) async {
    final meetingOfflineId = int.tryParse(
      item.payload['meetingOfflineId']?.toString() ?? '',
    );
    if (meetingOfflineId == null) {
      throw const ApiException('meetingOfflineId inválido na fila.');
    }

    final pendingMeeting = await _meetingOfflineDatasource.getByLocalId(
      meetingOfflineId,
    );
    if (pendingMeeting == null) return;
    final localMeetingId = -meetingOfflineId;

    await _syncOfflineMeetingBundle(
      pendingMeeting: pendingMeeting,
      localMeetingId: localMeetingId,
    );

    await _meetingOfflineDatasource.deleteByLocalId(meetingOfflineId);
    await _foulsLocalDatasource.clearFoulsByMeeting(localMeetingId);
    await _archivesOfflineDatasource.deleteByMeetingId(localMeetingId);
    await _syncQueueLocalDatasource.removeByTypeAndMeeting(
      type: SyncQueueType.fouls,
      meetingId: localMeetingId,
    );
    await _syncQueueLocalDatasource.removeByTypeAndMeeting(
      type: SyncQueueType.archives,
      meetingId: localMeetingId,
    );
  }

  Future<void> _syncOfflineMeetingBundle({
    required MeetingOfflineItem pendingMeeting,
    required int localMeetingId,
  }) async {
    final fouls = await _foulsLocalDatasource.getFoulsByMeeting(localMeetingId);
    final archives = await _archivesOfflineDatasource.getPendingByMeeting(
      localMeetingId,
    );

    final requestModel = pendingMeeting.toRequestModel();
    final payload = {
      'requestId': requestModel.requestId ?? _generateRequestId(),
      'source': 'OFFLINE_SYNC',
      'meeting': requestModel.toJson(),
      'fouls': fouls.toList()..sort(),
    };

    final token = await _tokenStorage.getToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${MeetingEndpoints.meetingBffSyncOffline}',
    );
    final request = http.MultipartRequest('POST', uri);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields['payload'] = jsonEncode(payload);

    for (final archive in archives) {
      final file = File(archive.filePath);
      if (!await file.exists()) continue;
      request.files.add(await http.MultipartFile.fromPath('files', file.path));
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (_isUnauthorized(response.statusCode)) {
      await _handleUnauthorized();
      throw const ApiException(
        'Sessao expirada. Faca login novamente.',
        statusCode: 401,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Falha ao sincronizar pacote offline (${response.statusCode}). $responseBody',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> _createMeetingOnline(MeetingCreateRequestModel request) async {
    await _apiClient.post(
      MeetingEndpoints.meeting,
      withAuthToken: true,
      body: request.toJson(),
    );
  }

  Future<void> _enqueueMeetingCreate(MeetingCreateRequestModel request) async {
    final meetingOfflineId = await _meetingOfflineDatasource.addPendingMeeting(
      request: request,
    );
    final localMeetingId = -meetingOfflineId;
    await _syncQueueLocalDatasource.enqueue(
      type: SyncQueueType.meetingCreate,
      payload: {
        'meetingOfflineId': meetingOfflineId,
        'meetingId': localMeetingId,
      },
      description: 'Sincronizar criação do encontro "${request.name}"',
      createdBy: await _resolveCurrentUser(),
    );
  }

  Future<void> _uploadArchiveOnline({
    required int meetingId,
    required File imageFile,
  }) async {
    final token = await _tokenStorage.getToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ArchiveEndpoints.uploadByMeetingId(meetingId, source: 'OFFLINE_SYNC')}',
    );
    final request = http.MultipartRequest('POST', uri);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (_isUnauthorized(streamedResponse.statusCode)) {
      await _handleUnauthorized();
      throw const ApiException(
        'Sessao expirada. Faca login novamente.',
        statusCode: 401,
      );
    }

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      throw ApiException(
        'Falha ao enviar arquivo (${streamedResponse.statusCode}). $responseBody',
        statusCode: streamedResponse.statusCode,
      );
    }
  }

  int _extractFoulsCount(dynamic fouls) {
    return _extractAbsentStudentIds(fouls).length;
  }

  Set<int> _extractAbsentStudentIds(dynamic fouls) {
    final entries = _normalizeFoulsEntries(fouls);
    if (entries.isNotEmpty) {
      final ids = <int>{};
      for (final entry in entries) {
        if (entry is Map<String, dynamic>) {
          final idValue = entry['registration_fk'];
          final id = int.tryParse(idValue?.toString() ?? '');
          if (id != null) ids.add(id);
        }
      }
      return ids;
    }
    return {};
  }

  List<dynamic> _normalizeFoulsEntries(dynamic fouls) {
    if (fouls is List) return fouls;
    if (fouls is Map<String, dynamic>) {
      return _extractFoulsList(fouls);
    }
    return const [];
  }

  List<dynamic> _extractFoulsList(Map<String, dynamic> foulsMap) {
    final candidate =
        foulsMap['items'] ??
        foulsMap['students'] ??
        foulsMap['fouls'] ??
        foulsMap['registrations'] ??
        foulsMap['data'];
    if (candidate is List) return candidate;
    return const [];
  }

  List<int> _extractIntList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => int.tryParse(item.toString()))
        .whereType<int>()
        .toList();
  }

  List<Map<String, dynamic>> _extractListMaps(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      final content = data['content'] ?? data['items'] ?? data['data'];
      if (content is List) {
        return content.whereType<Map<String, dynamic>>().toList();
      }
      return [data];
    }
    return const [];
  }

  Future<List<MeetingArchiveModel>> _fetchMeetingArchivesFromApi({
    required int meetingId,
  }) async {
    try {
      final response = await _apiClient.get(
        ArchiveEndpoints.byMeetingId(meetingId),
        withAuthToken: true,
      );
      final maps = _extractArchiveMaps(response.data);
      return maps
          .map((item) {
            final id = int.tryParse(item['id']?.toString() ?? '') ?? 0;
            final originalName =
                item['original_name']?.toString() ??
                item['originalName']?.toString() ??
                item['name']?.toString() ??
                'Arquivo';
            final archiveUrl =
                item['archive_url']?.toString() ??
                item['archiveUrl']?.toString() ??
                item['url']?.toString() ??
                '';
            return MeetingArchiveModel(
              id: id,
              originalName: originalName,
              archiveUrl: archiveUrl,
            );
          })
          .where(
            (item) =>
                item.originalName.isNotEmpty || item.archiveUrl.isNotEmpty,
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<Map<String, dynamic>> _extractArchiveMaps(dynamic data) {
    if (data is Map<String, dynamic>) {
      final raw =
          data['meeting_archives'] ??
          data['archives'] ??
          data['items'] ??
          data['data'];
      if (raw is List) {
        return raw.whereType<Map<String, dynamic>>().toList();
      }
      if (raw is Map<String, dynamic>) {
        return [raw];
      }
      return const [];
    }
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  List<MeetingArchiveModel> _mergeArchives(
    List<MeetingArchiveModel> fromSnapshot,
    List<MeetingArchiveModel> fromEndpoint,
  ) {
    final merged = <String, MeetingArchiveModel>{};

    String keyFor(MeetingArchiveModel item) {
      if (item.id > 0) return 'id:${item.id}';
      if (item.archiveUrl.isNotEmpty) return 'url:${item.archiveUrl}';
      return 'name:${item.originalName}';
    }

    for (final item in [...fromSnapshot, ...fromEndpoint]) {
      merged[keyFor(item)] = item;
    }

    return merged.values.toList();
  }

  String _generateRequestId() {
    String block(int length) {
      final chars = 'abcdef0123456789';
      return List.generate(
        length,
        (_) => chars[_random.nextInt(chars.length)],
      ).join();
    }

    return '${block(8)}-${block(4)}-4${block(3)}-a${block(3)}-${block(12)}';
  }

  Future<String> _resolveCurrentUser() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) return 'usuario';

    try {
      final parts = token.split('.');
      if (parts.length < 2) return 'usuario';
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final map = jsonDecode(payload);
      if (map is Map<String, dynamic>) {
        final username =
            map['username'] ?? map['name'] ?? map['email'] ?? map['sub'];
        if (username != null && username.toString().trim().isNotEmpty) {
          return username.toString();
        }
      }
    } catch (_) {
      return 'usuario';
    }

    return 'usuario';
  }

  Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('one.one.one.one');
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool _isUnauthorized(int? statusCode) {
    return statusCode == 401 || statusCode == 403;
  }

  Future<void> _handleUnauthorized() async {
    await _tokenStorage.clearToken();
    AppNavigator.redirectToLogin();
  }
}
