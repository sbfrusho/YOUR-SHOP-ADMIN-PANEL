import 'dart:ui';

import 'package:get/get.dart';

/// GetX translations. Keys are the English text itself (as in the customer
/// app), so a missing translation falls back to readable English and `.tr`
/// can wrap any string.
///
/// To add a language (Bangla is being considered): add its map and its
/// locale to [locales].
class AppTranslations extends Translations {
  static const english = Locale('en', 'US');
  static const locales = [english];

  @override
  Map<String, Map<String, String>> get keys => {'en_US': const {}};
}
