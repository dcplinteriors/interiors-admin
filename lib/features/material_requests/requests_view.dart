import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/material_requests_controller.dart';
import 'package:dcpl_admin/features/material_requests/widgets/accept_request_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/decline_request_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/request_attachments_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/request_status_chip.dart';
import 'package:dcpl_shared/models/material_request.dart';
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
          Row(
            children: [
              // Title + count share a flexible slot so the title can ellipsize
              // on narrow widths; the actions then sit flush-right (no Spacer to
              // fight over slack, so no stray gap).
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.materialRequestsTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Obx(
                      () => Text(
                        _countLabel(l10n),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Obx(() => RefreshButton(
                    tooltip: l10n.refresh,
                    onPressed: controller.fetch,
                    isRefreshing:
                        controller.isLoading.value && controller.requests.isNotEmpty,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() => _filter(l10n)),
          const SizedBox(height: 16),
          Expanded(child: Obx(() => _body(context, l10n))),
          Obx(() => _loadMoreBar(l10n)),
        ],
      ),
    );
  }

  /// Footer shown only when more pages are available — a "Load more" button (or a spinner
  /// while the next page loads).
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
    // Five segments overflow a phone; let them scroll horizontally there.
    scrollDirection: Axis.horizontal,
    child: SegmentedButton<String?>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(value: null, label: Text(l10n.segAll)),
        ButtonSegment(value: 'requested', label: Text(l10n.segToReview)),
        ButtonSegment(value: 'accepted', label: Text(l10n.segAccepted)),
        ButtonSegment(value: 'declined', label: Text(l10n.segDeclined)),
        ButtonSegment(value: 'cancelled', label: Text(l10n.segCancelled)),
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

  Widget _cards(BuildContext context, AppLocalizations l10n) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: controller.requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = controller.requests[i];
        return EntityCard(
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
    final (IconData icon, String title, String body) = switch (controller.statusFilter.value) {
      // Review queue empty = the happy path; phrase it positively.
      'requested' => (Icons.inbox_outlined, l10n.caughtUpTitle, l10n.caughtUpBody),
      // "All" empty = there are genuinely no requests yet (neutral, not a filtered-out look).
      null => (Icons.inbox_outlined, l10n.nothingHereTitle, l10n.noRequestsBody),
      // A specific status filter matched nothing.
      'accepted' => (Icons.filter_list_off, l10n.nothingHereTitle, l10n.noAcceptedBody),
      'declined' => (Icons.filter_list_off, l10n.nothingHereTitle, l10n.noDeclinedBody),
      _ => (Icons.filter_list_off, l10n.nothingHereTitle, l10n.noCancelledBody),
    };
    return EmptyState(icon: icon, title: title, body: body);
  }

  Widget _table(BuildContext context, AppLocalizations l10n) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) => ScrollableTable(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: DataTable(
            columnSpacing: 24,
            columns: [
              DataColumn(label: Text(l10n.colItem)),
              DataColumn(label: Text(l10n.colMake)),
              DataColumn(label: Text(l10n.colSize)),
              DataColumn(label: Text(l10n.colQty)),
              DataColumn(label: Text(l10n.colClient)),
              DataColumn(label: Text(l10n.colPo)),
              DataColumn(label: Text(l10n.colSupervisor)),
              DataColumn(label: Text(l10n.colSubmitted)),
              DataColumn(label: Text(l10n.colStatus)),
              const DataColumn(label: Text('')),
            ],
            rows: [
              for (final r in controller.requests)
                DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (r.attachments.isNotEmpty)
                            IconButton(
                              tooltip: l10n.attachments,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.attach_file, size: 18),
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => RequestAttachmentsDialog(
                                  attachments: r.attachments,
                                ),
                              ),
                            ),
                          _capped(
                            r.particular,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    DataCell(_capped(r.make, style: TextStyle(color: muted))),
                    DataCell(Text(r.size.isEmpty ? '—' : r.size)),
                    DataCell(Text(l10n.qtyWithUnit(r.quantityLabel, r.unit))),
                    DataCell(Text(r.clientName ?? '—')),
                    DataCell(Text(r.poNumber, style: TextStyle(color: muted))),
                    DataCell(Text(r.supervisorName ?? '—')),
                    DataCell(Text(formatDate(r.createdAt))),
                    DataCell(RequestStatusChip(r.status)),
                    DataCell(_actions(context, l10n, r, muted)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _capped(String text, {TextStyle? style}) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 220),
    child: Text(text, style: style, overflow: TextOverflow.ellipsis),
  );

  Widget _actions(
    BuildContext context,
    AppLocalizations l10n,
    MaterialRequest r,
    Color muted,
  ) {
    if (!r.isPending) {
      final text = switch (r.status) {
        'accepted' =>
          (r.vendor != null && r.vendor!.isNotEmpty)
              ? l10n.vendorArrow(r.vendor!)
              : l10n.segAccepted,
        'declined' => l10n.declinedShort,
        _ => l10n.withdrawnShort,
      };
      return Text(text, style: TextStyle(color: muted));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => DeclineRequestDialog(request: r),
          ),
          child: Text(l10n.decline),
        ),
        const SizedBox(width: 8),
        FilledButton.tonal(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => AcceptRequestDialog(request: r),
          ),
          child: Text(l10n.accept),
        ),
      ],
    );
  }
}
