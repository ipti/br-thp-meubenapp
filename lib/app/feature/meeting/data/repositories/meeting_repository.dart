import 'package:br_thp_meubenapp/app/core/network/i_api_client.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/models/meeting_item_model.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/repositories/i_meeting_repository.dart';
import 'package:br_thp_meubenapp/app/feature/mobile_store/data/repositories/mobile_store_repository.dart';

class MeetingRepository implements IMeetingRepository {
  MeetingRepository({required IApiClient apiClient})
      : _mobileStoreRepository = MobileStoreRepository(apiClient: apiClient);

  final MobileStoreRepository _mobileStoreRepository;

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
            fouls: meeting.fouls,
            classroomId: classroom.first.id,
            projectId: project.first.id,
            socialTechnologyId: socialTechnology.first.id,
          ),
        )
        .toList();
  }
}
