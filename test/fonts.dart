import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the bundled Manrope and Playfair Display fonts (and Material
/// icons when the Flutter SDK is found), so text is measured as in the
/// app rather than in the square test font.
Future<void> loadAppFonts() async {
  Future<void> load(String family, List<String> files) async {
    final existing = files.where((f) => File(f).existsSync()).toList();
    if (existing.isEmpty) return;
    final loader = FontLoader(family);
    for (final f in existing) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  const dir = 'assets/fonts';
  await load('Manrope', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'])
      '$dir/Manrope-$w.ttf',
  ]);
  await load('PlayfairDisplay', [
    '$dir/PlayfairDisplay-SemiBold.ttf',
    '$dir/PlayfairDisplay-Bold.ttf',
  ]);
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter';
  await load('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}
