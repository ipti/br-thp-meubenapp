import 'dart:io';
import 'dart:convert';

import 'package:br_thp_meubenapp/app/core/config/api_config.dart';
import 'package:br_thp_meubenapp/app/core/network/api_client.dart';
import 'package:br_thp_meubenapp/app/core/storage/token/token_storage.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/archive_endpoints.dart';
import 'package:br_thp_meubenapp/app/core/network/i_api_client.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/fouls_endpoints.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/local/meeting_fouls_local_datasource.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/models/meeting_detail_model.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/models/meeting_item_model.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/repositories/i_meeting_repository.dart';
import 'package:br_thp_meubenapp/app/feature/mobile_store/data/repositories/mobile_store_repository.dart';
import 'package:http/http.dart' as http;

class MeetingRepository implements IMeetingRepository {
  MeetingRepository({IApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        _mobileStoreRepository = MobileStoreRepository(
          apiClient: apiClient ?? ApiClient(),
        ),
        _foulsLocalDatasource = MeetingFoulsLocalDatasource();

  final IApiClient _apiClient;
  final MobileStoreRepository _mobileStoreRepository;
  final MeetingFoulsLocalDatasource _foulsLocalDatasource;

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

    return MeetingDetailModel(
      id: currentMeeting.id,
      name: currentMeeting.name,
      createdAt: currentMeeting.createdAt,
      students: students,
      absentStudentIds: initialFouls,
      archives: currentMeeting.meetingArchives
          .map(
            (archive) => MeetingArchiveModel(
              id: archive.id,
              originalName: archive.originalName,
              archiveUrl: archive.archiveUrl,
            ),
          )
          .toList(),
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
    if (!online) return;

    await _apiClient.post(
      FoulsEndpoints.foulsBff,
      withAuthToken: true,
      body: {
        'meeting': meetingId,
        'registration': allFouls,
      },
    );
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

  Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('one.one.one.one');
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<MeetingArchiveModel?> uploadMeetingArchive({
    required int meetingId,
    required File imageFile,
  }) async {
    final token = await TokenStorage().getToken();
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

    if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
      throw Exception('Falha ao enviar arquivo (${streamedResponse.statusCode}).');
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Falha ao excluir arquivo (${response.statusCode}).');
    }
  }
}
