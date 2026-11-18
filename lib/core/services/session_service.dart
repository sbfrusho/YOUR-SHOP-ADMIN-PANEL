import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../errors/app_exception.dart';
import '../utils/app_logger.dart';
import '../utils/app_snackbar.dart';
import 'auth_service.dart';

/// The signed-in admin and the rules that keep the session valid.
///
/// - [admin] is set only after the `isAdmin` check passed.
/// - Signing out anywhere (or the account losing `isAdmin`) sends the app
///   back to the login screen.
class SessionService extends GetxService {
  SessionService(this._auth, this._repo);

  final AuthService _auth;
  final AuthRepository _repo;

  final Rxn<UserModel> admin = Rxn<UserModel>();

  StreamSubscription<bool>? _adminSub;
  Worker? _userWorker;

  /// Routes reachable without a session.
  static const publicRoutes = {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.forgotPassword,
  };

  bool get isAdmin => _auth.isSignedIn && admin.value != null;

  @override
  void onInit() {
    super.onInit();
    _userWorker = ever<User?>(_auth.user, _onUserChanged);
  }

  /// Route to open at launch. Re-checks `isAdmin` for a remembered session.
  Future<String> restore() async {
    final user = _auth.currentUser;
    if (user == null) return AppRoutes.login;
    try {
      _start(await _repo.requireAdmin(user));
      return AppRoutes.shell;
    } on AppException catch (e) {
      AppLogger.debug('Session not restored: ${e.message}');
      return AppRoutes.login;
    }
  }

  /// Called by the login screen after [AuthRepository.signIn] succeeded.
  String completeSignIn(UserModel profile) {
    _start(profile);
    return AppRoutes.shell;
  }

  Future<void> signOut() async {
    _stop();
    await _repo.signOut();
  }

  void _start(UserModel profile) {
    admin.value = profile;
    _adminSub?.cancel();
    _adminSub = _repo.watchIsAdmin(profile.uid).listen((isAdmin) async {
      if (isAdmin || admin.value == null) return;
      await signOut();
      AppSnackbar.error(AuthRepository.notAdminMessage);
    }, onError: (Object e) => AppLogger.error('Admin watch failed', e));
  }

  void _stop() {
    _adminSub?.cancel();
    _adminSub = null;
    admin.value = null;
  }

  void _onUserChanged(User? user) {
    if (user != null) return;
    _stop();
    if (!publicRoutes.contains(Get.currentRoute)) {
      Get.offAllNamed<void>(AppRoutes.login);
    }
  }

  @override
  void onClose() {
    _userWorker?.dispose();
    _adminSub?.cancel();
    super.onClose();
  }
}
