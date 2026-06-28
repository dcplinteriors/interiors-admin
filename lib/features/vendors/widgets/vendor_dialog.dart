import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/vendors/vendors_controller.dart';
import 'package:dcpl_shared/models/models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Add or edit a vendor. [vendor] null = create. Pops with the created/updated [Vendor] so callers
/// (e.g. the assign-vendor dialog's "add new") can pick it up; other callers ignore the result.
/// Only the name is collected — the backend supports phone/email but the client doesn't ask yet.
class VendorDialog extends StatefulWidget {
  const VendorDialog({super.key, this.vendor});

  final Vendor? vendor;

  @override
  State<VendorDialog> createState() => _VendorDialogState();
}

class _VendorDialogState extends State<VendorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.vendor?.name ?? '',
  );

  bool _submitting = false;
  String? _error;

  bool get _isEdit => widget.vendor != null;

  VendorsController get _controller => Get.find<VendorsController>();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final name = _name.text.trim();
    try {
      final l10n = AppLocalizations.of(context);
      final Vendor result;
      final String message;
      if (_isEdit) {
        result = await _controller.edit(widget.vendor!.id, name: name);
        message = l10n.vendorUpdated;
      } else {
        result = await _controller.create(name: name);
        message = l10n.vendorAdded;
      }
      if (!mounted) return;
      Navigator.of(context).pop(result);
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
    return AlertDialog(
      title: Text(_isEdit ? l10n.editVendor : l10n.newVendor),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                ErrorStrip(_error!),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _name,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submitting ? null : _submit(),
                decoration: InputDecoration(labelText: l10n.vendorNameLabel),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
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
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEdit ? l10n.save : l10n.add),
        ),
      ],
    );
  }
}
