class WorkPlanRequestDto {
  final String title;
  final String description;
  final bool active;

  const WorkPlanRequestDto({
    required this.title,
    required this.description,
    required this.active,
  });

  Map<String, dynamic> toJson() {
    return {'title': title, 'description': description, 'active': active};
  }
}
