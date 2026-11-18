import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_shop_admin/core/errors/app_exception.dart';
import 'package:your_shop_admin/data/repositories/auth_repository.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  late AuthRepository repo;

  final user = MockUser(uid: 'u1', email: 'admin@shop.test');

  setUp(() {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(mockUser: user);
    repo = AuthRepository(auth: auth, firestore: db);
  });

  Future<void> profile(Map<String, dynamic> data) =>
      db.collection('users').doc('u1').set(data);

  test('admin signs in and gets their profile', () async {
    await profile({'uId': 'u1', 'name': 'Rusho', 'isAdmin': true});

    final admin = await repo.signIn(email: 'admin@shop.test', password: 'x');

    expect(admin.uid, 'u1');
    expect(admin.name, 'Rusho');
    expect(admin.email, 'admin@shop.test');
    expect(auth.currentUser, isNotNull);
  });

  test('customer is refused and signed out', () async {
    await profile({'uId': 'u1', 'isAdmin': false});

    await expectLater(
      repo.signIn(email: 'admin@shop.test', password: 'x'),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          AuthRepository.notAdminMessage,
        ),
      ),
    );
    expect(auth.currentUser, isNull);
  });

  test('account without a profile is refused', () async {
    await expectLater(
      repo.signIn(email: 'admin@shop.test', password: 'x'),
      throwsA(isA<AppException>()),
    );
    expect(auth.currentUser, isNull);
  });

  test('legacy string "true" counts as admin', () async {
    await profile({'isAdmin': 'true'});
    final admin = await repo.signIn(email: 'admin@shop.test', password: 'x');
    expect(admin.isAdmin, isTrue);
  });

  test('watchIsAdmin follows the flag', () async {
    await profile({'isAdmin': true});
    final values = repo.watchIsAdmin('u1').take(2).toList();
    await db.collection('users').doc('u1').update({'isAdmin': false});
    expect(await values, [true, false]);
  });

  test('password reset is sent', () async {
    await expectLater(repo.sendPasswordReset('admin@shop.test'), completes);
  });
}
