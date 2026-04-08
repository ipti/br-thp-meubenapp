import 'dart:convert';
import 'dart:developer';

import 'package:br_thp_meubenapp/app/core/components/button/button_default.dart';
import 'package:br_thp_meubenapp/app/core/network/api_client.dart';
import 'package:br_thp_meubenapp/app/core/network/api_exception.dart';
import 'package:br_thp_meubenapp/app/core/storage/token/i_token_storage.dart';
import 'package:br_thp_meubenapp/app/core/storage/token/token_storage.dart';
import 'package:br_thp_meubenapp/app/core/storage/user/i_user_storage.dart';
import 'package:br_thp_meubenapp/app/core/storage/user/user_storage.dart';
import 'package:br_thp_meubenapp/app/core/theme/app_colors.dart';
import 'package:br_thp_meubenapp/app/feature/auth/data/repositories/auth_repository.dart';
import 'package:br_thp_meubenapp/app/feature/auth/data/repositories/i_auth_repository.dart';
import 'package:br_thp_meubenapp/app/feature/profile/data/profile_endpoints.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final IAuthRepository _authRepository;
  late final ITokenStorage _tokenStorage;
  late final IUserStorage _userStorage;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _authRepository = AuthRepository(apiClient: ApiClient());
    _tokenStorage = TokenStorage();
    _userStorage = UserStorage();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe email e senha.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _authRepository.login(
        username: username,
        password: password,
      );
      await _tokenStorage.saveToken(token);
      await _cacheUserProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login realizado com sucesso.')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha no login: ${e.toString()}')),
      );
    } catch (e, stackTrace) {
      log(
        'Erro inesperado ao realizar login',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado ao realizar login. $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cacheUserProfile() async {
    try {
      final response = await ApiClient().get(
        ProfileEndpoints.oneToken,
        withAuthToken: true,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        await _userStorage.saveUser(jsonEncode(data));
      }
    } catch (e, stackTrace) {
      log(
        'Falha ao salvar cache local do perfil no login',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Image.asset(
                  'assets/image/logo.png', // Lembre-se de adicionar no pubspec.yaml
                  height: 100,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Usuário',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration:
                    const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Senha',
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        color: AppColors.primary,
                      ),
                    ),
              ),
              const SizedBox(height: 16),
              ButtonDefault(
                onPressed: _login,
                text: 'Entrar',
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
