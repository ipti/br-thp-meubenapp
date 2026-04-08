import 'package:br_thp_meubenapp/app/core/storage/user/i_user_storage.dart';
import 'package:br_thp_meubenapp/app/core/storage/local/local_database.dart';
import 'package:sembast/sembast.dart';

class UserStorage implements IUserStorage {
  static const int _userRecordKey = 1;
  final StoreRef<int, Map<String, Object?>> _store = intMapStoreFactory.store(
    'user_cache',
  );

  @override
  Future<void> saveUser(String user) async {
    final db = await LocalDatabase.instance.database;
    await _store.record(_userRecordKey).put(db, {
      'data': user,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<String?> getUser() async {
    final db = await LocalDatabase.instance.database;
    final map = await _store.record(_userRecordKey).get(db);
    return map?['data']?.toString();
  }

  @override
  Future<void> clearUser() async {
    final db = await LocalDatabase.instance.database;
    await _store.record(_userRecordKey).delete(db);
  }
}
