import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/material_requests_controller.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Admin correction of a supervisor's item entry — description, make, size, quantity, unit.
/// The backend only allows this before a vendor is assigned (requested / processing); the caller
/// gates the entry point. Pops with the updated [MaterialRequest] on success.
class EditRequestDialog extends StatefulWidget {
  const EditRequestDialog({super.key, required this.request});

  final MaterialRequest request;

  @override
  State<EditRequestDialog> createState() => _EditRequestDialogState();
}

class _EditRequestDialogState extends State<EditRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _particular;
  late final TextEditingController _make;
  late final TextEditingController _size;
  late final TextEditingController _quantity;
  late String _unit;

  bool _submitting = false;
  String? _error;

  MaterialRequestsController get _controller =>
      Get.find<MaterialRequestsController>();

  @override
  void initState() {
    super.initState();
    final r = widget.request;
    _particular = TextEditingController(text: r.particular);
    _make = TextEditingController(text: r.make);
    _size = TextEditingController(text: r.size);
    _quantity = TextEditingController(text: r.quantityLabel);
    _unit = r.unit;
  }

  @override
  void dispose() {
    _particular.dispose();
    _make.dispose();
    _size.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final updated = await _controller.editItem(
        widget.request.id,
        particular: _particular.text.trim(),
        make: _make.text.trim(),
        size: _size.text.trim(),
        quantity: num.parse(_quantity.text.trim()),
        unit: _unit,
      );
      if (!mounted) return;
      final message = AppLocalizations.of(context).itemUpdated;
      Navigator.of(context).pop(updated);
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
    return AlertDialog(
      title: Text(l10n.editItemTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.editItemHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  ErrorStrip(_error!),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _particular,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.descriptionLabel),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _make,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.colMake),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _size,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.colSize),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantity,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: InputDecoration(labelText: l10n.colQty),
                        validator: (v) {
                          final n = num.tryParse((v ?? '').trim());
                          return (n == null || n <= 0) ? 'Enter a quantity' : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _unit,
                        decoration: InputDecoration(labelText: l10n.unitLabel),
                        items: [
                          for (final u in MaterialUnits.all)
                            DropdownMenuItem(value: u, child: Text(u)),
                        ],
                        onChanged: _submitting
                            ? null
                            : (v) => setState(() => _unit = v ?? _unit),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
              : Text(l10n.editItemButton),
        ),
      ],
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}
