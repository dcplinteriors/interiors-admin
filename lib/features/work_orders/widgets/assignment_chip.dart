import 'package:dcpl_admin/l10n/app_localizations.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter/material.dart';

/// Shows the assigned supervisor's name, or a prominent "Unassigned" indicator
/// (the action-needed state that drives the admin's workflow). Unassigned reads
/// as a warning (needs attention), not an error.
///
/// When [onTap] is provided the chip becomes an actionable button — rendered as an
/// [ActionChip] (with press/hover feedback) plus a trailing edit affordance — so it
/// reads as tappable rather than as a passive status chip.
class AssignmentChip extends StatelessWidget {
  const AssignmentChip({super.key, required this.name, this.onTap});

  /// Supervisor name, or null/empty when unassigned.
  final String? name;

  /// Tap handler to (re)assign. Null ⇒ a passive status chip.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final assigned = name != null && name!.isNotEmpty;
    final warn = context.statusColors.warning;

    // Shared styling for both the passive and actionable variants.
    final fg = assigned ? null : warn.ink;
    final avatar = Icon(
      assigned ? Icons.person_outline : Icons.person_off_outlined,
      size: 16,
      color: fg,
    );
    final background = assigned ? Colors.transparent : warn.surface;
    final side = assigned
        ? BorderSide(color: scheme.outlineVariant)
        : BorderSide.none;
    final text = assigned ? name! : l10n.unassigned;

    if (onTap == null) {
      return Chip(
        avatar: avatar,
        label: Text(text, style: TextStyle(color: fg)),
        backgroundColor: background,
        side: side,
        visualDensity: VisualDensity.compact,
      );
    }

    // Actionable: ActionChip gives real press/hover/cursor feedback; the trailing
    // pencil signals it's editable.
    return ActionChip(
      onPressed: onTap,
      avatar: avatar,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: TextStyle(color: fg)),
          const SizedBox(width: 6),
          Icon(
            Icons.edit_outlined,
            size: 13,
            color: fg ?? scheme.onSurfaceVariant,
          ),
        ],
      ),
      backgroundColor: background,
      side: side,
      visualDensity: VisualDensity.compact,
    );
  }
}
