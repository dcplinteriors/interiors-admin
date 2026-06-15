import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/material_requests_controller.dart';
import 'package:dcpl_admin/features/material_requests/widgets/accept_request_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/decline_request_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/request_attachments_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/request_status_chip.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestsView extends GetView<MaterialRequestsController> {
  const RequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: context.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() => PageHeader(
                title: l10n.materialRequestsTitle,
                count: _countLabel(l10n),
                actions: [
                  Obx(() => RefreshButton(
                        tooltip: l10n.refresh,
                        onPressed: controller.fetch,
                        isRefreshing: controller.isLoading.value &&
                            controller.requests.isNotEmpty,
                      )),
                ],
              )),
          const SizedBox(height: 20),
          Obx(() => _filter(l10n)),
          const SizedBox(height: 20),
          Expanded(child: Obx(() => _body(context, l10n))),
          Obx(() => _loadMoreBar(l10n)),
        ],
      ),
    );
  }

  Widget _loadMoreBar(AppLocalizations l10n) {
    if (!controller.hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: controller.isLoadingMore.value
            ? const SizedBox(
                height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : OutlinedButton.icon(
                onPressed: controller.loadMore,
                icon: const Icon(Icons.expand_more),
                label: Text(l10n.loadMore),
              ),
      ),
    );
  }

  String _countLabel(AppLocalizations l10n) {
    final n = controller.requests.length;
    return switch (controller.statusFilter.value) {
      'requested' => l10n.countToReview(n),
      'accepted' => l10n.countAccepted(n),
      'declined' => l10n.countDeclined(n),
      'cancelled' => l10n.countCancelled(n),
      _ => l10n.countRequests(n),
    };
  }

  Widget _filter(AppLocalizations l10n) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<String?>(
          showSelectedIcon: false,
          // softWrap:false so each segment sizes to its full label — in the
          // unbounded scroll view SegmentedButton would otherwise collapse
          // segments to their longest word and wrap the labels.
          segments: [
            ButtonSegment(value: null, label: Text(l10n.segAll, softWrap: false, maxLines: 1)),
            ButtonSegment(value: 'requested', label: Text(l10n.segToReview, softWrap: false, maxLines: 1)),
            ButtonSegment(value: 'accepted', label: Text(l10n.segAccepted, softWrap: false, maxLines: 1)),
            ButtonSegment(value: 'declined', label: Text(l10n.segDeclined, softWrap: false, maxLines: 1)),
            ButtonSegment(value: 'cancelled', label: Text(l10n.segCancelled, softWrap: false, maxLines: 1)),
          ],
          selected: {controller.statusFilter.value},
          onSelectionChanged: (s) => controller.setFilter(s.first),
        ),
      );

  Widget _body(BuildContext context, AppLocalizations l10n) {
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
      return _emptyState(l10n);
    }
    return context.isCompact ? _cards(context, l10n) : _table(context, l10n);
  }

  // The make + size context line under an item title.
  String _itemSubtitle(MaterialRequest r) =>
      [r.make, r.size].where((s) => s.isNotEmpty).join(' · ');

  Widget _attachmentButton(BuildContext context, AppLocalizations l10n, MaterialRequest r) {
    final count = r.attachments.photos.length + (r.attachments.audio != null ? 1 : 0);
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
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => RequestAttachmentsDialog(attachments: r.attachments),
      ),
    );
  }

  Widget _cards(BuildContext context, AppLocalizations l10n) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final status = context.statusColors;
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: controller.requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = controller.requests[i];
        return EntityCard(
          eyebrow: l10n.colItem,
          railColor: status.forRequest(r.status).ink,
          title: r.particular,
          trailing: RequestStatusChip(r.status),
          fields: [
            EntityField(l10n.colMake, text: r.make, muted: true),
            if (r.size.isNotEmpty) EntityField(l10n.colSize, text: r.size),
            EntityField(l10n.colQty, text: l10n.qtyWithUnit(r.quantityLabel, r.unit)),
            EntityField(l10n.colClient, text: r.clientName ?? '—'),
            EntityField(l10n.colPo, text: r.poNumber, muted: true),
            EntityField(l10n.colSupervisor, text: r.supervisorName ?? '—'),
            EntityField(l10n.colSubmitted, text: formatDate(r.createdAt)),
            if (r.attachments.isNotEmpty)
              EntityField(
                l10n.attachments,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: Text(
                      '${r.attachments.photos.length + (r.attachments.audio != null ? 1 : 0)}',
                    ),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          RequestAttachmentsDialog(attachments: r.attachments),
                    ),
                  ),
                ),
              ),
          ],
          footer: _actions(context, l10n, r, muted),
        );
      },
    );
  }

  Widget _emptyState(AppLocalizations l10n) {
    final (IconData icon, String title, String body) =
        switch (controller.statusFilter.value) {
      'requested' => (Icons.inbox_outlined, l10n.caughtUpTitle, l10n.caughtUpBody),
      null => (Icons.inbox_outlined, l10n.nothingHereTitle, l10n.noRequestsBody),
      'accepted' => (Icons.filter_list_off, l10n.nothingHereTitle, l10n.noAcceptedBody),
      'declined' => (Icons.filter_list_off, l10n.nothingHereTitle, l10n.noDeclinedBody),
      _ => (Icons.filter_list_off, l10n.nothingHereTitle, l10n.noCancelledBody),
    };
    return EmptyState(icon: icon, title: title, body: body);
  }

  Widget _table(BuildContext context, AppLocalizations l10n) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final status = context.statusColors;
    return DcplTable(
      columns: [
        DcplColumn(l10n.colItem, flex: 3),
        DcplColumn(l10n.colQty, fixedWidth: 100),
        DcplColumn(l10n.colClient, flex: 2),
        DcplColumn(l10n.colPo, fixedWidth: 96),
        DcplColumn(l10n.colSupervisor, flex: 2),
        DcplColumn(l10n.colSubmitted, fixedWidth: 96, numeric: true),
        DcplColumn(l10n.colStatus, fixedWidth: 168),
        const DcplColumn('', fixedWidth: 210),
      ],
      rows: [
        for (final r in controller.requests)
          DcplRow(
            railColor: status.forRequest(r.status).ink,
            cells: [
              Row(
                children: [
                  Expanded(child: PrimaryCell(r.particular, subtitle: _itemSubtitle(r))),
                  if (r.attachments.isNotEmpty) _attachmentButton(context, l10n, r),
                ],
              ),
              Text(l10n.qtyWithUnit(r.quantityLabel, r.unit)),
              Text(r.clientName ?? '—'),
              Text(r.poNumber, style: TextStyle(color: muted)),
              Text(r.supervisorName ?? '—'),
              Text(formatDate(r.createdAt)),
              RequestStatusChip(r.status),
              _actions(context, l10n, r, muted),
            ],
          ),
      ],
    );
  }

  Widget _actions(
    BuildContext context,
    AppLocalizations l10n,
    MaterialRequest r,
    Color muted,
  ) {
    if (!r.isPending) {
      final text = switch (r.status) {
        'accepted' => (r.vendor != null && r.vendor!.isNotEmpty)
            ? l10n.vendorArrow(r.vendor!)
            : l10n.segAccepted,
        'declined' => l10n.declinedShort,
        _ => l10n.withdrawnShort,
      };
      return Text(text, style: TextStyle(color: muted), overflow: TextOverflow.ellipsis);
    }
    // Compact buttons, right-aligned; FittedBox guarantees they never overflow
    // the fixed actions column on tighter widths.
    const compact = ButtonStyle(
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
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
  }
}
