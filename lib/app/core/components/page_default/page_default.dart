import 'package:br_thp_meubenapp/app/core/navigation/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:br_thp_meubenapp/app/core/theme/app_colors.dart';

class PageDefault extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget body;
  const PageDefault({super.key, this.title, this.subtitle, required this.body});

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Image.asset('assets/image/logo.png', height: 32),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AppNavigator.redirectToLogin();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              title ?? '',
              textAlign: TextAlign.start,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          if (hasSubtitle) const SizedBox(height: 8),
          if (hasSubtitle)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(subtitle!),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
