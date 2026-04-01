import 'dart:async';
import 'dart:convert';

import 'package:br_thp_meubenapp/app/core/config/api_config.dart';
import 'package:br_thp_meubenapp/app/core/network/api_exception.dart';
import 'package:br_thp_meubenapp/app/core/network/api_response.dart';
import 'package:br_thp_meubenapp/app/core/network/i_api_client.dart';
import 'package:http/http.dart' as http;

class ApiClient implements IApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration _timeout = const Duration(seconds: 20);

  @override
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      method: 'GET',
      endpoint: endpoint,
      headers: headers,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      method: 'POST',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      method: 'PUT',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<ApiResponse> patch(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      method: 'PATCH',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      method: 'DELETE',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
    );
  }

  Future<ApiResponse> _request({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
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

      final parsedData = _decodeBody(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(statusCode: response.statusCode, data: parsedData);
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
}
