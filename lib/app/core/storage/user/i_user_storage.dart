abstract class IUserStorage {
  Future<void> saveUser(String user);
  Future<String?> getUser();
  Future<void> clearUser();
}
