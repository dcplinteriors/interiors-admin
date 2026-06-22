import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/projects/projects_controller.dart';
import 'package:dcpl_admin/features/projects/widgets/status_chip.dart';
import 'package:dcpl_admin/features/work_orders/widgets/assign_supervisor_dialog.dart';
import 'package:dcpl_admin/features/work_orders/widgets/assignment_chip.dart';
import 'package:dcpl_admin/features/work_orders/widgets/work_order_status_chip.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Project detail: header + meta + the project's work orders. The full project (with work
/// orders) is fetched on open; admin can mark an active project completed here.
class ProjectDetailDialog extends StatefulWidget {
  const ProjectDetailDialog({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectDetailDialog> createState() => _ProjectDetailDialogState();
}

class _ProjectDetailDialogState extends State<ProjectDetailDialog> {
  late Future<Project> _future;
  bool _completing = false;

  ProjectsController get _controller => Get.find<ProjectsController>();

  @override
  void initState() {
    super.initState();
    _future = _controller.detail(widget.projectId);
  }

  /// Re-fetch the project so a just-assigned supervisor shows on its work order.
  void _refresh() =>
      setState(() => _future = _controller.detail(widget.projectId));

  Future<void> _complete(Project project) async {
    setState(() => _completing = true);
    try {
      await _controller.complete(project.id);
      if (!mounted) return;
      final message = AppLocalizations.of(context).projectCompleted;
      Navigator.of(context).pop();
      showAppSnackbar(message);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _completing = false);
        showAppSnackbar(e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      content: SizedBox(
        width: 520,
        child: FutureBuilder<Project>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snap.error is ApiException
                      ? (snap.error as ApiException).message
                      : l10n.couldntLoadProjects,
                ),
              );
            }
            final project = snap.data!;
            return _DetailContent(
              project: project,
              completing: _completing,
              onComplete: () => _complete(project),
              onAssigned: _refresh,
            );
          },
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.project,
    required this.completing,
    required this.onComplete,
    required this.onAssigned,
  });

  final Project project;
  final bool completing;
  final VoidCallback onComplete;
  final VoidCallback onAssigned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                project.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StatusChip(project.status),
        const SizedBox(height: 20),
        _DetailRow(label: l10n.colNumber, value: project.number),
        _DetailRow(label: l10n.colClient, value: project.clientName),
        _DetailRow(label: l10n.colEngineer, value: project.projectEngineer),
        const SizedBox(height: 20),
        Text(
          l10n.workOrdersSection,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (project.workOrders.isEmpty)
          Text(
            l10n.noWorkOrdersYet,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: project.workOrders.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) =>
                  _WorkOrderTile(project.workOrders[i], onAssigned: onAssigned),
            ),
          ),
        if (project.status == ProjectStatus.active) ...[
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: completing ? null : onComplete,
              icon: completing
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: Text(l10n.completeProject),
            ),
          ),
        ],
      ],
    );
  }
}

class _WorkOrderTile extends StatelessWidget {
  const _WorkOrderTile(this.workOrder, {required this.onAssigned});

  final WorkOrder workOrder;

  /// Called after a supervisor is (re)assigned, so the parent re-fetches the project.
  final VoidCallback onAssigned;

  /// A supervisor can be (re)assigned only while the work order is still open.
  bool get _assignable =>
      workOrder.status == WorkOrderStatus.pending ||
      workOrder.status == WorkOrderStatus.active;

  Future<void> _openAssign(BuildContext context) async {
    final assigned = await showDialog<bool>(
      context: context,
      builder: (_) => AssignSupervisorDialog(workOrder: workOrder),
    );
    if (assigned == true) onAssigned();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final chip = AssignmentChip(
      name: workOrder.isAssigned ? workOrder.supervisorName : null,
      onTap: _assignable ? () => _openAssign(context) : null,
    );
    // A plain Row (not ListTile): ListTile clamps its `trailing` to the tile height,
    // which clips the stacked status + assignment chips.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(workOrder.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${workOrder.number} · ${formatDate(workOrder.date)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              WorkOrderStatusChip(workOrder.status),
              const SizedBox(height: 4),
              if (_assignable)
                Tooltip(
                  message: workOrder.isAssigned
                      ? l10n.changeSupervisor
                      : l10n.assign,
                  child: chip,
                )
              else
                chip,
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
