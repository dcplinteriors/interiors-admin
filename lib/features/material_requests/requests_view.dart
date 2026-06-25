import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/material_requests_controller.dart';
import 'package:dcpl_admin/features/material_requests/widgets/accept_request_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/assign_vendor_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/close_bills_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/decline_request_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/request_attachments_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/request_status_chip.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestsView extends GetView<MaterialRequestsController> {
  const RequestsView({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: context.pagePadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        const SizedBox(height: 20),
        const _Filters(),
        const SizedBox(height: 20),
        const Expanded(child: _Body()),
        LoadMoreBar(
          controller: controller,
          label: AppLocalizations.of(context).loadMore,
        ),
      ],
    ),
  );
}

class _Header extends GetView<MaterialRequestsController> {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Obx(
      () => PageHeader(
        title: l10n.materialRequestsTitle,
        count: l10n.countRequests(controller.requests.length),
        actions: [
          RefreshButton(
            tooltip: l10n.refresh,
            onPressed: controller.fetch,
            isRefreshing:
                controller.isLoading.value && controller.requests.isNotEmpty,
          ),
        ],
      ),
    );
  }
}

class _Filters extends GetView<MaterialRequestsController> {
  const _Filters();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Obx(
      () => Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilterDropdown<MaterialRequestStatus?>(
            value: controller.statusFilter.value,
            onChanged: controller.setStatusFilter,
            options: [
              FilterOption(null, l10n.allStatuses),
              for (final s in MaterialRequestStatus.values)
                FilterOption(s, _statusLabel(l10n, s)),
            ],
          ),
          FilterDropdown<String?>(
            value: controller.projectFilter.value,
            onChanged: controller.setProjectFilter,
            options: [
              FilterOption(null, l10n.allProjects),
              for (final p in controller.projects) FilterOption(p.id, p.name),
            ],
          ),
          // Cascades from the project: shown (enabled) only once a project is
          // picked, so the field is always created fresh in a working state
          // rather than toggled disabled→enabled in place.
          if (controller.projectFilter.value != null)
            FilterDropdown<String?>(
              value: controller.workOrderFilter.value,
              onChanged: controller.setWorkOrderFilter,
              options: [
                FilterOption(null, l10n.allWorkOrders),
                for (final w in controller.workOrders)
                  FilterOption(w.id, w.name),
              ],
            ),
        ],
      ),
    );
  }
}

class _Body extends GetView<MaterialRequestsController> {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Obx(() {
      if (controller.isLoading.value && controller.requests.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value != null) {
        return ErrorState(
          title: l10n.couldntLoadRequests,
          message: controller.error.value!,
          onRetry: controller.fetch,
        );
      }
      if (controller.requests.isEmpty) {
        return EmptyState(
          icon: Icons.inbox_outlined,
          title: l10n.nothingHereTitle,
          body: l10n.noRequestsBody,
        );
      }
      return context.isCompact
          ? _Cards(controller.requests.toList())
          : _Table(controller.requests.toList());
    });
  }
}

class _Cards extends StatelessWidget {
  const _Cards(this.requests);

  final List<MaterialRequest> requests;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final status = context.statusColors;
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = requests[i];
        return EntityCard(
          eyebrow: l10n.colItem,
          railColor: status.forRequest(r.status.wire).ink,
          title: r.particular,
          trailing: RequestStatusChip(r.status),
          fields: [
            EntityField(l10n.colMake, text: r.make, muted: true),
            if (r.size.isNotEmpty) EntityField(l10n.colSize, text: r.size),
            EntityField(
              l10n.colQty,
              text: l10n.qtyWithUnit(r.quantityLabel, r.unit),
            ),
            EntityField(l10n.navWorkOrders, text: r.workOrderName ?? '—'),
            EntityField(l10n.colClient, text: r.clientName ?? '—'),
            EntityField(l10n.colSupervisor, text: r.supervisorName ?? '—'),
            EntityField(l10n.colSubmitted, text: formatDate(r.createdAt)),
            if (r.attachments.isNotEmpty)
              EntityField(
                l10n.attachments,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _AttachmentButton(r),
                ),
              ),
            if (r.billImages.isNotEmpty)
              EntityField(
                l10n.billsTitle,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _BillButton(r),
                ),
              ),
          ],
          footer: _RowActions(r, muted),
        );
      },
    );
  }
}

class _Table extends StatelessWidget {
  const _Table(this.requests);

  final List<MaterialRequest> requests;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final status = context.statusColors;
    return DcplTable(
      columns: [
        DcplColumn(l10n.colItem, flex: 3),
        DcplColumn(l10n.colQty, fixedWidth: 100),
        DcplColumn(l10n.navWorkOrders, flex: 2),
        DcplColumn(l10n.colSupervisor, flex: 2),
        DcplColumn(l10n.colSubmitted, fixedWidth: 96, numeric: true),
        DcplColumn(l10n.colStatus, fixedWidth: 168),
        const DcplColumn('', fixedWidth: 210),
      ],
      rows: [
        for (final r in requests)
          DcplRow(
            railColor: status.forRequest(r.status.wire).ink,
            cells: [
              Row(
                children: [
                  Expanded(
                    child: PrimaryCell(
                      r.particular,
                      subtitle: _itemSubtitle(r),
                    ),
                  ),
                  if (r.attachments.isNotEmpty)
                    _AttachmentButton(r, dense: true),
                  if (r.billImages.isNotEmpty) _BillButton(r, dense: true),
                ],
              ),
              Text(l10n.qtyWithUnit(r.quantityLabel, r.unit)),
              Text(r.workOrderName ?? '—'),
              Text(r.supervisorName ?? '—'),
              Text(formatDate(r.createdAt)),
              RequestStatusChip(r.status),
              _RowActions(r, muted),
            ],
          ),
      ],
    );
  }
}

class _AttachmentButton extends StatelessWidget {
  const _AttachmentButton(this.request, {this.dense = false});

  final MaterialRequest request;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final count =
        request.attachments.photos.length +
        (request.attachments.audio != null ? 1 : 0);
    void open() => showDialog<void>(
      context: context,
      builder: (_) =>
          RequestAttachmentsDialog(attachments: request.attachments),
    );
    if (dense) {
      return IconButton(
        tooltip: l10n.attachments,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        iconSize: 16,
        icon: Badge(
          label: Text('$count'),
          child: const Icon(Icons.attach_file),
        ),
        onPressed: open,
      );
    }
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
      ),
      icon: const Icon(Icons.attach_file, size: 18),
      label: Text('$count'),
      onPressed: open,
    );
  }
}

/// Opens the bill image(s) + close note a supervisor attached when closing the item.
class _BillButton extends StatelessWidget {
  const _BillButton(this.request, {this.dense = false});

  final MaterialRequest request;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final count = request.billImages.length;
    void open() => showDialog<void>(
      context: context,
      builder: (_) => CloseBillsDialog(
        billImages: request.billImages,
        note: request.closeNote,
      ),
    );
    if (dense) {
      return IconButton(
        tooltip: l10n.billsTitle,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        iconSize: 16,
        icon: Badge(
          label: Text('$count'),
          child: const Icon(Icons.receipt_long_outlined),
        ),
        onPressed: open,
      );
    }
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
      ),
      icon: const Icon(Icons.receipt_long_outlined, size: 18),
      label: Text('$count'),
      onPressed: open,
    );
  }
}

/// Status-gated actions for a request row.
class _RowActions extends StatelessWidget {
  const _RowActions(this.request, this.muted);

  final MaterialRequest request;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = request;
    const compact = ButtonStyle(
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    switch (r.status) {
      case MaterialRequestStatus.requested:
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                style: compact,
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => DeclineRequestDialog(request: r),
                ),
                child: Text(l10n.decline),
              ),
              const SizedBox(width: 6),
              FilledButton.tonal(
                style: compact,
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AcceptRequestDialog(request: r),
                ),
                child: Text(l10n.accept),
              ),
            ],
          ),
        );
      case MaterialRequestStatus.processing:
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: FilledButton.tonal(
            style: compact,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AssignVendorDialog(request: r),
            ),
            child: Text(l10n.assignVendor),
          ),
        );
      case MaterialRequestStatus.accepted:
        final text = (r.vendor != null && r.vendor!.isNotEmpty)
            ? l10n.vendorArrow(r.vendor!)
            : l10n.statusAccepted;
        return Text(
          text,
          style: TextStyle(color: muted),
          overflow: TextOverflow.ellipsis,
        );
      case MaterialRequestStatus.declined:
        return Text(l10n.declinedShort, style: TextStyle(color: muted));
      case MaterialRequestStatus.cancelled:
        return Text(l10n.withdrawnShort, style: TextStyle(color: muted));
      case MaterialRequestStatus.closed:
        return Text('—', style: TextStyle(color: muted));
    }
  }
}

// The make + size context line under an item title.
String _itemSubtitle(MaterialRequest r) =>
    [r.make, r.size].where((s) => s.isNotEmpty).join(' · ');

String _statusLabel(AppLocalizations l10n, MaterialRequestStatus s) =>
    switch (s) {
      MaterialRequestStatus.requested => l10n.statusRequested,
      MaterialRequestStatus.processing => l10n.statusProcessing,
      MaterialRequestStatus.accepted => l10n.statusAccepted,
      MaterialRequestStatus.closed => l10n.statusClosed,
      MaterialRequestStatus.declined => l10n.statusDeclined,
      MaterialRequestStatus.cancelled => l10n.statusCancelled,
    };
