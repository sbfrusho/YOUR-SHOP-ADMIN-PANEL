// Renders the brand mark to the launcher icon, native splash and web icons
// for Your Shop Admin. Run after changing BrandMarkPainter or the colours:
//
//   flutter test tool/generate_brand_assets_test.dart
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
//
// The admin icon is the shop's mark inverted (cream bag on charcoal), so the
// two apps are easy to tell apart on the same phone.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_shop_admin/core/theme/app_colors.dart';
import 'package:your_shop_admin/core/widgets/brand/brand_mark_painter.dart';

const _out = 'assets/branding';
const _web = 'web';

Future<void> _render(
  String path, {
  required int size,
  required double markFraction,
  required Color bag,
  required Color letter,
  Color? background,
  double cornerRadius = 0,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final full = Offset.zero & Size(size.toDouble(), size.toDouble());
  if (background != null) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(full, Radius.circular(cornerRadius)),
      Paint()..color = background,
    );
  }
  final markSize = size * markFraction;
  canvas.translate((size - markSize) / 2, (size - markSize) / 2);
  BrandMarkPainter(
    bagColor: bag,
    letterColor: letter,
  ).paint(canvas, Size.square(markSize));
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('generate admin brand assets', () async {
    const bg = AppColors.grey900;
    const bag = AppColors.cream100;
    const letter = AppColors.grey900;

    // Launcher icon (legacy Android, iOS masks the corners).
    await _render(
      '$_out/app_icon.png',
      size: 1024,
      markFraction: 0.62,
      bag: bag,
      letter: letter,
      background: bg,
    );
    // Android adaptive foreground: mark inside the 66% safe zone.
    await _render(
      '$_out/app_icon_foreground.png',
      size: 1024,
      markFraction: 0.56,
      bag: bag,
      letter: letter,
    );
    // Android 13+ themed (monochrome) icon.
    await _render(
      '$_out/app_icon_monochrome.png',
      size: 1024,
      markFraction: 0.56,
      bag: const Color(0xFF000000),
      letter: const Color(0x00000000),
    );
    // Play listing icon (512, full bleed).
    await _render(
      '$_out/play_store_icon.png',
      size: 512,
      markFraction: 0.62,
      bag: bag,
      letter: letter,
      background: bg,
    );

    // Native splash: charcoal background, cream mark (both themes), so it
    // matches the icon the admin just tapped.
    await _render(
      '$_out/splash_logo.png',
      size: 768,
      markFraction: 0.5,
      bag: bag,
      letter: letter,
    );
    await _render(
      '$_out/splash_android12.png',
      size: 960,
      markFraction: 0.5,
      bag: bag,
      letter: letter,
    );

    // Web: PWA icons, maskable variants (mark inside the 80% safe zone)
    // and the favicon.
    for (final px in [192, 512]) {
      await _render(
        '$_web/icons/Icon-$px.png',
        size: px,
        markFraction: 0.62,
        bag: bag,
        letter: letter,
        background: bg,
        cornerRadius: px * 0.22,
      );
      await _render(
        '$_web/icons/Icon-maskable-$px.png',
        size: px,
        markFraction: 0.5,
        bag: bag,
        letter: letter,
        background: bg,
      );
    }
    await _render(
      '$_web/favicon.png',
      size: 64,
      markFraction: 0.7,
      bag: bag,
      letter: letter,
      background: bg,
      cornerRadius: 14,
    );
  });
}
