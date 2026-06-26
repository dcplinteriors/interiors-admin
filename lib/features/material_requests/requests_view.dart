import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/material_requests_controller.dart';
import 'package:dcpl_admin/features/material_requests/widgets/accept_request_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/assign_vendor_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/close_bills_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/decline_request_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/edit_request_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/request_attachments_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/request_detail_dialog.dart';
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
        LoadMoreBar(controller: controller, label: AppLocalizations.of(context).loadMore),
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
            isRefreshing: controller.isLoading.value && controller.requests.isNotEmpty,
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
                FilterOption(s, _statusLabel(l10n, s), swatch: context.statusColors.forRequest(s.wire).ink),
            ],
          ),
          // Independent of the project cascade — a supervisor's items can span projects.
          FilterDropdown<String?>(
            value: controller.supervisorFilter.value,
            onChanged: controller.setSupervisorFilter,
            options: [FilterOption(null, l10n.allSupervisors), for (final s in controller.supervisors) FilterOption(s.uid, s.name)],
          ),
          FilterDropdown<String?>(
            value: controller.projectFilter.value,
            onChanged: controller.setProjectFilter,
            options: [FilterOption(null, l10n.allProjects), for (final p in controller.projects) FilterOption(p.id, p.name)],
          ),
          // Cascades from the project: shown (enabled) only once a project is
          // picked, so the field is always created fresh in a working state
          // rather than toggled disabled→enabled in place.
          if (controller.projectFilter.value != null)
            FilterDropdown<String?>(
              value: controller.workOrderFilter.value,
              onChanged: controller.setWorkOrderFilter,
              options: [FilterOption(null, l10n.allWorkOrders), for (final w in controller.workOrders) FilterOption(w.id, w.name)],
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
        return ErrorState(title: l10n.couldntLoadRequests, message: controller.error.value!, onRetry: controller.fetch);
      }
      if (controller.requests.isEmpty) {
        return EmptyState(icon: Icons.inbox_outlined, title: l10n.nothingHereTitle, body: l10n.noRequestsBody);
      }
      return context.isCompact ? _Cards(controller.requests.toList()) : _Table(controller.requests.toList());
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
          onTap: () => _openDetail(context, r),
          fields: [
            EntityField(l10n.colMake, text: r.make, muted: true),
            if (r.size.isNotEmpty) EntityField(l10n.colSize, text: r.size),
            EntityField(l10n.colQty, text: l10n.qtyWithUnit(r.quantityLabel, r.unit)),
            EntityField(l10n.navWorkOrders, text: r.workOrderName ?? 'N/A'),
            EntityField(l10n.colClient, text: r.clientName ?? 'N/A'),
            EntityField(l10n.colSupervisor, text: r.supervisorName ?? 'N/A'),
            EntityField(l10n.colSubmitted, text: formatDate(r.createdAt)),
            if (r.attachments.isNotEmpty)
              EntityField(
                l10n.attachments,
                child: Align(alignment: Alignment.centerLeft, child: _AttachmentButton(r)),
              ),
            if (r.billImages.isNotEmpty)
              EntityField(
                l10n.billsTitle,
                child: Align(alignment: Alignment.centerLeft, child: _BillButton(r)),
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
        DcplColumn(l10n.colItem, flex: 4),
        DcplColumn(l10n.colFiles, fixedWidth: 100),
        DcplColumn(l10n.colWorkOrderClient, flex: 3),
        DcplColumn(l10n.colSupervisor, flex: 3),
        DcplColumn(l10n.colSubmitted, fixedWidth: 96, numeric: true),
        DcplColumn(l10n.colStatus, fixedWidth: 168),
        DcplColumn(l10n.colActions, fixedWidth: 240),
      ],
      rows: [
        for (final r in requests)
          DcplRow(
            railColor: status.forRequest(r.status.wire).ink,
            onTap: () => _openDetail(context, r),
            cells: [
              PrimaryCell(r.particular, subtitle: _itemSubtitle(l10n, r)),
              _FilesCell(r),
              _WorkOrderClientCell(r, muted),
              Text(r.supervisorName ?? 'N/A'),
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
  const _AttachmentButton(this.request);

  final MaterialRequest request;

  @override
  Widget build(BuildContext context) {
    final count = request.attachments.photos.length + (request.attachments.audio != null ? 1 : 0);
    void open() => showDialog<void>(
      context: context,
      builder: (_) => RequestAttachmentsDialog(attachments: request.attachments),
    );
    return TextButton.icon(
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), visualDensity: VisualDensity.compact),
      icon: const Icon(Icons.attach_file, size: 18),
      label: Text('$count'),
      onPressed: open,
    );
  }
}

/// Opens the bill image(s) + close note a supervisor attached when closing the item.
class _BillButton extends StatelessWidget {
  const _BillButton(this.request);

  final MaterialRequest request;

  @override
  Widget build(BuildContext context) {
    final count = request.billImages.length;
    void open() => showDialog<void>(
      context: context,
      builder: (_) => CloseBillsDialog(billImages: request.billImages, note: request.closeNote),
    );
    return TextButton.icon(
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), visualDensity: VisualDensity.compact),
      icon: const Icon(Icons.receipt_long_outlined, size: 18),
      label: Text('$count'),
      onPressed: open,
    );
  }
}

/// The desktop table's "Files" cell: attachment + bill count chips, aligned in
/// their own column (so they line up row-to-row instead of crowding the item
/// title). A muted dash when the item has neither.
class _FilesCell extends StatelessWidget {
  const _FilesCell(this.request);

  final MaterialRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final photos = request.attachments.photos.length;
    final hasAudio = request.attachments.audio != null;
    final bills = request.billImages.length;
    if (photos == 0 && !hasAudio && bills == 0) {
      return Text('—', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant));
    }
    void openAttachments() => showDialog<void>(
      context: context,
      builder: (_) => RequestAttachmentsDialog(attachments: request.attachments),
    );
    void openBills() => showDialog<void>(
      context: context,
      builder: (_) => CloseBillsDialog(billImages: request.billImages, note: request.closeNote),
    );
    // Distinct icons per kind: photos, the voice note, and bills.
    final chips = <Widget>[
      if (photos > 0) _CountChip(icon: Icons.image_outlined, count: photos, tooltip: l10n.photos, onTap: openAttachments),
      if (hasAudio)
        _CountChip(
          icon: Icons.graphic_eq,
          count: null, // a single voice note — icon only
          tooltip: l10n.audioNote,
          onTap: openAttachments,
        ),
      if (bills > 0) _CountChip(icon: Icons.receipt_long_outlined, count: bills, tooltip: l10n.billsTitle, onTap: openBills),
    ];
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < chips.length; i++) ...[if (i > 0) const SizedBox(width: 6), chips[i]],
        ],
      ),
    );
  }
}

/// A compact `icon + count` pill for the dense table cell — reads as "📎 2"
/// instead of a floating badge stacked on a tiny icon (which looked cramped,
/// doubly so with attachments + bills side by side). Bordered + muted so it sits
/// quietly in the row and doesn't fight the status rail or hover highlight.
class _CountChip extends StatelessWidget {
  const _CountChip({required this.icon, required this.count, required this.tooltip, required this.onTap});

  final IconData icon;

  /// The badge number, or null for an icon-only chip (e.g. a single voice note).
  final int? count;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: cs.onSurfaceVariant),
                if (count != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The combined "Work order / Client" cell — the work order name with its client
/// beneath, so the two related bits of context share one column.
class _WorkOrderClientCell extends StatelessWidget {
  const _WorkOrderClientCell(this.request, this.muted);

  final MaterialRequest request;
  final Color muted;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(request.workOrderName ?? 'N/A', maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(
        request.clientName ?? 'N/A',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
      ),
    ],
  );
}

/// Status-gated actions for a request row.
class _RowActions extends StatelessWidget {
  const _RowActions(this.request, this.muted);

  final MaterialRequest request;
  final Color muted;

  // Shared compact sizing so every action button in the column matches.
  static const _compact = ButtonStyle(
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
    visualDensity: VisualDensity.compact,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = request;

    switch (r.status) {
      case MaterialRequestStatus.requested:
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                style: _compact,
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => DeclineRequestDialog(request: r),
                ),
                child: Text(l10n.decline),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                style: _compact,
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AcceptRequestDialog(request: r),
                ),
                child: Text(l10n.accept),
              ),
              const SizedBox(width: 8),
              _editButton(context, l10n, r),
            ],
          ),
        );
      case MaterialRequestStatus.processing:
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.tonal(
                style: _compact,
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AssignVendorDialog(request: r),
                ),
                child: Text(l10n.assignVendor),
              ),
              const SizedBox(width: 8),
              _editButton(context, l10n, r),
            ],
          ),
        );
      case MaterialRequestStatus.accepted:
        final text = (r.vendor != null && r.vendor!.isNotEmpty) ? l10n.vendorArrow(r.vendor!) : l10n.statusAccepted;
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

  /// Edit affordance for the Actions column — labeled like the other actions, and
  /// only shown while the item is still requested/processing (where it's rendered).
  Widget _editButton(BuildContext context, AppLocalizations l10n, MaterialRequest r) => TextButton.icon(
    style: _compact,
    icon: const Icon(Icons.edit_outlined, size: 18),
    label: Text(l10n.editItemAction),
    onPressed: () => showDialog<void>(
      context: context,
      builder: (_) => EditRequestDialog(request: r),
    ),
  );
}

/// Opens the read-only detail dialog showing every field of [r] (both the card
/// and the table row use this, so the two layouts can't drift).
void _openDetail(BuildContext context, MaterialRequest r) => showDialog<void>(
  context: context,
  builder: (_) => RequestDetailDialog(request: r),
);

// The make + size + quantity context line under an item title.
String _itemSubtitle(AppLocalizations l10n, MaterialRequest r) =>
    [r.make, r.size, l10n.qtyWithUnit(r.quantityLabel, r.unit)].where((s) => s.isNotEmpty).join(' · ');

String _statusLabel(AppLocalizations l10n, MaterialRequestStatus s) => switch (s) {
  MaterialRequestStatus.requested => l10n.statusRequested,
  MaterialRequestStatus.processing => l10n.statusProcessing,
  MaterialRequestStatus.accepted => l10n.statusAccepted,
  MaterialRequestStatus.closed => '${l10n.statusClosed} ${l10n.statusBySupervisorSuffix}',
  MaterialRequestStatus.declined => l10n.statusDeclined,
  MaterialRequestStatus.cancelled => '${l10n.statusCancelled} ${l10n.statusBySupervisorSuffix}',
};
