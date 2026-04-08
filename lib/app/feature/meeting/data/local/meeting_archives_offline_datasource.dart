import 'package:br_thp_meubenapp/app/core/storage/local/local_database.dart';
import 'package:sembast/sembast.dart';

class MeetingArchiveOfflineItem {
  const MeetingArchiveOfflineItem({
    required this.localId,
    required this.meetingId,
    required this.filePath,
    required this.originalName,
    required this.createdAt,
  });

  final int localId;
  final int meetingId;
  final String filePath;
  final String originalName;
  final DateTime createdAt;
}

class MeetingArchivesOfflineDatasource {
  MeetingArchivesOfflineDatasource({LocalDatabase? localDatabase})
    : _localDatabase = localDatabase ?? LocalDatabase.instance;

  final LocalDatabase _localDatabase;
  final StoreRef<int, Map<String, Object?>> _store = intMapStoreFactory.store(
    'archives_meeting_offline',
  );

  Future<int> addPendingArchive({
    required int meetingId,
    required String filePath,
    required String originalName,
  }) async {
    final db = await _localDatabase.database;
    return _store.add(db, {
      'meetingId': meetingId,
      'filePath': filePath,
      'originalName': originalName,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<MeetingArchiveOfflineItem>> getPendingByMeeting(
    int meetingId,
  ) async {
    final db = await _localDatabase.database;
    final snapshots = await _store.find(
      db,
      finder: Finder(
        filter: Filter.equals('meetingId', meetingId),
        sortOrders: [SortOrder('createdAt')],
      ),
    );
    return snapshots.map(_fromSnapshot).toList();
  }

  Future<MeetingArchiveOfflineItem?> getByLocalId(int localId) async {
    final db = await _localDatabase.database;
    final map = await _store.record(localId).get(db);
    if (map == null) return null;
    return _fromMap(localId, map);
  }

  Future<void> deleteByLocalId(int localId) async {
    final db = await _localDatabase.database;
    await _store.record(localId).delete(db);
  }

  Future<void> deleteByMeetingId(int meetingId) async {
    final db = await _localDatabase.database;
    await _store.delete(
      db,
      finder: Finder(filter: Filter.equals('meetingId', meetingId)),
    );
  }

  MeetingArchiveOfflineItem _fromSnapshot(
    RecordSnapshot<int, Map<String, Object?>> snapshot,
  ) {
    return _fromMap(snapshot.key, snapshot.value);
  }

  MeetingArchiveOfflineItem _fromMap(int localId, Map<String, Object?> map) {
    return MeetingArchiveOfflineItem(
      localId: localId,
      meetingId: int.tryParse(map['meetingId']?.toString() ?? '') ?? 0,
      filePath: map['filePath']?.toString() ?? '',
      originalName: map['originalName']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
