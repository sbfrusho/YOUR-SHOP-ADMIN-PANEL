import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../errors/app_exception.dart';

/// Uploads catalogue images. An interface so tests use a fake.
abstract interface class ImageStorage {
  /// Stores [bytes] at [path] and returns the public download URL.
  Future<String> upload(String path, Uint8List bytes, String contentType);
}

class FirebaseImageStorage implements ImageStorage {
  FirebaseImageStorage({FirebaseStorage? storage}) : _storage = storage;

  final FirebaseStorage? _storage;

  @override
  Future<String> upload(
    String path,
    Uint8List bytes,
    String contentType,
  ) async {
    try {
      final ref = (_storage ?? FirebaseStorage.instance).ref(path);
      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: contentType,
          cacheControl: 'public, max-age=31536000',
        ),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
