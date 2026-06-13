import 'package:dcpl_admin/l10n/app_localizations.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter/material.dart';

/// Shows the assigned supervisor's name, or a prominent "Unassigned" indicator
/// (the action-needed state that drives the admin's workflow). Unassigned reads
/// as a warning (needs attention), not an error.
class AssignmentChip extends StatelessWidget {
  const AssignmentChip({super.key, required this.name});

  /// Supervisor name, or null/empty when unassigned.
  final String? name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final assigned = name != null && name!.isNotEmpty;

    if (assigned) {
      return Chip(
        avatar: const Icon(Icons.person_outline, size: 16),
        label: Text(name!),
        backgroundColor: Colors.transparent,
        side: BorderSide(color: scheme.outlineVariant),
        visualDensity: VisualDensity.compact,
      );
    }

    final warn = context.statusColors.warning;
    return Chip(
      avatar: Icon(Icons.person_off_outlined, size: 16, color: warn.ink),
      label: Text(l10n.unassigned, style: TextStyle(color: warn.ink)),
      backgroundColor: warn.surface,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
