import 'dart:convert';
import 'dart:io';

import 'package:br_thp_meubenapp/app/core/network/api_client.dart';
import 'package:br_thp_meubenapp/app/core/network/api_exception.dart';
import 'package:br_thp_meubenapp/app/core/storage/user/i_user_storage.dart';
import 'package:br_thp_meubenapp/app/core/storage/user/user_storage.dart';
import 'package:br_thp_meubenapp/app/feature/profile/data/models/user_profile_model.dart';
import 'package:br_thp_meubenapp/app/feature/profile/data/profile_endpoints.dart';
import 'package:br_thp_meubenapp/app/feature/profile/data/repositories/i_profile_repository.dart';

class ProfileRepository implements IProfileRepository {
  ProfileRepository({ApiClient? apiClient, IUserStorage? userStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _userStorage = userStorage ?? UserStorage();

  final ApiClient _apiClient;
  final IUserStorage _userStorage;

  @override
  Future<UserProfileModel> getUserProfile() async {
    final isOnline = await _checkOnlineStatus();

    if (isOnline) {
      try {
        final response = await _apiClient.get(
          ProfileEndpoints.oneToken,
          withAuthToken: true,
        );
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          throw const ApiException('Resposta inválida da API de perfil.');
        }

        await _userStorage.saveUser(jsonEncode(data));
        return UserProfileModel.fromJson(data);
      } on ApiException {
        rethrow;
      } catch (_) {
        final local = await _getLocalProfile();
        if (local != null) return local;
        throw const ApiException('Não foi possível carregar o perfil.');
      }
    }

    final local = await _getLocalProfile();
    if (local != null) return local;
    throw const ApiException('Sem conexão e sem dados locais de perfil.');
  }

  Future<UserProfileModel?> _getLocalProfile() async {
    final raw = await _userStorage.getUser();
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return UserProfileModel.fromJson(decoded);
  }

  Future<bool> _checkOnlineStatus() async {
    try {
      final result = await InternetAddress.lookup('one.one.one.one');
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
