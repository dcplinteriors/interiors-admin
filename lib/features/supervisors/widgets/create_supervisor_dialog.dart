import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/supervisors/data/data.dart';
import 'package:dcpl_admin/features/supervisors/supervisors_controller.dart';
import 'package:dcpl_admin/features/supervisors/widgets/supervisor_credentials_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Creates a supervisor from a name + 10-digit phone. On success it doesn't just
/// close: it swaps to a one-time credentials panel showing the phone and the
/// generated temporary password (which is never shown again). Closing that panel
/// pops the created [Supervisor] so callers (e.g. the assign dialog) can pre-select it.
class CreateSupervisorDialog extends StatefulWidget {
  const CreateSupervisorDialog({super.key});

  @override
  State<CreateSupervisorDialog> createState() => _CreateSupervisorDialogState();
}

class _CreateSupervisorDialogState extends State<CreateSupervisorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  bool _submitting = false;
  String? _error;

  // Set once the supervisor is created; switches the dialog to the credentials panel.
  CreatedSupervisorResult? _created;

  SupervisorsController get _controller => Get.find<SupervisorsController>();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').trim();
    if (digits.isEmpty) return 'Enter a phone number';
    if (!RegExp(r'^\d{10}$').hasMatch(digits)) {
      return 'Enter a 10-digit phone number';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final created = await _controller.create(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
      );
      if (!mounted) return;
      setState(() => _created = created);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Couldn\'t create the supervisor. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final created = _created;
    if (created != null) {
      return AlertDialog(
        title: Text(l10n.supervisorCreatedTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SupervisorCredentialsPanel(
            phone: _phone.text.trim(),
            tempPassword: created.tempPassword,
          ),
        ),
        actions: [
          FilledButton(
            // Return the created supervisor so callers (e.g. the assign dialog) can
            // refresh and pre-select it; other callers simply ignore the result.
            onPressed: () => Navigator.of(context).pop(created.supervisor),
            child: Text(l10n.done),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(l10n.newSupervisor),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.createSupervisorHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                ErrorStrip(_error!),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _name,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.nameLabel),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: l10n.phoneNumberLabel,
                  helperText: l10n.phoneNumberHelper,
                ),
                validator: _validatePhone,
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
              : Text(l10n.createSupervisorAction),
        ),
      ],
    );
  }
}
