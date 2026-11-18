import 'package:image_picker/image_picker.dart';

import '../../data/repositories/catalog_repository.dart';

/// Picks images from the gallery (file chooser on the web). Replaced by a
/// fake in tests.
class ImagePickerService {
  ImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Long edge after resizing; keeps uploads small for the shop.
  static const maxSide = 1600.0;

  Future<List<ImageUpload>> pickImages() async {
    final files = await _picker.pickMultiImage(
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: 85,
    );
    return [for (final f in files) await _toUpload(f)];
  }

  /// One image, or `null` when the admin cancels.
  Future<ImageUpload?> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: 85,
    );
    return file == null ? null : _toUpload(file);
  }

  static Future<ImageUpload> _toUpload(XFile f) async => ImageUpload(
    bytes: await f.readAsBytes(),
    contentType: f.mimeType ?? _mimeFor(f.name),
    extension: _extensionOf(f.name),
  );

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? 'jpg' : name.substring(dot + 1).toLowerCase();
  }

  static String _mimeFor(String name) => switch (_extensionOf(name)) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    _ => 'image/jpeg',
  };
}
