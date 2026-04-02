import 'package:br_thp_meubenapp/app/core/network/api_exception.dart';
import 'package:br_thp_meubenapp/app/core/network/i_api_client.dart';
import 'package:br_thp_meubenapp/app/feature/auth/data/dto/login_request_dto.dart';
import 'package:br_thp_meubenapp/app/feature/auth/data/repositories/i_auth_repository.dart';

class AuthRepository implements IAuthRepository {
  AuthRepository({required IApiClient apiClient}) : _apiClient = apiClient;

  final IApiClient _apiClient;

  @override
  Future<String> login({
    required String username,
    required String password,
  }) async {
    final dto = LoginRequestDto(username: username, password: password);
    final response = await _apiClient.post('/auth/login', body: dto.toJson());
    final data = response.data;

    final token = _extractToken(data);
    if (token != null && token.isNotEmpty) return token;

    throw const ApiException(
      'Login realizado, mas token nao encontrado na resposta.',
    );
  }

  String? _extractToken(dynamic json) {
    if (json is Map<String, dynamic>) {
      final direct =
          json['token'] ??
          json['accessToken'] ??
          json['access_token'] ??
          json['jwt'];

      if (direct is String && direct.isNotEmpty) return direct;

      for (final value in json.values) {
        final nestedToken = _extractToken(value);
        if (nestedToken != null && nestedToken.isNotEmpty) {
          return nestedToken;
        }
      }
    }

    if (json is List) {
      for (final item in json) {
        final nestedToken = _extractToken(item);
        if (nestedToken != null && nestedToken.isNotEmpty) {
          return nestedToken;
        }
      }
    }

    return null;
  }
}
