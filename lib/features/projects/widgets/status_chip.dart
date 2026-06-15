import 'package:dcpl_admin/l10n/app_localizations.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isActive = status == 'active';
    final colors = context.statusColors.forProject(status);
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
