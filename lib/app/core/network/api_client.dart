import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:br_thp_meubenapp/app/core/config/api_config.dart';
import 'package:br_thp_meubenapp/app/core/navigation/app_navigator.dart';
import 'package:br_thp_meubenapp/app/core/network/api_exception.dart';
import 'package:br_thp_meubenapp/app/core/network/api_response.dart';
import 'package:br_thp_meubenapp/app/core/network/i_api_client.dart';
import 'package:br_thp_meubenapp/app/core/storage/token/i_token_storage.dart';
import 'package:br_thp_meubenapp/app/core/storage/token/token_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient implements IApiClient {
  ApiClient({http.Client? client, ITokenStorage? tokenStorage})
    : _client = client ?? http.Client(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final http.Client _client;
  final ITokenStorage _tokenStorage;
  final Duration _timeout = const Duration(seconds: 20);
  static bool _isRedirectingToLogin = false;

  @override
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool withAuthToken = false,
    String? token,
  }) {
    return _request(
      method: 'GET',
      endpoint: endpoint,
      headers: headers,
      queryParameters: queryParameters,
      withAuthToken: withAuthToken,
      token: token,
    );
  }

  @override
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
    bool withAuthToken = false,
    String? token,
  }) {
    return _request(
      method: 'POST',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      withAuthToken: withAuthToken,
      token: token,
    );
  }

  @override
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
    bool withAuthToken = false,
    String? token,
  }) {
    return _request(
      method: 'PUT',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      withAuthToken: withAuthToken,
      token: token,
    );
  }

  @override
  Future<ApiResponse> patch(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
    bool withAuthToken = false,
    String? token,
  }) {
    return _request(
      method: 'PATCH',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      withAuthToken: withAuthToken,
      token: token,
    );
  }

  @override
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
    bool withAuthToken = false,
    String? token,
  }) {
    return _request(
      method: 'DELETE',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      withAuthToken: withAuthToken,
      token: token,
    );
  }

  Future<ApiResponse> _request({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
    required bool withAuthToken,
    String? token,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final authHeader = await _buildAuthHeader(
      withAuthToken: withAuthToken,
      explicitToken: token,
    );
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...authHeader,
      ...?headers,
    };

    try {
      late final http.Response response;
      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: mergedHeaders)
              .timeout(_timeout);
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: mergedHeaders, body: _encodeBody(body))
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: mergedHeaders, body: _encodeBody(body))
              .timeout(_timeout);
          break;
        case 'PATCH':
          response = await _client
              .patch(uri, headers: mergedHeaders, body: _encodeBody(body))
              .timeout(_timeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: mergedHeaders, body: _encodeBody(body))
              .timeout(_timeout);
          break;
        default:
          throw const ApiException('Metodo HTTP nao suportado.');
      }

      log('[API] $method $uri');
      if (body != null) log('[API] body: ${_encodeBody(body)}');

      final parsedData = _decodeBody(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(statusCode: response.statusCode, data: parsedData);
      }

      log('[API] erro ${response.statusCode}: ${response.body}');

      if (withAuthToken && _isUnauthorized(response.statusCode)) {
        await _handleUnauthorized();
      }

      final errorMessage = _extractErrorMessage(parsedData);
      throw ApiException(errorMessage, statusCode: response.statusCode);
    } on TimeoutException {
      throw const ApiException('Tempo de requisicao esgotado.');
    } on http.ClientException catch (e) {
      throw ApiException('Falha de conexao: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Erro inesperado ao consumir a API.');
    }
  }

  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParameters) {
    final cleanBase = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$cleanBase$cleanEndpoint');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(
      queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  String? _encodeBody(Object? body) {
    if (body == null) return null;
    return jsonEncode(body);
  }

  dynamic _decodeBody(String responseBody) {
    if (responseBody.isEmpty) return {};
    try {
      return jsonDecode(responseBody);
    } catch (_) {
      return {'raw': responseBody};
    }
  }

  String _extractErrorMessage(dynamic parsedData) {
    if (parsedData is Map<String, dynamic>) {
      if (parsedData['message'] is String) {
        return parsedData['message'] as String;
      }
      if (parsedData['error'] is String) {
        return parsedData['error'] as String;
      }
    }
    return 'A API retornou erro.';
  }

  Future<Map<String, String>> _buildAuthHeader({
    required bool withAuthToken,
    String? explicitToken,
  }) async {
    if (!withAuthToken) return {};

    final token = explicitToken ?? await _tokenStorage.getToken();
    if (token == null || token.isEmpty) return {};

    return {'Authorization': 'Bearer $token'};
  }

  bool _isUnauthorized(int statusCode) {
    return statusCode == 401 || statusCode == 403;
  }

  Future<void> _handleUnauthorized() async {
    await _tokenStorage.clearToken();
    if (_isRedirectingToLogin) return;

    _isRedirectingToLogin = true;
    AppNavigator.redirectToLogin();
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      _isRedirectingToLogin = false;
    });
  }
}
