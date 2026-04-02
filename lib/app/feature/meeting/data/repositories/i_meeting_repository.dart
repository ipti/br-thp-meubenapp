import 'package:br_thp_meubenapp/app/feature/meeting/data/models/meeting_item_model.dart';

abstract class IMeetingRepository {
  Future<List<MeetingItemModel>> getMeetingsByClassroom({
    required int year,
    required String socialTechnologyId,
    required String projectId,
    required String classroomId,
  });
}
