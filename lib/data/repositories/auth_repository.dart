import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/app_exception.dart';
import '../models/user_model.dart';

/// Firebase Authentication for admins.
///
/// Only accounts whose `users/{uid}.isAdmin` is `true` may sign in. Anyone
/// else is signed straight back out, mirroring how the customer app refuses
/// admin accounts.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const notAdminMessage =
      'This account does not have admin access. Use the Your Shop app to '
      'shop.';

  DocumentReference<Map<String, dynamic>> _profile(String uid) =>
      _db.collection(FirestorePaths.users).doc(uid);

  /// Signs in and returns the admin profile, or throws [AppException].
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final User user;
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = credential.user!;
    } catch (e) {
      throw AppException.from(e);
    }
    return requireAdmin(user);
  }

  /// The admin profile of [user]. Signs out and throws when the account is
  /// not an admin (or has no profile).
  Future<UserModel> requireAdmin(User user) async {
    final UserModel? profile;
    try {
      profile = await fetchProfile(user.uid, fallbackEmail: user.email);
    } catch (e) {
      throw AppException.from(e);
    }
    if (profile == null || !profile.isAdmin) {
      await _auth.signOut();
      throw const AppException(notAdminMessage);
    }
    return profile;
  }

  Future<UserModel?> fetchProfile(String uid, {String? fallbackEmail}) async {
    final snap = await _profile(uid).get();
    final data = snap.data();
    if (data == null) return null;
    return UserModel.fromMap({'email': ?fallbackEmail, ...data}, uid: uid);
  }

  /// Live `isAdmin` flag, so a revoked admin is signed out at once.
  Stream<bool> watchIsAdmin(String uid) =>
      _profile(uid).snapshots().map((s) => s.data()?['isAdmin'] == true);

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> signOut() => _auth.signOut();
}
