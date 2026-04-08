class MobileStoreSnapshotModel {
  final int id;
  final String name;
  final String? avartarUrl;
  final String areaOfActivity;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MobileStoreProjectModel> project;

  const MobileStoreSnapshotModel({
    required this.id,
    required this.name,
    required this.avartarUrl,
    required this.areaOfActivity,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    required this.project,
  });

  factory MobileStoreSnapshotModel.fromJson(Map<String, dynamic> json) {
    return MobileStoreSnapshotModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      avartarUrl: json['avartar_url']?.toString(),
      areaOfActivity: json['area_of_activity']?.toString() ?? '',
      active: _toBool(json['active']),
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
      project: _toList(
        json['project'],
      ).map(MobileStoreProjectModel.fromJson).toList(),
    );
  }

  static List<Map<String, dynamic>> _toList(dynamic value) {
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
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

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static DateTime _toDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class MobileStoreProjectModel {
  final int id;
  final String name;
  final bool active;
  final double approvalPercentage;
  final String? rulerUrl;
  final String? avartarUrl;
  final int socialTechnologyId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MobileStoreClassroomModel> classrooms;

  const MobileStoreProjectModel({
    required this.id,
    required this.name,
    required this.active,
    required this.approvalPercentage,
    this.rulerUrl,
    required this.avartarUrl,
    required this.socialTechnologyId,
    required this.createdAt,
    required this.updatedAt,
    required this.classrooms,
  });

  factory MobileStoreProjectModel.fromJson(Map<String, dynamic> json) {
    return MobileStoreProjectModel(
      id: MobileStoreSnapshotModel._toInt(json['id']),
      name: json['name']?.toString() ?? '',
      active: MobileStoreSnapshotModel._toBool(json['active']),
      approvalPercentage: MobileStoreSnapshotModel._toDouble(
        json['approval_percentage'],
      ),
      rulerUrl: json['ruler_url']?.toString(),
      avartarUrl: json['avartar_url']?.toString(),
      socialTechnologyId: MobileStoreSnapshotModel._toInt(
        json['social_technology_id'],
      ),
      createdAt: MobileStoreSnapshotModel._toDate(json['createdAt']),
      updatedAt: MobileStoreSnapshotModel._toDate(json['updatedAt']),
      classrooms: MobileStoreSnapshotModel._toList(
        json['classrooms'],
      ).map(MobileStoreClassroomModel.fromJson).toList(),
    );
  }
}

class MobileStoreClassroomModel {
  final int id;
  final String name;
  final DateTime createdAt;
  final List<MobileStoreRegisterClassroomModel> registerClassroom;
  final List<MobileStoreMeetingModel> meeting;

  const MobileStoreClassroomModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.registerClassroom,
    required this.meeting,
  });

  factory MobileStoreClassroomModel.fromJson(Map<String, dynamic> json) {
    return MobileStoreClassroomModel(
      id: MobileStoreSnapshotModel._toInt(json['id']),
      name: json['name']?.toString() ?? '',
      createdAt: MobileStoreSnapshotModel._toDate(json['createdAt']),
      registerClassroom: MobileStoreSnapshotModel._toList(
        json['register_classroom'],
      ).map(MobileStoreRegisterClassroomModel.fromJson).toList(),
      meeting: MobileStoreSnapshotModel._toList(
        json['meeting'],
      ).map(MobileStoreMeetingModel.fromJson).toList(),
    );
  }
}

class MobileStoreMeetingModel {
  final int id;
  final String name;
  final DateTime createdAt;
  final dynamic fouls;
  final List<MobileStoreMeetingArchiveModel> meetingArchives;

  const MobileStoreMeetingModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.fouls,
    required this.meetingArchives,
  });

  factory MobileStoreMeetingModel.fromJson(Map<String, dynamic> json) {
    return MobileStoreMeetingModel(
      id: MobileStoreSnapshotModel._toInt(json['id']),
      name: json['name']?.toString() ?? '',
      createdAt: MobileStoreSnapshotModel._toDate(json['createdAt']),
      fouls: json['fouls'],
      meetingArchives: MobileStoreSnapshotModel._toList(
        json['meeting_archives'],
      ).map(MobileStoreMeetingArchiveModel.fromJson).toList(),
    );
  }
}

class MobileStoreRegisterClassroomModel {
  final MobileStoreRegistrationModel registration;

  const MobileStoreRegisterClassroomModel({required this.registration});

  factory MobileStoreRegisterClassroomModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final registrationJson = json['registration'];
    return MobileStoreRegisterClassroomModel(
      registration: registrationJson is Map<String, dynamic>
          ? MobileStoreRegistrationModel.fromJson(registrationJson)
          : const MobileStoreRegistrationModel(id: 0, name: ''),
    );
  }
}

class MobileStoreRegistrationModel {
  final int id;
  final String name;

  const MobileStoreRegistrationModel({required this.id, required this.name});

  factory MobileStoreRegistrationModel.fromJson(Map<String, dynamic> json) {
    return MobileStoreRegistrationModel(
      id: MobileStoreSnapshotModel._toInt(json['id']),
      name: json['name']?.toString() ?? '',
    );
  }
}

class MobileStoreMeetingArchiveModel {
  final int id;
  final String originalName;
  final String archiveUrl;

  const MobileStoreMeetingArchiveModel({
    required this.id,
    required this.originalName,
    required this.archiveUrl,
  });

  factory MobileStoreMeetingArchiveModel.fromJson(Map<String, dynamic> json) {
    return MobileStoreMeetingArchiveModel(
      id: MobileStoreSnapshotModel._toInt(json['id']),
      originalName: json['original_name']?.toString() ?? '',
      archiveUrl: json['archive_url']?.toString() ?? '',
    );
  }
}
