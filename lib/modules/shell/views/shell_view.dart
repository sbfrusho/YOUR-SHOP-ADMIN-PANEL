import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/brand/app_logo.dart';
import '../../orders/views/orders_view.dart';
import '../view_models/shell_view_model.dart';
import 'section_placeholder_view.dart';

/// Responsive admin shell: a side rail at [ShellViewModel.wideBreakpoint]
/// and wider (tablets, web), a bottom navigation bar on phones.
class ShellView extends GetView<ShellViewModel> {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= ShellViewModel.wideBreakpoint;
        return Obx(() {
          final page = KeyedSubtree(
            key: ValueKey(controller.section.value),
            child: _page(controller.section.value),
          );
          if (!wide) {
            return Scaffold(
              body: page,
              bottomNavigationBar: NavigationBar(
                selectedIndex: controller.index,
                onDestinationSelected: controller.select,
                destinations: [
                  for (final s in AdminSection.values)
                    NavigationDestination(
                      icon: Icon(s.icon),
                      selectedIcon: Icon(s.selectedIcon),
                      label: s.label.tr,
                    ),
                ],
              ),
            );
          }
          final extended = width >= ShellViewModel.extendedBreakpoint;
          return Scaffold(
            body: Row(
              children: [
                _Rail(extended: extended),
                const VerticalDivider(width: 1),
                Expanded(child: page),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _page(AdminSection section) => switch (section) {
    AdminSection.dashboard => const SectionPlaceholderView(
      section: AdminSection.dashboard,
      message:
          "Today's orders and revenue, pending orders, low stock and best "
          'sellers arrive in Sprint 5.',
    ),
    AdminSection.orders => const OrdersView(),
    AdminSection.products => const SectionPlaceholderView(
      section: AdminSection.products,
      message:
          'Create, edit and archive products with images, sizes and sale '
          'prices in Sprint 3.',
    ),
    AdminSection.catalogue => const SectionPlaceholderView(
      section: AdminSection.catalogue,
      message: 'Categories and home banners arrive in Sprint 4.',
    ),
    AdminSection.customers => const SectionPlaceholderView(
      section: AdminSection.customers,
      message: 'Customers and their order history arrive in Sprint 6.',
    ),
  };
}

class _Rail extends GetView<ShellViewModel> {
  const _Rail({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: extended,
      minExtendedWidth: 232,
      selectedIndex: controller.index,
      onDestinationSelected: controller.select,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 24),
        child: extended
            ? const AppLogo(size: 36, showWordmark: true, badge: 'ADMIN')
            : const AppLogo(size: 36),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: AppIconButton(
              icon: Icons.settings_outlined,
              tooltip: 'Settings',
              onPressed: () => Get.toNamed<void>(AppRoutes.settings),
            ),
          ),
        ),
      ),
      destinations: [
        for (final s in AdminSection.values)
          NavigationRailDestination(
            icon: Icon(s.icon),
            selectedIcon: Icon(s.selectedIcon),
            label: Text(s.label.tr),
          ),
      ],
    );
  }
}
