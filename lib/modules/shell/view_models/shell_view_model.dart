import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The admin areas, in navigation order.
enum AdminSection {
  dashboard('Dashboard', Icons.space_dashboard_outlined, Icons.space_dashboard),
  orders('Orders', Icons.receipt_long_outlined, Icons.receipt_long),
  products('Products', Icons.checkroom_outlined, Icons.checkroom),
  catalogue('Catalogue', Icons.category_outlined, Icons.category),
  customers('Customers', Icons.people_outline, Icons.people);

  const AdminSection(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class ShellViewModel extends GetxController {
  /// Width at which the side rail and tables replace the bottom bar.
  static const wideBreakpoint = 900.0;

  /// Width at which the rail shows its labels beside the icons.
  static const extendedBreakpoint = 1200.0;

  final Rx<AdminSection> section = AdminSection.dashboard.obs;

  int get index => section.value.index;

  void select(int index) => section.value = AdminSection.values[index];
}
