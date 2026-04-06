import 'package:br_thp_meubenapp/app/core/storage/token/i_token_storage.dart';
import 'package:br_thp_meubenapp/app/core/storage/token/token_storage.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final ITokenStorage _tokenStorage;

  @override
  void initState() {
    super.initState();
    _tokenStorage = TokenStorage();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final token = await _tokenStorage.getToken();
    if (!mounted) return;

    final nextRoute = (token != null && token.trim().isNotEmpty)
        ? '/home'
        : '/login';

    Navigator.pushReplacementNamed(context, nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Container(
              //   height: 120,
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(999),
              //     gradient: const LinearGradient(
              //       colors: [Color(0xFF2C6CF6), Color(0xFF4C78FF)],
              //     ),
              //   ),
              //   alignment: Alignment.centerLeft,
              //   padding: const EdgeInsets.all(14),
              //   child: Container(
              //     width: 88,
              //     height: 88,
              //     decoration: const BoxDecoration(
              //       shape: BoxShape.circle,
              //       color: Color(0xFFFDB400),
              //     ),
              //   ),
              // ),
              const SizedBox(height: 36),
              Image.asset(
                'assets/image/logo.png',
                height: 72,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Image.asset(
                'assets/image/splash_loading.gif',
                width: 180,
                height: 64,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
