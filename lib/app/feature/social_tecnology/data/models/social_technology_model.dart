class SocialTechnologyModel {
  final int id;
  final String name;
  final dynamic avartarUrl;
  final String areaOfActivity;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SocialTechnologyModel({
    required this.id,
    required this.name,
    required this.avartarUrl,
    required this.areaOfActivity,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SocialTechnologyModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawName = json['name'];
    final rawArea = json['area_of_activity'];
    final rawActive = json['active'];
    final rawCreatedAt = json['createdAt'];
    final rawUpdatedAt = json['updatedAt'];

    return SocialTechnologyModel(
      id: rawId is int
          ? rawId
          : rawId is num
          ? rawId.toInt()
          : int.tryParse('$rawId') ?? 0,
      name: rawName?.toString() ?? '',
      avartarUrl: json['avartar_url'],
      areaOfActivity: rawArea?.toString() ?? '',
      active: rawActive is bool
          ? rawActive
          : rawActive?.toString().toLowerCase() == 'true',
      createdAt:
          DateTime.tryParse(rawCreatedAt?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(rawUpdatedAt?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
