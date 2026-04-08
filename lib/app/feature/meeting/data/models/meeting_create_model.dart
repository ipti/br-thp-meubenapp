class MeetingAssigneeModel {
  const MeetingAssigneeModel({
    required this.id,
    required this.name,
    required this.role,
    required this.active,
  });

  final int id;
  final String name;
  final String role;
  final bool active;
}

class MeetingCreateRequestModel {
  const MeetingCreateRequestModel({
    required this.name,
    required this.meetingDate,
    required this.workload,
    required this.classroomId,
    this.theme = '',
    this.users = const [],
    this.requestId,
  });

  final String name;
  final DateTime meetingDate;
  final int workload;
  final int classroomId;
  final String theme;
  final List<int> users;
  final String? requestId;

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'meeting_date': meetingDate.toIso8601String(),
      'workload': workload,
      'classroom': classroomId,
      'theme': theme,
      'users': users,
    };
  }
}

class MeetingCreateResult {
  const MeetingCreateResult({
    required this.createdOnline,
    required this.queuedOffline,
    this.message,
  });

  final bool createdOnline;
  final bool queuedOffline;
  final String? message;
}
