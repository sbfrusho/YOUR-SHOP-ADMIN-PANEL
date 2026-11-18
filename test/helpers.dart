import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:your_shop_admin/app/routes/app_pages.dart';
import 'package:your_shop_admin/app/routes/app_routes.dart';
import 'package:your_shop_admin/core/services/auth_service.dart';
import 'package:your_shop_admin/core/services/clock.dart';
import 'package:your_shop_admin/core/services/functions_client.dart';
import 'package:your_shop_admin/core/services/image_picker_service.dart';
import 'package:your_shop_admin/core/services/image_storage.dart';
import 'package:your_shop_admin/core/services/session_service.dart';
import 'package:your_shop_admin/core/services/theme_service.dart';
import 'package:your_shop_admin/core/theme/app_theme.dart';
import 'package:your_shop_admin/data/repositories/auth_repository.dart';
import 'package:your_shop_admin/data/repositories/catalog_repository.dart';
import 'package:your_shop_admin/data/repositories/order_repository.dart';

/// Gives the image cache a temp folder (no path_provider plugin in tests).
void mockPathProvider() {
  final dir = Directory.systemTemp.createTempSync('your_shop_admin_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => dir.path,
      );
}

/// Records uploads and returns a fake URL.
class FakeImageStorage implements ImageStorage {
  final uploads = <String>[];

  @override
  Future<String> upload(String path, Uint8List bytes, String type) async {
    uploads.add(path);
    return 'https://img.test/$path';
  }
}

/// Returns [next] (one tiny PNG by default) instead of opening a picker.
class FakeImagePicker extends ImagePickerService {
  List<ImageUpload> next = [
    ImageUpload(
      bytes: transparentPng,
      contentType: 'image/png',
      extension: 'png',
    ),
  ];

  @override
  Future<List<ImageUpload>> pickImages() async => next;

  @override
  Future<ImageUpload?> pickImage() async => next.firstOrNull;
}

/// 1×1 transparent PNG.
final transparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// Real services and repositories on Firebase fakes.
class TestBackend {
  TestBackend({bool signedIn = false, bool isAdmin = true})
    : auth = MockFirebaseAuth(
        signedIn: signedIn,
        mockUser: MockUser(uid: 'u1', email: 'admin@shop.test'),
      ) {
    db.collection('users').doc('u1').set({
      'uId': 'u1',
      'name': 'Rusho',
      'email': 'admin@shop.test',
      'isAdmin': isAdmin,
    });
  }

  final db = FakeFirebaseFirestore();
  final MockFirebaseAuth auth;

  /// "Now" for the dashboard: Thursday 19 Nov 2026, 14:00.
  Clock clock = FixedClock(DateTime(2026, 11, 19, 14));

  final images = FakeImageStorage();
  final picker = FakeImagePicker();

  Future<void> addCategory(String id, String name) =>
      db.collection('categories').doc(id).set({
        'categoryId': id,
        'categoryName': name,
        'categoryImg': 'https://img.test/categories/$id.jpg',
      });

  /// A banner; [order] `null` is a legacy banner without a position.
  Future<void> addBanner(String id, {int? order, DateTime? createdAt}) =>
      db.collection('banners').doc(id).set({
        'imageUrl': 'https://img.test/banners/$id.jpg',
        'sortOrder': ?order,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt),
      });

  /// Adds a product in the legacy (string) formats.
  Future<void> addProduct(
    String id,
    String name, {
    String categoryId = 'shirts',
    String categoryName = 'Shirts',
    String full = '2490',
    String sale = '2490',
    bool isSale = false,
    String stock = '12',
    List<String> sizes = const ['S', 'M', 'L'],
    bool archived = false,
    Map<String, dynamic> extra = const {},
  }) => db.collection('products').doc(id).set({
    'productId': id,
    'productName': name,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'fullPrice': full,
    'salePrice': sale,
    'isSale': isSale,
    'quantity': stock,
    'productSizes': sizes,
    'productImages': ['https://img.test/$id.jpg'],
    'productDescription': 'Soft cotton.',
    'deliveryTime': '2–4 working days',
    'email': 'seller@shop.test',
    if (archived) 'isArchived': true,
    ...extra,
  });

  /// Requests sent to the Cloud Functions.
  final calls = <http.Request>[];

  /// Fake `adminCancelOrder`: marks the order cancelled like the server.
  late final functions = FunctionsClient(
    baseUrl: 'https://functions.test',
    auth: auth,
    client: MockClient((req) async {
      calls.add(req);
      final id = (jsonDecode(req.body) as Map)['orderId'] as String;
      await db.collection('orders').doc(id).update({
        'status': 'Cancelled',
        'paymentStatus': 'void',
        'cancelledBy': 'admin',
      });
      return http.Response('{"cancelled":true,"refunded":false}', 200);
    }),
  );

  /// Adds an order (and its items) and returns its ID.
  Future<String> addOrder({
    String id = 'order1abc',
    String status = 'Pending',
    String paymentStatus = 'unpaid',
    String name = 'Nusrat Jahan',
    String phone = '01712-345678',
    double total = 2540,
    DateTime? createdAt,
    bool customerDeleted = false,
    List<Map<String, dynamic>> items = const [
      {
        'product_id': 'p1',
        'product_name': 'Linen Overshirt',
        'price': '1890',
        'quantity': 1,
        'size': 'M',
        'product_image': '',
      },
      {
        'product_id': 'p2',
        'product_name': 'Everyday Cap',
        'price': '650',
        'quantity': 1,
        'size': '',
        'product_image': '',
      },
    ],
  }) async {
    final ref = db.collection('orders').doc(id);
    await ref.set({
      'customerId': 'c1',
      'uniqueId': customerDeleted
          ? ''
          : '${name.split(' ').first.toLowerCase()}@mail.test',
      'customerName': customerDeleted ? '' : name,
      'customerPhone': customerDeleted ? '' : phone,
      'customerAddress': customerDeleted
          ? ''
          : 'House 12, Road 5, Dhanmondi, Dhaka 1205',
      'paymentMethod': 'Cash on Delivery',
      'paymentStatus': paymentStatus,
      'paymentGateway': 'cod',
      'deliveryTime': '2–4 working days',
      'deliveryType': 'Home delivery',
      'totalPrice': total,
      'status': status,
      'customerDeleted': customerDeleted,
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime(2026, 11, 18, 10)),
    });
    for (final (i, item) in items.indexed) {
      await ref.collection('items').doc('i$i').set(item);
    }
    return id;
  }

  Future<void> register() async {
    SharedPreferences.setMockInitialValues({});
    Get.put(await ThemeService().init(), permanent: true);
    Get.put(AuthRepository(auth: auth, firestore: db), permanent: true);
    Get.put(
      OrderRepository(firestore: db, functions: functions),
      permanent: true,
    );
    Get.put(CatalogRepository(firestore: db, images: images), permanent: true);
    Get.put<ImagePickerService>(picker, permanent: true);
    Get.put<Clock>(clock, permanent: true);
    final authService = Get.put(AuthService(auth: auth), permanent: true);
    Get.put(SessionService(authService, Get.find()), permanent: true);
  }
}

Widget testApp({String initialRoute = AppRoutes.splash}) => GetMaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  getPages: AppPages.routes,
  initialRoute: initialRoute,
);

/// Pumps frames without waiting for endless animations (spinners).
Future<void> settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Lets GetX snackbars finish so no timers are left pending.
Future<void> drainSnackbars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await settle(tester);
}
