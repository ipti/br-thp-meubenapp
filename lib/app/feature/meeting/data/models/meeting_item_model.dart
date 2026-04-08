class MeetingItemModel {
  final int id;
  final String name;
  final int fouls;
  final bool isPendingSync;
  final int classroomId;
  final int projectId;
  final int socialTechnologyId;
  final DateTime createdAt;

  const MeetingItemModel({
    required this.id,
    required this.name,
    required this.fouls,
    this.isPendingSync = false,
    required this.classroomId,
    required this.projectId,
    required this.socialTechnologyId,
    required this.createdAt,
  });
}
