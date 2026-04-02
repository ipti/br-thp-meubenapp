import 'package:br_thp_meubenapp/app/core/storage/local/local_database.dart';
import 'package:sembast/sembast.dart';

class MobileStoreCacheDatasource {
  MobileStoreCacheDatasource({LocalDatabase? localDatabase})
      : _localDatabase = localDatabase ?? LocalDatabase.instance;

  final LocalDatabase _localDatabase;
  static const String _storeName = 'mobile_store_cache';

  StoreRef<String, Object?> get _store => StoreRef<String, Object?>.main();

  String _snapshotKey(int year) => 'user_token_snapshot_$year';

  Future<void> saveSnapshot({
    required int year,
    required dynamic payload,
  }) async {
    final db = await _localDatabase.database;
    await _store.record(_snapshotKey(year)).put(db, {
      'store': _storeName,
      'updatedAt': DateTime.now().toIso8601String(),
      'year': year,
      'payload': payload,
    });
  }

  Future<dynamic> getSnapshot({required int year}) async {
    final db = await _localDatabase.database;
    final record = await _store.record(_snapshotKey(year)).get(db);
    if (record is Map<String, dynamic>) {
      return record['payload'];
    }
    if (record is Map) {
      return record['payload'];
    }
    return null;
  }
}
