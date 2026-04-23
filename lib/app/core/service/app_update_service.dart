import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  AppUpdateService._();

  static bool _checking = false;
  static bool _dialogShownThisLaunch = false;
  static bool _startingUpdate = false;

  static Future<void> checkAndPrompt(BuildContext context) async {
    if (_checking || _dialogShownThisLaunch) return;
    if (!Platform.isAndroid) return;

    _checking = true;
    try {
      final online = await _isOnline();
      if (!online) return;

      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      if (!context.mounted) return;
      _dialogShownThisLaunch = true;
      await _showForceUpdateDialog(context);
    } catch (_) {
      // Em falhas silenciosas (ex.: build de debug fora da Play Store),
      // simplesmente não mostramos modal para não bloquear o fluxo.
    } finally {
      _checking = false;
    }
  }

  static Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('one.one.one.one');
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _showForceUpdateDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Atualização obrigatória'),
            content: const Text(
              'Existe uma nova versão do app na loja. '
              'Para continuar usando, é necessário atualizar agora.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  await _startUpdateFlow(context);
                },
                child: const Text('Atualizar agora'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _startUpdateFlow(BuildContext context) async {
    if (_startingUpdate) return;
    _startingUpdate = true;
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar agora. Tente novamente.'),
        ),
      );
    } finally {
      _startingUpdate = false;
    }
  }
}
