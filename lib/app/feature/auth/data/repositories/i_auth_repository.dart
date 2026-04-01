abstract class IAuthRepository {
  Future<String> login({required String username, required String password});
}
