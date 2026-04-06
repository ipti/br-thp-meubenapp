import 'dart:convert';
import 'dart:io';

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
      _syncQueueLocalDatasource = SyncQueueLocalDatasource(),
      _tokenStorage = TokenStorage();

  final IApiClient _apiClient;
  final MobileStoreRepository _mobileStoreRepository;
  final MeetingFoulsLocalDatasource _foulsLocalDatasource;
  final MeetingArchivesOfflineDatasource _archivesOfflineDatasource;
  final SyncQueueLocalDatasource _syncQueueLocalDatasource;
  final TokenStorage _tokenStorage;

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

    return classroom.first.meeting
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
  }

  @override
  Future<MeetingDetailModel?> getMeetingDetail({
    required int year,
    required String socialTechnologyId,
    required String projectId,
    required String classroomId,
    required String meetingId,
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

    final meeting = classroom.first.meeting.where(
      (item) => item.id.toString() == meetingId,
    );
    if (meeting.isEmpty) return null;

    final currentMeeting = meeting.first;
    final students = (currentMeeting.classroom?.registerClassroom ?? const [])
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
      archives: [...pendingArchives, ...apiArchives],
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

    await _syncQueueLocalDatasource.removePendingByTypeAndMeeting(
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
        if (item.type == SyncQueueType.fouls) {
          await _syncFouls(item);
        } else {
          await _syncArchive(item);
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

  Future<void> _syncFouls(SyncQueueItemModel item) async {
    final meetingId = int.tryParse(item.payload['meetingId']?.toString() ?? '');
    final registrationIds = _extractIntList(item.payload['registrationIds']);

    if (meetingId == null) {
      throw const ApiException('meetingId invalido na fila de sync.');
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
