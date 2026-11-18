import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product_model.dart';

/// Price with the full price struck through when on sale.
class PriceText extends StatelessWidget {
  const PriceText(this.product, {super.key, this.style, this.stacked = false});

  final ProductModel product;
  final TextStyle? style;

  /// Full price and discount on a second line (narrow table cells).
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = style ?? theme.textTheme.titleSmall;
    if (!product.hasDiscount) {
      return Text(Formatters.price(product.fullPrice), style: base);
    }
    final sale = Text(Formatters.price(product.price), style: base);
    final rest = [
      Text(
        Formatters.price(product.fullPrice),
        style: theme.textTheme.bodySmall?.copyWith(
          color: context.palette.mutedText,
          decoration: TextDecoration.lineThrough,
        ),
      ),
      Text(
        '-${product.salePercent}%',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.tertiary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ];
    if (stacked) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sale,
          Wrap(spacing: 6, children: rest),
        ],
      );
    }
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [sale, ...rest],
    );
  }
}
