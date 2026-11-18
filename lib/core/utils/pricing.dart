/// Sale maths shared by the product form and list.
abstract final class Pricing {
  /// Largest discount the form allows.
  static const maxPercent = 90;

  /// Sale price for [fullPrice] at [percent] off, rounded to whole Taka.
  static double salePrice(double fullPrice, int percent) {
    final p = percent.clamp(0, maxPercent);
    return (fullPrice * (100 - p) / 100).roundToDouble();
  }

  /// Percent off implied by two prices (for legacy products without
  /// `salePercent`).
  static int percentOff(double fullPrice, double salePrice) {
    if (fullPrice <= 0 || salePrice <= 0 || salePrice >= fullPrice) return 0;
    return ((fullPrice - salePrice) / fullPrice * 100).round();
  }

  /// Whole numbers without a trailing `.0`, as the legacy data stores them.
  static String legacyString(double amount) => amount == amount.roundToDouble()
      ? amount.toInt().toString()
      : amount.toStringAsFixed(2);
}
