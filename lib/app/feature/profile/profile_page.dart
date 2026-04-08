import 'dart:io';

import 'package:br_thp_meubenapp/app/core/components/button/button_default.dart';
import 'package:br_thp_meubenapp/app/core/components/page_default/page_default.dart';
import 'package:br_thp_meubenapp/app/core/navigation/app_navigator.dart';
import 'package:br_thp_meubenapp/app/core/network/api_client.dart';
import 'package:br_thp_meubenapp/app/core/network/api_exception.dart';
import 'package:br_thp_meubenapp/app/core/storage/token/i_token_storage.dart';
import 'package:br_thp_meubenapp/app/core/storage/token/token_storage.dart';
import 'package:br_thp_meubenapp/app/core/storage/user/i_user_storage.dart';
import 'package:br_thp_meubenapp/app/core/storage/user/user_storage.dart';
import 'package:br_thp_meubenapp/app/core/utils/translateRole.dart';
import 'package:br_thp_meubenapp/app/feature/profile/data/models/user_profile_model.dart';
import 'package:br_thp_meubenapp/app/feature/profile/data/repositories/i_profile_repository.dart';
import 'package:br_thp_meubenapp/app/feature/profile/data/repositories/profile_repository.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final IProfileRepository _repository;
  late final ITokenStorage _tokenStorage;
  late final IUserStorage _userStorage;

  bool _loading = true;
  bool _isOnline = false;
  UserProfileModel? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = ProfileRepository(apiClient: ApiClient());
    _tokenStorage = TokenStorage();
    _userStorage = UserStorage();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final online = await _checkOnlineStatus();
    try {
      final profile = await _repository.getUserProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isOnline = online;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isOnline = online;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isOnline = online;
        _error = 'Erro ao carregar perfil: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    final online = await _checkOnlineStatus();
    if (!online) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout indisponível offline.')),
      );
      return;
    }

    await _tokenStorage.clearToken();
    await _userStorage.clearUser();
    AppNavigator.redirectToLogin();
  }

  Future<bool> _checkOnlineStatus() async {
    try {
      final result = await InternetAddress.lookup('one.one.one.one');
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageDefault(
      title: 'Perfil',
      subtitle: 'Informações do usuário',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!),
                      ),
                    ),
                  if (_profile != null) ...[
                    _buildInfoCard('Nome', _profile!.name),
                    _buildInfoCard('Usuário', _profile!.username),
                    _buildInfoCard(
                      'Perfil',
                      TranslateRole.translateRole(_profile!.role),
                    ),
                    _buildInfoCard(
                      'Status',
                      _profile!.active ? 'Ativo' : 'Inativo',
                    ),
                    _buildInfoCard(
                      'Tecnologias',
                      _profile!.socialTechnologies.isEmpty
                          ? '-'
                          : _profile!.socialTechnologies.join(', '),
                    ),
                    _buildInfoCard('E-mail', _profile!.email ?? '-'),
                    _buildInfoCard('Telefone', _profile!.phone ?? '-'),
                  ],
                  const SizedBox(height: 16),
                  ButtonDefault(
                    onPressed: _isOnline ? _logout : null,
                    text: _isOnline
                        ? 'Sair da conta'
                        : 'Logout indisponível offline',
                    iconLeft: Icons.logout,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      child: ListTile(title: Text(label), subtitle: Text(value)),
    );
  }
}
