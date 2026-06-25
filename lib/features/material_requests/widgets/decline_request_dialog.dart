import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/material_requests_controller.dart';
import 'package:dcpl_shared/models/models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeclineRequestDialog extends StatefulWidget {
  const DeclineRequestDialog({super.key, required this.request});

  final MaterialRequest request;

  @override
  State<DeclineRequestDialog> createState() => _DeclineRequestDialogState();
}

class _DeclineRequestDialogState extends State<DeclineRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  bool _submitting = false;
  String? _error;

  MaterialRequestsController get _controller =>
      Get.find<MaterialRequestsController>();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _controller.decline(widget.request.id, _reason.text.trim());
      if (!mounted) return;
      final message = AppLocalizations.of(context).requestDeclined;
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

    return AlertDialog(
      title: Text(l10n.declineRequestTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${r.particular} · ${r.clientName ?? 'N/A'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.declineConfirmBody,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                ErrorStrip(_error!),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _reason,
                autofocus: true,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.reasonLabel,
                  helperText: l10n.declineReasonHelper,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a reason' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.declineButton),
        ),
      ],
    );
  }
}
