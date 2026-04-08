import 'package:br_thp_meubenapp/app/core/storage/local/local_database.dart';
import 'package:sembast/sembast.dart';

class MeetingFoulsLocalDatasource {
  MeetingFoulsLocalDatasource({LocalDatabase? localDatabase})
    : _localDatabase = localDatabase ?? LocalDatabase.instance;

  final LocalDatabase _localDatabase;
  final StoreRef<int, Map<String, Object?>> _store = intMapStoreFactory.store(
    'fouls_offline',
  );

  Future<Set<int>> getFoulsByMeeting(int meetingId) async {
    final db = await _localDatabase.database;
    final data = await _store.record(meetingId).get(db);
    if (data == null) return {};
    final raw = data['studentIds'];
    if (raw is List) {
      return raw.map((e) => int.tryParse(e.toString()) ?? 0).toSet()..remove(0);
    }
    return {};
  }

  Future<void> saveFoulsByMeeting({
    required int meetingId,
    required Set<int> studentIds,
  }) async {
    final db = await _localDatabase.database;
    await _store.record(meetingId).put(db, {
      'studentIds': studentIds.toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> clearFoulsByMeeting(int meetingId) async {
    final db = await _localDatabase.database;
    await _store.record(meetingId).delete(db);
  }
}
