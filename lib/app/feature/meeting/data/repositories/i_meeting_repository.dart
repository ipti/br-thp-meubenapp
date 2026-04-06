import 'package:br_thp_meubenapp/app/feature/meeting/data/models/meeting_detail_model.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/models/meeting_item_model.dart';
import 'dart:io';

abstract class IMeetingRepository {
  Future<List<MeetingItemModel>> getMeetingsByClassroom({
    required int year,
    required String socialTechnologyId,
    required String projectId,
    required String classroomId,
  });

  Future<MeetingDetailModel?> getMeetingDetail({
    required int year,
    required String socialTechnologyId,
    required String projectId,
    required String classroomId,
    required String meetingId,
  });

  Future<void> saveMeetingFouls({
    required int meetingId,
    required Set<int> absentStudentIds,
  });

  Future<MeetingArchiveModel?> uploadMeetingArchive({
    required int meetingId,
    required File imageFile,
  });

  Future<void> deleteMeetingArchive({
    required int archiveId,
  });
}
