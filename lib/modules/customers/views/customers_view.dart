import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/user_model.dart';
import '../../shell/view_models/shell_view_model.dart';
import '../../shell/views/settings_button.dart';
import '../view_models/customers_view_model.dart';
import 'customer_avatar.dart';

class CustomersView extends GetView<CustomersViewModel> {
  const CustomersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar.large(
        title: 'Customers',
        actions: [SettingsButton()],
      ),
      body: Column(
        children: [
          const _FilterBar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const LoadingView();
              final error = controller.error.value;
              if (error != null) {
                return ErrorView(message: error, onRetry: controller.listen);
              }
              final list = controller.visible;
              if (list.isEmpty) {
                final none = controller.customers.isEmpty;
                return EmptyView(
                  icon: Icons.people_outline,
                  title: none ? 'No customers yet' : 'No matching customers',
                  message: none
                      ? 'Customers appear here once they sign up in the shop.'
                      : 'Try another filter or search.',
                  action: none
                      ? null
                      : OutlinedButton(
                          onPressed: controller.clearFilters,
                          child: Text('Clear filters'.tr),
                        ),
                );
              }
              return LayoutBuilder(
                builder: (context, c) =>
                    c.maxWidth >= ShellViewModel.wideBreakpoint - 120
                    ? _CustomersTable(customers: list)
                    : _CustomersList(customers: list),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends GetView<CustomersViewModel> {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: controller.query.call,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by name, email or phone'.tr,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Wrap(
              spacing: 8,
              children: [
                for (final f in CustomerFilter.values)
                  ChoiceChip(
                    showCheckmark: false,
                    label: Text('${f.label.tr} (${controller.count(f)})'),
                    selected: controller.filter.value == f,
                    onSelected: (_) => controller.filter.value = f,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DisabledChip extends StatelessWidget {
  const DisabledChip({super.key});

  @override
  Widget build(BuildContext context) =>
      const StatusChip(label: 'Disabled', tone: StatusTone.error);
}

class _CustomersList extends GetView<CustomersViewModel> {
  const _CustomersList({required this.customers});

  final List<UserModel> customers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.palette.mutedText;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: customers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final u = customers[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => controller.open(u),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CustomerAvatar(u),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.displayName,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          [
                            u.email,
                            u.phone,
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (u.disabled) ...[
                    const SizedBox(width: 8),
                    const DisabledChip(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CustomersTable extends GetView<CustomersViewModel> {
  const _CustomersTable({required this.customers});

  final List<UserModel> customers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.palette.mutedText;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: c.maxWidth),
              child: DataTable(
                showCheckboxColumn: false,
                columnSpacing: 28,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 72,
                headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                  color: muted,
                ),
                columns: [
                  DataColumn(label: Text('Customer'.tr)),
                  DataColumn(label: Text('Email'.tr)),
                  DataColumn(label: Text('Phone'.tr)),
                  DataColumn(label: Text('Status'.tr)),
                ],
                rows: [
                  for (final u in customers)
                    DataRow(
                      onSelectChanged: (_) => controller.open(u),
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              CustomerAvatar(u, size: 40),
                              const SizedBox(width: 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 240,
                                ),
                                child: Text(
                                  u.displayName,
                                  style: theme.textTheme.titleSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(u.email)),
                        DataCell(Text(u.phone.isEmpty ? '-' : u.phone)),
                        DataCell(
                          u.disabled
                              ? const DisabledChip()
                              : const StatusChip(
                                  label: 'Active',
                                  tone: StatusTone.success,
                                ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
