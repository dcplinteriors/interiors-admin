import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter/material.dart';

/// A coloured chip for the four work-order statuses (pending / active / completed / cancelled).
/// Colours come from the shared semantic palette ([StatusColors.forWorkOrder]).
class WorkOrderStatusChip extends StatelessWidget {
  const WorkOrderStatusChip(this.status, {super.key});

  final WorkOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.statusColors.forWorkOrder(status.wire);

    final (IconData icon, String label) = switch (status) {
      WorkOrderStatus.pending => (Icons.schedule, l10n.woPending),
      WorkOrderStatus.active => (Icons.bolt, l10n.woActive),
      WorkOrderStatus.completed => (Icons.check_circle_outline, l10n.completed),
      WorkOrderStatus.cancelled => (Icons.block_outlined, l10n.woCancelled),
    };

    return Chip(
      avatar: Icon(icon, size: 16, color: colors.ink),
      label: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: TextStyle(color: colors.ink),
      ),
      backgroundColor: colors.surface,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
