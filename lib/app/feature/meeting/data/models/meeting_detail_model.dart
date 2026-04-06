class MeetingDetailModel {
  final int id;
  final String name;
  final DateTime createdAt;
  final List<MeetingStudentModel> students;
  final Set<int> absentStudentIds;
  final List<MeetingArchiveModel> archives;

  const MeetingDetailModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.students,
    required this.absentStudentIds,
    required this.archives,
  });
}

class MeetingStudentModel {
  final int id;
  final String name;

  const MeetingStudentModel({
    required this.id,
    required this.name,
  });
}

class MeetingArchiveModel {
  final int id;
  final String originalName;
  final String archiveUrl;

  const MeetingArchiveModel({
    required this.id,
    required this.originalName,
    required this.archiveUrl,
  });
}
