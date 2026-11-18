import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/status_chip.dart';
import '../../../data/models/product_model.dart';

class StockChip extends StatelessWidget {
  const StockChip(this.product, {super.key});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    if (product.isArchived) {
      return const StatusChip(label: 'Archived', tone: StatusTone.neutral);
    }
    if (product.isOutOfStock) {
      return const StatusChip(label: 'Out of stock', tone: StatusTone.error);
    }
    return StatusChip(
      label: '@n in stock'.trParams({'n': '${product.stock}'}),
      tone: product.isLowStock ? StatusTone.warning : StatusTone.success,
    );
  }
}
