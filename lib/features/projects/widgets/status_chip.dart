import 'package:dcpl_admin/l10n/app_localizations.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter/material.dart';

/// A coloured chip for a project's status (active / completed). Colours come from the
/// shared semantic palette ([StatusColors]); only icon + label are decided here.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isActive = status == ProjectStatus.active;
    final colors = context.statusColors.forProject(status.wire);
    return Chip(
      avatar: Icon(
        isActive ? Icons.bolt : Icons.check_circle_outline,
        size: 16,
        color: colors.ink,
      ),
      label: Text(
        isActive ? l10n.active : l10n.completed,
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
