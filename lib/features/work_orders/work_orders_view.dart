import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/work_orders/widgets/add_work_order_dialog.dart';
import 'package:dcpl_admin/features/work_orders/widgets/assign_supervisor_dialog.dart';
import 'package:dcpl_admin/features/work_orders/widgets/assignment_chip.dart';
import 'package:dcpl_admin/features/work_orders/widgets/work_order_status_chip.dart';
import 'package:dcpl_admin/features/work_orders/work_orders_controller.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WorkOrdersView extends GetView<WorkOrdersController> {
  const WorkOrdersView({super.key});

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

class _Header extends GetView<WorkOrdersController> {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Obx(
      () => PageHeader(
        title: l10n.navWorkOrders,
        count: '${controller.workOrders.length}',
        actions: [
          RefreshButton(
            tooltip: l10n.refresh,
            onPressed: controller.fetch,
            isRefreshing:
                controller.isLoading.value && controller.workOrders.isNotEmpty,
          ),
          const _CreateAction(),
        ],
      ),
    );
  }
}

class _CreateAction extends GetView<WorkOrdersController> {
  const _CreateAction();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void open() => showDialog<void>(
      context: context,
      builder: (_) =>
          AddWorkOrderDialog(initialProjectId: controller.projectFilter.value),
    );
    return context.isCompact
        ? IconButton.filled(
            tooltip: l10n.newWorkOrder,
            onPressed: open,
            icon: const Icon(Icons.add),
          )
        : GradientButton(
            onPressed: open,
            icon: Icons.add,
            label: l10n.newWorkOrder,
          );
  }
}

class _Filters extends GetView<WorkOrdersController> {
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
          FilterDropdown<String?>(
            value: controller.projectFilter.value,
            onChanged: controller.setProjectFilter,
            options: [
              FilterOption(null, l10n.allProjects),
              for (final p in controller.projects) FilterOption(p.id, p.name),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<WorkOrderStatus?>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: null,
                  label: Text(l10n.segAll, softWrap: false, maxLines: 1),
                ),
                ButtonSegment(
                  value: WorkOrderStatus.pending,
                  label: Text(l10n.woPending, softWrap: false, maxLines: 1),
                ),
                ButtonSegment(
                  value: WorkOrderStatus.active,
                  label: Text(l10n.woActive, softWrap: false, maxLines: 1),
                ),
                ButtonSegment(
                  value: WorkOrderStatus.completed,
                  label: Text(l10n.completed, softWrap: false, maxLines: 1),
                ),
                ButtonSegment(
                  value: WorkOrderStatus.cancelled,
                  label: Text(l10n.woCancelled, softWrap: false, maxLines: 1),
                ),
              ],
              selected: {controller.statusFilter.value},
              onSelectionChanged: (s) => controller.setStatusFilter(s.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends GetView<WorkOrdersController> {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Obx(() {
      if (controller.isLoading.value && controller.workOrders.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value != null) {
        return ErrorState(
          title: l10n.couldntLoadWorkOrders,
          message: controller.error.value!,
          onRetry: controller.fetch,
        );
      }
      if (controller.workOrders.isEmpty) {
        return EmptyState(
          icon: Icons.assignment_outlined,
          title: l10n.noWorkOrdersTitle,
          body: l10n.noWorkOrdersBody,
        );
      }
      return context.isCompact
          ? _Cards(controller.workOrders.toList())
          : _Table(controller.workOrders.toList());
    });
  }
}

class _Cards extends StatelessWidget {
  const _Cards(this.workOrders);

  final List<WorkOrder> workOrders;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = context.statusColors;
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: workOrders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final w = workOrders[i];
        return EntityCard(
          eyebrow: l10n.navWorkOrders,
          railColor: status.forWorkOrder(w.status.wire).ink,
          title: w.name,
          trailing: WorkOrderStatusChip(w.status),
          fields: [
            EntityField(l10n.colNumber, text: w.number, muted: true),
            EntityField(l10n.colProject, text: w.projectName ?? '—'),
            EntityField(l10n.colClient, text: w.clientName ?? '—'),
            EntityField(l10n.colDate, text: formatDate(w.date)),
            EntityField(
              l10n.colSupervisor,
              child: AssignmentChip(
                name: w.isAssigned ? w.supervisorName : null,
              ),
            ),
          ],
          footer: _RowActions(w),
        );
      },
    );
  }
}

class _Table extends StatelessWidget {
  const _Table(this.workOrders);

  final List<WorkOrder> workOrders;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = context.statusColors;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return DcplTable(
      columns: [
        DcplColumn(l10n.navWorkOrders, flex: 3),
        DcplColumn(l10n.colNumber, fixedWidth: 132),
        DcplColumn(l10n.colProject, flex: 2),
        DcplColumn(l10n.colDate, fixedWidth: 96, numeric: true),
        DcplColumn(l10n.colSupervisor, flex: 2),
        DcplColumn(l10n.colStatus, fixedWidth: 150),
        const DcplColumn('', fixedWidth: 200),
      ],
      rows: [
        for (final w in workOrders)
          DcplRow(
            railColor: status.forWorkOrder(w.status.wire).ink,
            cells: [
              PrimaryCell(w.name),
              Text(w.number, style: TextStyle(color: muted)),
              Text(w.projectName ?? '—'),
              Text(formatDate(w.date)),
              AssignmentChip(name: w.isAssigned ? w.supervisorName : null),
              WorkOrderStatusChip(w.status),
              _RowActions(w),
            ],
          ),
      ],
    );
  }
}

enum _WoAction { change, unassign }

/// Status-gated actions for a work-order row.
class _RowActions extends GetView<WorkOrdersController> {
  const _RowActions(this.workOrder);

  final WorkOrder workOrder;

  void _openAssign(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => AssignSupervisorDialog(workOrder: workOrder),
  );

  Future<void> _confirmAndRun(
    BuildContext context,
    AppLocalizations l10n, {
    required String title,
    required String body,
    required String confirmLabel,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await action();
      showAppSnackbar(successMessage);
    } on ApiException catch (e) {
      showAppSnackbar(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const compact = ButtonStyle(
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final w = workOrder;

    final children = <Widget>[];
    switch (w.status) {
      case WorkOrderStatus.pending:
        children.addAll([
          TextButton(
            style: compact,
            onPressed: () => _confirmAndRun(
              context,
              l10n,
              title: l10n.cancelWorkOrderTitle,
              body: l10n.cancelWorkOrderBody,
              confirmLabel: l10n.cancelWorkOrder,
              action: () => controller.cancel(w.id),
              successMessage: l10n.workOrderCancelled,
            ),
            child: Text(l10n.cancelWorkOrder),
          ),
          const SizedBox(width: 6),
          FilledButton.tonal(
            style: compact,
            onPressed: () => _openAssign(context),
            child: Text(l10n.assign),
          ),
        ]);
      case WorkOrderStatus.active:
        children.addAll([
          FilledButton.tonal(
            style: compact,
            onPressed: () => _confirmAndRun(
              context,
              l10n,
              title: l10n.completeWorkOrderTitle,
              body: l10n.completeWorkOrderBody,
              confirmLabel: l10n.markComplete,
              action: () => controller.complete(w.id),
              successMessage: l10n.workOrderCompleted,
            ),
            child: Text(l10n.markComplete),
          ),
          PopupMenuButton<_WoAction>(
            tooltip: '',
            onSelected: (a) => switch (a) {
              _WoAction.change => _openAssign(context),
              _WoAction.unassign => _confirmAndRun(
                context,
                l10n,
                title: l10n.unassignTitle,
                body: l10n.unassignBody,
                confirmLabel: l10n.unassign,
                action: () => controller.unassign(w.id),
                successMessage: l10n.workOrderUnassigned,
              ),
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _WoAction.change,
                child: Text(l10n.changeSupervisor),
              ),
              PopupMenuItem(
                value: _WoAction.unassign,
                child: Text(l10n.unassign),
              ),
            ],
          ),
        ]);
      case WorkOrderStatus.completed:
      case WorkOrderStatus.cancelled:
        return Text('—', style: TextStyle(color: muted));
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
