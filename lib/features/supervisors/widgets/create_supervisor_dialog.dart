import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/supervisors/supervisors_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateSupervisorDialog extends StatefulWidget {
  const CreateSupervisorDialog({super.key});

  @override
  State<CreateSupervisorDialog> createState() => _CreateSupervisorDialogState();
}

class _CreateSupervisorDialogState extends State<CreateSupervisorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  bool _submitting = false;
  String? _error;
  // The email the backend rejected as already-in-use; drives the field-level error.
  String? _takenEmail;

  SupervisorsController get _controller => Get.find<SupervisorsController>();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter an email address';
    // Pragmatic check — the backend is the source of truth for validity.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    final l10n = AppLocalizations.of(context);
    if (_takenEmail != null && email.toLowerCase() == _takenEmail) {
      return l10n.emailInUseShort;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final email = _email.text.trim().toLowerCase();
    try {
      await _controller.create(
        name: _name.text.trim(),
        email: email,
        phone: _phone.text.trim(),
      );
      if (!mounted) return;
      final message = AppLocalizations.of(context).inviteSent(email);
      Navigator.of(context).pop();
      showAppSnackbar(message);
    } on ApiException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      if (e.statusCode == 409) {
        // Pin the offending email so the field re-validates into an error state.
        setState(() {
          _takenEmail = email;
          _error = l10n.emailAlreadyInUse;
        });
        _formKey.currentState!.validate();
      } else {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn\'t send the invite. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                l10n.supervisorInviteHint,
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
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.emailLabel,
                  helperText: l10n.emailInviteHelper,
                ),
                validator: _validateEmail,
                // Clear the stale "already in use" error once the email is edited.
                onChanged: (_) {
                  if (_takenEmail != null) setState(() => _takenEmail = null);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.phoneOptionalLabel),
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
              : Text(l10n.sendInvite),
        ),
      ],
    );
  }
}

