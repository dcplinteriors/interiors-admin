import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/material_requests_controller.dart';
import 'package:dcpl_shared/models/material_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AcceptRequestDialog extends StatefulWidget {
  const AcceptRequestDialog({super.key, required this.request});

  final MaterialRequest request;

  @override
  State<AcceptRequestDialog> createState() => _AcceptRequestDialogState();
}

class _AcceptRequestDialogState extends State<AcceptRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _vendor = TextEditingController();
  final _remarks = TextEditingController();
  DateTime? _expectedDate;

  bool _submitting = false;
  String? _error;
  bool _dateMissing = false;

  MaterialRequestsController get _controller => Get.find<MaterialRequestsController>();

  @override
  void dispose() {
    _vendor.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _expectedDate = picked;
        _dateMissing = false;
      });
    }
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    final dateOk = _expectedDate != null;
    if (!dateOk) setState(() => _dateMissing = true);
    if (!formOk || !dateOk) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _controller.accept(
        widget.request.id,
        expectedDate: DateFormat('yyyy-MM-dd').format(_expectedDate!),
        vendor: _vendor.text.trim(),
        remarks: _remarks.text.trim(),
      );
      if (!mounted) return;
      final message = AppLocalizations.of(context).requestAccepted;
      Navigator.of(context).pop();
      showAppSnackbar(message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = widget.request;
    final subhead = '${r.particular} · ${l10n.qtyWithUnit(r.quantityLabel, r.unit)} · '
        '${r.clientName ?? '—'}';

    return AlertDialog(
      title: Text(l10n.acceptRequestTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                subhead,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                ErrorStrip(_error!),
                const SizedBox(height: 16),
              ],
              InkWell(
                onTap: _submitting ? null : _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.expectedDateLabel,
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                    errorText: _dateMissing ? 'Select an expected date' : null,
                  ),
                  child: Text(
                    _expectedDate == null
                        ? l10n.selectDate
                        : formatDate(DateFormat('yyyy-MM-dd').format(_expectedDate!)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vendor,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.vendorLabel),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a vendor' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarks,
                maxLines: 3,
                decoration: InputDecoration(labelText: l10n.remarksOptionalLabel),
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
                  height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.acceptRequestButton),
        ),
      ],
    );
  }
}

