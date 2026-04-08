import 'dart:io';

import 'package:br_thp_meubenapp/app/core/navigation/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:br_thp_meubenapp/app/core/theme/app_colors.dart';

class PageDefault extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final Widget body;
  const PageDefault({super.key, this.title, this.subtitle, required this.body});

  @override
  State<PageDefault> createState() => _PageDefaultState();
}

class _PageDefaultState extends State<PageDefault> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkOnlineStatus();
  }

  Future<void> _checkOnlineStatus() async {
    try {
      final result = await InternetAddress.lookup('one.one.one.one');
      if (!mounted) return;
      setState(() => _isOnline = result.isNotEmpty);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isOnline = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSubtitle =
        widget.subtitle != null && widget.subtitle!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Image.asset('assets/image/logo.png', height: 32),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _isOnline ? 'Sair' : 'Logout indisponível offline',
            icon: const Icon(Icons.logout),
            onPressed: _isOnline ? AppNavigator.redirectToLogin : null,
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
              widget.title ?? '',
              textAlign: TextAlign.start,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          if (hasSubtitle) const SizedBox(height: 8),
          if (hasSubtitle)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(widget.subtitle!),
            ),
          Expanded(child: widget.body),
        ],
      ),
    );
  }
}
