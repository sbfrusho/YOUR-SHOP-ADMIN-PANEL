import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/session_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../data/models/user_model.dart';

class SettingsViewModel extends GetxController {
  SettingsViewModel(this._session, this._theme);

  final SessionService _session;
  final ThemeService _theme;

  final RxBool isSigningOut = false.obs;

  Rx<ThemeMode> get themeMode => _theme.mode;
  UserModel? get admin => _session.admin.value;

  Future<void> setThemeMode(ThemeMode mode) => _theme.setMode(mode);

  /// The session listener routes back to the login screen.
  Future<void> signOut() async {
    if (isSigningOut.value) return;
    isSigningOut.value = true;
    try {
      await _session.signOut();
    } finally {
      isSigningOut.value = false;
    }
  }
}
