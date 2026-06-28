import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/material_requests_controller.dart';
import 'package:dcpl_admin/features/vendors/vendors.dart';
import 'package:dcpl_shared/models/models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Step 2 of fulfilment: assign the vendor + delivery details to a `processing` item,
/// moving it to `accepted`. The vendor is picked from the managed list (searchable) — or added
/// inline — instead of typed free-text. Vendor + expected date are required; PO + remarks optional.
class AssignVendorDialog extends StatefulWidget {
  const AssignVendorDialog({super.key, required this.request});

  final MaterialRequest request;

  @override
  State<AssignVendorDialog> createState() => _AssignVendorDialogState();
}

class _AssignVendorDialogState extends State<AssignVendorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _vendorField = TextEditingController();
  final _poNumber = TextEditingController();
  final _remarks = TextEditingController();
  DateTime? _expectedDate;

  List<Vendor> _vendors = [];
  Vendor? _selectedVendor;
  bool _loadingVendors = true;

  bool _submitting = false;
  String? _error;
  bool _dateMissing = false;
  bool _vendorMissing = false;

  MaterialRequestsController get _controller => Get.find<MaterialRequestsController>();

  @override
  void initState() {
    super.initState();
    // DropdownMenu doesn't re-fire onSelected or revert typed text, so a typed-over field can keep
    // a stale selection. Drop the selection when the text no longer matches it, forcing an explicit
    // re-pick — so what's submitted always matches what's shown.
    _vendorField.addListener(_syncVendorSelection);
    _loadVendors();
  }

  void _syncVendorSelection() {
    if (_selectedVendor != null && _vendorField.text.trim() != _selectedVendor!.name) {
      setState(() => _selectedVendor = null);
    }
  }

  @override
  void dispose() {
    _vendorField.removeListener(_syncVendorSelection);
    _vendorField.dispose();
    _poNumber.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    try {
      final all = await Get.find<VendorRepository>().listAll();
      if (!mounted) return;
      // Only active vendors are assignable.
      setState(() {
        _vendors = all.where((v) => v.isActive).toList();
        _loadingVendors = false;
      });
    } on ApiException catch (_) {
      if (mounted) setState(() => _loadingVendors = false);
    }
  }

  /// Add a vendor inline, then select it.
  Future<void> _addVendor() async {
    final created = await showDialog<Vendor>(context: context, builder: (_) => const VendorDialog());
    if (created == null || !mounted) return;
    setState(() {
      _vendors = [..._vendors, created];
      _selectedVendor = created;
      _vendorField.text = created.name;
      _vendorMissing = false;
    });
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
    final vendorOk = _selectedVendor != null;
    if (!dateOk) setState(() => _dateMissing = true);
    if (!vendorOk) setState(() => _vendorMissing = true);
    if (!formOk || !dateOk || !vendorOk) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _controller.assignVendor(
        widget.request.id,
        expectedDate: DateFormat('yyyy-MM-dd').format(_expectedDate!),
        vendorId: _selectedVendor!.id,
        poNumber: _poNumber.text.trim().isEmpty ? null : _poNumber.text.trim(),
        remarks: _remarks.text.trim().isEmpty ? null : _remarks.text.trim(),
      );
      if (!mounted) return;
      final message = AppLocalizations.of(context).vendorAssigned;
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
    final theme = Theme.of(context);
    final r = widget.request;
    final subhead = '${r.particular} · ${l10n.qtyWithUnit(r.quantityLabel, r.unit)} · ${r.clientName ?? 'N/A'}';

    return AlertDialog(
      title: Text(l10n.assignVendorTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(subhead, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 20),
                if (_error != null) ...[ErrorStrip(_error!), const SizedBox(height: 16)],
                // Vendor — the searchable picker (the dialog's primary input), with an inline
                // "add new" for when the supplier isn't in the list yet.
                DropdownMenu<Vendor>(
                  controller: _vendorField,
                  initialSelection: _selectedVendor,
                  enabled: !_loadingVendors && !_submitting,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  expandedInsets: EdgeInsets.zero,
                  // DropdownMenu doesn't inherit the global input theme, so its field would render
                  // unfilled — hand it the theme so it matches the other fields, and give the
                  // popup a solid surface.
                  inputDecorationTheme: theme.inputDecorationTheme,
                  menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surfaceContainerHigh)),
                  label: Text(l10n.vendorLabel),
                  leadingIcon: const Icon(Icons.storefront_outlined, size: 18),
                  hintText: _loadingVendors ? l10n.loading : null,
                  errorText: _vendorMissing ? 'Select a vendor' : null,
                  onSelected: (v) => setState(() {
                    _selectedVendor = v;
                    _vendorMissing = false;
                  }),
                  dropdownMenuEntries: [for (final v in _vendors) DropdownMenuEntry(value: v, label: v.name)],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: (_submitting || _loadingVendors) ? null : _addVendor,
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(l10n.newVendor),
                  ),
                ),
                const SizedBox(height: 16),
                // Expected delivery date.
                InkWell(
                  onTap: _submitting ? null : _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.expectedDateLabel,
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      errorText: _dateMissing ? 'Select an expected date' : null,
                    ),
                    child: Text(_expectedDate == null ? l10n.selectDate : formatDate(DateFormat('yyyy-MM-dd').format(_expectedDate!))),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _poNumber,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.poNumberOptionalLabel),
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
      ),
      actions: [
        TextButton(onPressed: _submitting ? null : () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.assignVendorButton),
        ),
      ],
    );
  }
}
