import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/dashboard_stats.dart';

/// Daily revenue as bars, oldest on the left, today in the primary colour.
/// Each bar has a tooltip and a screen-reader label with the exact amount.
class RevenueChart extends StatelessWidget {
  const RevenueChart({super.key, required this.days});

  final List<DayRevenue> days;

  static const _labelHeight = 20.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = context.palette.mutedText;
    final peak = days.fold<double>(0, (m, d) => d.revenue > m ? d.revenue : m);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: muted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          peak == 0
              ? 'No sales yet'.tr
              : 'Best day @amount'.trParams({'amount': Formatters.price(peak)}),
          style: labelStyle,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final barArea = c.maxHeight - _labelHeight;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (i, d) in days.indexed)
                    Expanded(
                      child: _Bar(
                        day: d,
                        height: peak == 0
                            ? 0
                            : (barArea * d.revenue / peak).clamp(
                                d.revenue > 0 ? 3.0 : 0.0,
                                barArea,
                              ),
                        color: i == days.length - 1
                            ? scheme.primary
                            : scheme.primary.withValues(alpha: 0.28),
                        empty: scheme.outlineVariant,
                        // Every other day, plus today, so labels never crowd.
                        label: (days.length - 1 - i).isEven
                            ? '${d.day.day}'
                            : '',
                        labelStyle: labelStyle,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.height,
    required this.color,
    required this.empty,
    required this.label,
    required this.labelStyle,
  });

  final DayRevenue day;
  final double height;
  final Color color;
  final Color empty;
  final String label;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final summary = '@date: @amount, @n orders'.trParams({
      'date': Formatters.date(day.day),
      'amount': Formatters.price(day.revenue),
      'n': '${day.orders}',
    });
    return Tooltip(
      message: summary,
      child: Semantics(
        label: summary,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: height == 0 ? 2 : height,
                decoration: BoxDecoration(
                  color: height == 0 ? empty : color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(
                height: RevenueChart._labelHeight,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(label, style: labelStyle, maxLines: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
