class MeetingItemModel {
  final int id;
  final String name;
  final int fouls;
  final int classroomId;
  final int projectId;
  final int socialTechnologyId;

  const MeetingItemModel({
    required this.id,
    required this.name,
    required this.fouls,
    required this.classroomId,
    required this.projectId,
    required this.socialTechnologyId,
  });
}
