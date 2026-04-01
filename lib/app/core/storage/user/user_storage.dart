import 'package:br_thp_meubenapp/app/core/storage/user/i_user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserStorage implements IUserStorage {
  static const String _userKey = 'user_data';

  @override
  Future<void> saveUser(String user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, user);
  }

  @override
  Future<String?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  @override
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
