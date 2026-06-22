import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/material_requests_controller.dart';
import 'package:dcpl_shared/models/models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 1 of fulfilment: approve a `requested` item into `processing` (admin has accepted it
/// but not yet assigned a vendor). Optional remarks only — vendor details come at step 2.
class AcceptRequestDialog extends StatefulWidget {
  const AcceptRequestDialog({super.key, required this.request});

  final MaterialRequest request;

  @override
  State<AcceptRequestDialog> createState() => _AcceptRequestDialogState();
}

class _AcceptRequestDialogState extends State<AcceptRequestDialog> {
  final _remarks = TextEditingController();

  bool _submitting = false;
  String? _error;

  MaterialRequestsController get _controller =>
      Get.find<MaterialRequestsController>();

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _controller.acceptToProcessing(
        widget.request.id,
        remarks: _remarks.text.trim().isEmpty ? null : _remarks.text.trim(),
      );
      if (!mounted) return;
      final message = AppLocalizations.of(context).requestAccepted;
      Navigator.of(context).pop();
      showAppSnackbar(message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final r = widget.request;
    final subhead =
        '${r.particular} · ${l10n.qtyWithUnit(r.quantityLabel, r.unit)} · ${r.clientName ?? '—'}';

    return AlertDialog(
      title: Text(l10n.acceptRequestTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              subhead,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.acceptToProcessingBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              ErrorStrip(_error!),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _remarks,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.remarksOptionalLabel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.acceptRequestButton),
        ),
      ],
    );
  }
}
