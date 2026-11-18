import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/user_model.dart';
import '../../orders/views/order_chips.dart';
import '../view_models/customer_detail_view_model.dart';
import 'customer_avatar.dart';
import 'customers_view.dart';

class CustomerDetailView extends GetView<CustomerDetailViewModel> {
  const CustomerDetailView({super.key});

  static const wideBreakpoint = 900.0;
  static const maxWidth = 1160.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Customer'.tr),
      body: Obx(() {
        if (controller.isLoading.value) return const LoadingView();
        final user = controller.customer.value;
        final error = controller.error.value;
        if (error != null && user == null) {
          return ErrorView(message: error, onRetry: controller.listen);
        }
        if (controller.notFound.value || user == null) {
          return const EmptyView(
            icon: Icons.person_off_outlined,
            title: 'Customer not found',
            message:
                'They may have deleted their account. Their orders '
                'stay under Orders as "Deleted customer".',
          );
        }
        return LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= wideBreakpoint;
            final side = [
              _ProfileCard(user: user),
              const SizedBox(height: 16),
              const _AddressesCard(),
            ];
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxWidth),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 24 : 20,
                    8,
                    wide ? 24 : 20,
                    32,
                  ),
                  children: [
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: side,
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Expanded(flex: 3, child: _OrdersCard()),
                        ],
                      )
                    else ...[
                      ...side,
                      const SizedBox(height: 16),
                      const _OrdersCard(),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title.tr, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends GetView<CustomerDetailViewModel> {
  const _ProfileCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.palette.mutedText;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CustomerAvatar(user, size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName, style: theme.textTheme.titleLarge),
                      if (user.disabled) ...[
                        const SizedBox(height: 6),
                        const DisabledChip(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Line(icon: Icons.mail_outline, text: user.email),
            if (user.phone.isNotEmpty)
              _Line(icon: Icons.phone_outlined, text: user.phone),
            const Divider(height: 32),
            Obx(
              () => Row(
                children: [
                  _Stat(label: 'Orders', value: '${controller.orderCount}'),
                  _Stat(
                    label: 'Spent',
                    value: Formatters.price(controller.totalSpent),
                  ),
                  _Stat(
                    label: 'Last order',
                    value: controller.lastOrderAt == null
                        ? '-'
                        : Formatters.date(controller.lastOrderAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _DisableButton(user: user),
            if (!controller.canDisable) ...[
              const SizedBox(height: 8),
              Text(
                'Disabling needs the server: set FUNCTIONS_BASE_URL and deploy '
                        'the Cloud Functions.'
                    .tr,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ] else if (user.disabled && user.disabledAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Disabled on @date'.trParams({
                  'date': Formatters.date(user.disabledAt),
                }),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DisableButton extends GetView<CustomerDetailViewModel> {
  const _DisableButton({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final busy = controller.isUpdating.value;
      final enabled = controller.canDisable && !busy;
      if (user.disabled) {
        return OutlinedButton.icon(
          onPressed: enabled ? () => _confirm(context, disable: false) : null,
          icon: const Icon(Icons.lock_open_outlined),
          label: Text('Enable account'.tr),
        );
      }
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.error,
          side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
        ),
        onPressed: enabled ? () => _confirm(context, disable: true) : null,
        icon: const Icon(Icons.block_outlined),
        label: Text('Disable account'.tr),
      );
    });
  }

  Future<void> _confirm(BuildContext context, {required bool disable}) async {
    final open = controller.openOrders;
    final ok = await showConfirmDialog(
      context,
      title: disable
          ? 'Disable @name?'.trParams({'name': user.displayName})
          : 'Enable @name?'.trParams({'name': user.displayName}),
      message: disable
          ? (open == 0
                ? 'They are signed out everywhere and can\'t sign in or '
                      'order. Their orders and data are kept. You can '
                      'enable the account again later.'
                : open == 1
                ? 'They are signed out everywhere and can\'t sign in or '
                      'order. Their open order stays open; cancel it under '
                      'Orders if needed.'
                : 'They are signed out everywhere and can\'t sign in or '
                          'order. Their @n open orders stay open; cancel them '
                          'under Orders if needed.'
                      .trParams({'n': '$open'}))
          : 'They can sign in and order again.',
      confirmLabel: disable ? 'Disable' : 'Enable',
      destructive: disable,
    );
    if (ok) await controller.setDisabled(disable);
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.palette.mutedText),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.tr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.palette.mutedText,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: theme.textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

class _AddressesCard extends GetView<CustomerDetailViewModel> {
  const _AddressesCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.palette.mutedText;
    return _Card(
      title: 'Saved addresses',
      child: Obx(() {
        if (controller.addresses.isEmpty) {
          return Text(
            'No saved addresses.'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, a) in controller.addresses.indexed) ...[
              if (i > 0) const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.label.isEmpty ? a.fullName : a.label,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (a.isDefault)
                    Text(
                      'Default'.tr,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: muted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (a.label.isNotEmpty) a.fullName,
                  a.phone,
                  a.formatted,
                ].where((s) => s.isNotEmpty).join('\n'),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _OrdersCard extends GetView<CustomerDetailViewModel> {
  const _OrdersCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.palette.mutedText;
    return _Card(
      title: 'Orders',
      child: Obx(() {
        final orders = controller.orders;
        if (orders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No orders yet.'.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          );
        }
        return Column(
          children: [
            for (final (i, o) in orders.indexed) ...[
              if (i > 0) const Divider(height: 1),
              InkWell(
                onTap: () => controller.openOrder(o),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${o.shortId}',
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              Formatters.dateTime(o.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OrderStatusChip(o.orderStatus),
                                PaymentChip(o),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        Formatters.price(o.totalPrice),
                        style: theme.textTheme.titleMedium,
                      ),
                      Icon(Icons.chevron_right_rounded, color: muted),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}
