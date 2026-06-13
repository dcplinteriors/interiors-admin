import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/projects/projects_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _particular = TextEditingController();
  final _client = TextEditingController();
  DateTime _date = DateTime.now();

  bool _submitting = false;
  String? _error;

  ProjectsController get _controller => Get.find<ProjectsController>();

  @override
  void dispose() {
    _particular.dispose();
    _client.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final project = await _controller.create(
        particular: _particular.text.trim(),
        clientName: _client.text.trim(),
        date: DateFormat('yyyy-MM-dd').format(_date),
      );
      if (!mounted) return;
      final message = AppLocalizations.of(context).projectCreated(project.po);
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
    return AlertDialog(
      title: Text(l10n.newProject),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
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
                controller: _particular,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.projectNameLabel),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a project name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _client,
                decoration: InputDecoration(labelText: l10n.clientNameLabel),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a client name' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _submitting ? null : _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.projectDateLabel,
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(formatDate(DateFormat('yyyy-MM-dd').format(_date))),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.createProjectHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
              : Text(l10n.createProject),
        ),
      ],
    );
  }
}

