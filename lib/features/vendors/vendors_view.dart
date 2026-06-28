import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/vendors/vendors.dart';
import 'package:dcpl_shared/models/models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VendorsView extends GetView<VendorsController> {
  const VendorsView({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: context.pagePadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        const SizedBox(height: 24),
        const Expanded(child: _Body()),
        LoadMoreBar(
          controller: controller,
          label: AppLocalizations.of(context).loadMore,
        ),
      ],
    ),
  );
}

class _Header extends GetView<VendorsController> {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Obx(
      () => PageHeader(
        title: l10n.navVendors,
        count: '${controller.vendors.length}',
        actions: [
          RefreshButton(
            tooltip: l10n.refresh,
            onPressed: controller.fetch,
            isRefreshing:
                controller.isLoading.value && controller.vendors.isNotEmpty,
          ),
          const _CreateAction(),
        ],
      ),
    );
  }
}

class _CreateAction extends StatelessWidget {
  const _CreateAction();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return context.isCompact
        ? IconButton.filled(
            tooltip: l10n.newVendor,
            onPressed: () => _openCreate(context),
            icon: const Icon(Icons.add),
          )
        : GradientButton(
            onPressed: () => _openCreate(context),
            icon: Icons.add,
            label: l10n.newVendor,
          );
  }
}

void _openCreate(BuildContext context) =>
    showDialog(context: context, builder: (_) => const VendorDialog());

void _openEdit(BuildContext context, Vendor vendor) =>
    showDialog(context: context, builder: (_) => VendorDialog(vendor: vendor));

Future<void> _toggleActive(BuildContext context, Vendor vendor) async {
  final l10n = AppLocalizations.of(context);
  try {
    await Get.find<VendorsController>().edit(vendor.id, isActive: !vendor.isActive);
    showAppSnackbar(
      vendor.isActive ? l10n.vendorDeactivated : l10n.vendorReactivated,
    );
  } on ApiException catch (e) {
    showAppSnackbar(e.message);
  }
}

class _Body extends GetView<VendorsController> {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Obx(() {
      if (controller.isLoading.value && controller.vendors.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value != null) {
        return ErrorState(
          title: l10n.couldntLoadVendors,
          message: controller.error.value!,
          onRetry: controller.fetch,
        );
      }
      if (controller.vendors.isEmpty) {
        return EmptyState(
          icon: Icons.store_outlined,
          title: l10n.noVendorsTitle,
          body: l10n.noVendorsBody,
          action: FilledButton.icon(
            onPressed: () => _openCreate(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.newVendor),
          ),
        );
      }
      return context.isCompact
          ? _Cards(controller.vendors.toList())
          : _Table(controller.vendors.toList());
    });
  }
}

class _Cards extends StatelessWidget {
  const _Cards(this.vendors);

  final List<Vendor> vendors;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: EdgeInsets.zero,
    itemCount: vendors.length,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (context, i) {
      final v = vendors[i];
      return EntityCard(
        title: v.name,
        trailing: _StatusChip(v.isActive),
        fields: const [],
        footer: _VendorActions(v),
      );
    },
  );
}

class _Table extends StatelessWidget {
  const _Table(this.vendors);

  final List<Vendor> vendors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DcplTable(
      columns: [
        DcplColumn(l10n.colName, flex: 3),
        DcplColumn(l10n.colStatus, fixedWidth: 120),
        DcplColumn(l10n.colActions, fixedWidth: 220),
      ],
      rows: [
        for (final v in vendors)
          DcplRow(
            cells: [
              PrimaryCell(v.name),
              _StatusChip(v.isActive),
              _VendorActions(v),
            ],
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.isActive);

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = isActive ? scheme.primary : scheme.onSurfaceVariant;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isActive ? l10n.statusActiveLabel : l10n.statusInactiveLabel,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: color),
        ),
      ),
    );
  }
}

class _VendorActions extends StatelessWidget {
  const _VendorActions(this.vendor);

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const compact = ButtonStyle(
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            style: compact,
            onPressed: () => _openEdit(context, vendor),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(l10n.editItemAction),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: compact,
            onPressed: () => _toggleActive(context, vendor),
            child: Text(
              vendor.isActive ? l10n.deactivate : l10n.reactivate,
            ),
          ),
        ],
      ),
    );
  }
}
