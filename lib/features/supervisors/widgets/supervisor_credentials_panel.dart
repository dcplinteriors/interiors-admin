import 'package:dcpl_admin/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One-time display of a supervisor's sign-in credentials (their phone + a temporary
/// password). Shown after creating a supervisor or resetting their password — the
/// password is never retrievable again, so the admin must copy/hand it over now.
///
/// A single button copies both as a labelled pair (ready to paste into a message).
/// Embedded in the create dialog and in [showSupervisorCredentialsDialog].
class SupervisorCredentialsPanel extends StatelessWidget {
  const SupervisorCredentialsPanel({
    super.key,
    required this.phone,
    required this.tempPassword,
  });

  final String phone;
  final String tempPassword;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final phoneText = formatPhone(phone);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: scheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.credentialsWarning,
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _CredentialField(label: l10n.phoneLabel, value: phoneText),
        const SizedBox(height: 12),
        _CredentialField(label: l10n.tempPasswordLabel, value: tempPassword),
        const SizedBox(height: 16),
        // One button copies both, labelled, as a ready-to-share pair.
        FilledButton.tonalIcon(
          onPressed: () async {
            final text =
                '${l10n.phoneLabel}: $phoneText\n${l10n.tempPasswordLabel}: $tempPassword';
            await Clipboard.setData(ClipboardData(text: text));
            showAppSnackbar(l10n.copiedToClipboard);
          },
          icon: const Icon(Icons.copy_outlined, size: 18),
          label: Text(l10n.copyCredentials),
        ),
      ],
    );
  }
}

/// A read-only labelled value (phone or password). Copying is handled by the panel's
/// single "copy both" button, so there's no per-field action here.
class _CredentialField extends StatelessWidget {
  const _CredentialField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the one-time [SupervisorCredentialsPanel] in its own dialog — used by the
/// reset-password flow (the create flow embeds the panel in its own dialog instead).
Future<void> showSupervisorCredentialsDialog(
  BuildContext context, {
  required String title,
  required String phone,
  required String tempPassword,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    // Pop via the dialog's own context — the outer page context resolves to go_router's shell
    // navigator and would tear the page off the stack instead of closing the dialog.
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SupervisorCredentialsPanel(
          phone: phone,
          tempPassword: tempPassword,
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.done),
        ),
      ],
    ),
  );
}
