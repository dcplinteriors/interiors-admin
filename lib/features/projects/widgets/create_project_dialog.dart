import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/projects/projects_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Creates a project together with its initial work orders (at least one). Each work-order
/// row carries a name, a date, and an optional description.
class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _client = TextEditingController();
  final _engineer = TextEditingController();
  final _rows = <_WoRow>[_WoRow()];

  bool _submitting = false;
  String? _error;

  ProjectsController get _controller => Get.find<ProjectsController>();

  @override
  void dispose() {
    _name.dispose();
    _client.dispose();
    _engineer.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _addRow() => setState(() => _rows.add(_WoRow()));

  void _removeRow(int i) => setState(() => _rows.removeAt(i).dispose());

  Future<void> _pickDate(_WoRow row) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: row.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => row.date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final project = await _controller.create(
        name: _name.text.trim(),
        clientName: _client.text.trim(),
        projectEngineer: _engineer.text.trim(),
        workOrders: [
          for (final r in _rows)
            WorkOrderInput(
              name: r.name.text.trim(),
              date: fmt.format(r.date),
              description: r.description.text.trim().isEmpty
                  ? null
                  : r.description.text.trim(),
            ),
        ],
      );
      if (!mounted) return;
      final message = AppLocalizations.of(
        context,
      ).projectCreated(project.number);
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
    return AlertDialog(
      title: Text(l10n.newProject),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
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
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.projectNameLabel),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter a project name'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _client,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.clientNameLabel),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter a client name'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _engineer,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.projectEngineerLabel,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter a project engineer'
                      : null,
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.workOrdersSection,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _rows.length; i++) ...[
                  _WorkOrderRowFields(
                    key: ObjectKey(_rows[i]),
                    row: _rows[i],
                    index: i,
                    canRemove: _rows.length > 1,
                    enabled: !_submitting,
                    onPickDate: () => _pickDate(_rows[i]),
                    onRemove: () => _removeRow(i),
                  ),
                  const SizedBox(height: 12),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _submitting ? null : _addRow,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.addWorkOrder),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.createProjectHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
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
              : Text(l10n.createProject),
        ),
      ],
    );
  }
}

/// Mutable holder for one work-order row's inputs.
class _WoRow {
  final name = TextEditingController();
  final description = TextEditingController();
  DateTime date = DateTime.now();

  void dispose() {
    name.dispose();
    description.dispose();
  }
}

class _WorkOrderRowFields extends StatelessWidget {
  const _WorkOrderRowFields({
    super.key,
    required this.row,
    required this.index,
    required this.canRemove,
    required this.enabled,
    required this.onPickDate,
    required this.onRemove,
  });

  final _WoRow row;
  final int index;
  final bool canRemove;
  final bool enabled;
  final VoidCallback onPickDate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.workOrderN(index + 1),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: l10n.removeWorkOrder,
                  visualDensity: VisualDensity.compact,
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.close, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: row.name,
            decoration: InputDecoration(labelText: l10n.workOrderNameLabel),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Enter a work-order name'
                : null,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: enabled ? onPickDate : null,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.workOrderDateLabel,
                suffixIcon: const Icon(Icons.calendar_today, size: 18),
              ),
              child: Text(
                formatDate(DateFormat('yyyy-MM-dd').format(row.date)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: row.description,
            decoration: InputDecoration(
              labelText: l10n.descriptionOptionalLabel,
            ),
            minLines: 1,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
