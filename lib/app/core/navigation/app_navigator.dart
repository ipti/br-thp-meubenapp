import 'package:flutter/material.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void redirectToLogin() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushNamedAndRemoveUntil('/', (route) => false);
  }
}
