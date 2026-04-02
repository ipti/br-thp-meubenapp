import 'package:br_thp_meubenapp/app/feature/mobile_store/data/models/mobile_store_snapshot_model.dart';

class SocialTechnologyOneModel {
  final int id;
  final String name;
  final dynamic avartarUrl;
  final String areaOfActivity;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProjectModel> project;

  const SocialTechnologyOneModel({
    required this.id,
    required this.name,
    required this.avartarUrl,
    required this.areaOfActivity,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    required this.project,
  });

  factory SocialTechnologyOneModel.fromJson(Map<String, dynamic> json) {
    return SocialTechnologyOneModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      avartarUrl: json['avartar_url'],
      areaOfActivity: json['area_of_activity']?.toString() ?? '',
      active: _toBool(json['active']),
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
      project: _toProjectList(json['project']),
    );
  }

  factory SocialTechnologyOneModel.empty() {
    return SocialTechnologyOneModel(
      id: 0,
      name: '',
      avartarUrl: null,
      areaOfActivity: '',
      active: false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      project: const [],
    );
  }

  factory SocialTechnologyOneModel.fromMobileStore(
    MobileStoreSnapshotModel model,
  ) {
    return SocialTechnologyOneModel(
      id: model.id,
      name: model.name,
      avartarUrl: model.avartarUrl,
      areaOfActivity: model.areaOfActivity,
      active: model.active,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      project: model.project.map(ProjectModel.fromMobileStore).toList(),
    );
  }

  static MobileStoreSnapshotModel emptyFromMobileStore() {
    return MobileStoreSnapshotModel(
      id: 0,
      name: '',
      avartarUrl: null,
      areaOfActivity: '',
      active: false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      project: [],
    );
  }

  static List<ProjectModel> _toProjectList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(ProjectModel.fromJson)
          .toList();
    }
    return const [];
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }

  static DateTime _toDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class ProjectModel {
  final int id;
  final String name;
  final bool active;
  final double approvalPercentage;
  final String? rulerUrl;
  final dynamic avartarUrl;
  final int socialTechnologyId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.active,
    required this.approvalPercentage,
    this.rulerUrl,
    required this.avartarUrl,
    required this.socialTechnologyId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: SocialTechnologyOneModel._toInt(json['id']),
      name: json['name']?.toString() ?? '',
      active: SocialTechnologyOneModel._toBool(json['active']),
      approvalPercentage:
          double.tryParse(json['approval_percentage']?.toString() ?? '') ?? 0.0,
      rulerUrl: json['ruler_url']?.toString(),
      avartarUrl: json['avartar_url'],
      socialTechnologyId:
          SocialTechnologyOneModel._toInt(json['social_technology_id']),
      createdAt: SocialTechnologyOneModel._toDate(json['createdAt']),
      updatedAt: SocialTechnologyOneModel._toDate(json['updatedAt']),
    );
  }

  factory ProjectModel.fromMobileStore(MobileStoreProjectModel model) {
    return ProjectModel(
      id: model.id,
      name: model.name,
      active: model.active,
      approvalPercentage: model.approvalPercentage,
      rulerUrl: model.rulerUrl,
      avartarUrl: model.avartarUrl,
      socialTechnologyId: model.socialTechnologyId,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}
