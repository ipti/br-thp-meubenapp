import 'package:br_thp_meubenapp/app/core/storage/local/local_database.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/models/meeting_create_model.dart';
import 'package:sembast/sembast.dart';

class MeetingOfflineItem {
  const MeetingOfflineItem({
    required this.localId,
    required this.requestId,
    required this.name,
    required this.meetingDate,
    required this.workload,
    required this.classroomId,
    required this.theme,
    required this.users,
    required this.createdAt,
  });

  final int localId;
  final String requestId;
  final String name;
  final DateTime meetingDate;
  final int workload;
  final int classroomId;
  final String theme;
  final List<int> users;
  final DateTime createdAt;

  MeetingCreateRequestModel toRequestModel() {
    return MeetingCreateRequestModel(
      requestId: requestId,
      name: name,
      meetingDate: meetingDate,
      workload: workload,
      classroomId: classroomId,
      theme: theme,
      users: users,
    );
  }
}

class MeetingOfflineDatasource {
  MeetingOfflineDatasource({LocalDatabase? localDatabase})
    : _localDatabase = localDatabase ?? LocalDatabase.instance;

  final LocalDatabase _localDatabase;
  final StoreRef<int, Map<String, Object?>> _store = intMapStoreFactory.store(
    'meeting_offline',
  );

  Future<int> addPendingMeeting({
    required MeetingCreateRequestModel request,
  }) async {
    final db = await _localDatabase.database;
    return _store.add(db, {
      'requestId': request.requestId,
      'name': request.name,
      'meetingDate': request.meetingDate.toIso8601String(),
      'workload': request.workload,
      'classroomId': request.classroomId,
      'theme': request.theme,
      'users': request.users,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<MeetingOfflineItem>> getPendingByClassroom(
    int classroomId,
  ) async {
    final db = await _localDatabase.database;
    final snapshots = await _store.find(
      db,
      finder: Finder(
        filter: Filter.equals('classroomId', classroomId),
        sortOrders: [SortOrder('meetingDate')],
      ),
    );
    return snapshots.map(_fromSnapshot).toList();
  }

  Future<MeetingOfflineItem?> getByLocalId(int localId) async {
    final db = await _localDatabase.database;
    final map = await _store.record(localId).get(db);
    if (map == null) return null;
    return _fromMap(localId, map);
  }

  Future<void> deleteByLocalId(int localId) async {
    final db = await _localDatabase.database;
    await _store.record(localId).delete(db);
  }

  MeetingOfflineItem _fromSnapshot(
    RecordSnapshot<int, Map<String, Object?>> snapshot,
  ) {
    return _fromMap(snapshot.key, snapshot.value);
  }

  MeetingOfflineItem _fromMap(int localId, Map<String, Object?> map) {
    final usersRaw = map['users'];
    final users = <int>[];
    if (usersRaw is List) {
      for (final user in usersRaw) {
        final id = int.tryParse(user.toString());
        if (id != null) users.add(id);
      }
    }

    return MeetingOfflineItem(
      localId: localId,
      requestId: map['requestId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      meetingDate:
          DateTime.tryParse(map['meetingDate']?.toString() ?? '') ??
          DateTime.now(),
      workload: int.tryParse(map['workload']?.toString() ?? '') ?? 0,
      classroomId: int.tryParse(map['classroomId']?.toString() ?? '') ?? 0,
      theme: map['theme']?.toString() ?? '',
      users: users,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
