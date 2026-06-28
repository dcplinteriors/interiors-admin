import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/work_orders/work_orders_controller.dart';
import 'package:dcpl_shared/models/models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Adds a work order to an existing project. The project picker lists only non-completed projects
/// (the backend rejects adding to a completed one). Pops with the created [WorkOrder].
class AddWorkOrderDialog extends StatefulWidget {
  const AddWorkOrderDialog({super.key, this.initialProjectId});

  /// Pre-selected project — e.g. the one currently filtered in the list.
  final String? initialProjectId;

  @override
  State<AddWorkOrderDialog> createState() => _AddWorkOrderDialogState();
}

class _AddWorkOrderDialogState extends State<AddWorkOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _projectField = TextEditingController();
  final _name = TextEditingController();
  final _description = TextEditingController();
  Project? _selectedProject;
  DateTime _date = DateTime.now();

  bool _submitting = false;
  String? _error;
  bool _projectMissing = false;

  WorkOrdersController get _controller => Get.find<WorkOrdersController>();

  List<Project> get _projects => _controller.projects
      .where((p) => p.status != ProjectStatus.completed)
      .toList();

  @override
  void initState() {
    super.initState();
    _projectField.addListener(_syncProjectSelection);
    final matches = _projects.where((p) => p.id == widget.initialProjectId);
    if (matches.isNotEmpty) {
      _selectedProject = matches.first;
      _projectField.text = matches.first.name;
    }
  }

  // DropdownMenu keeps a stale selection when the field is typed over (it doesn't re-fire
  // onSelected or revert the text) — drop the selection when the text diverges so a re-pick is
  // required, keeping submit consistent with what's shown.
  void _syncProjectSelection() {
    if (_selectedProject != null &&
        _projectField.text.trim() != _selectedProject!.name) {
      setState(() => _selectedProject = null);
    }
  }

  @override
  void dispose() {
    _projectField.removeListener(_syncProjectSelection);
    _projectField.dispose();
    _name.dispose();
    _description.dispose();
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
    final formOk = _formKey.currentState!.validate();
    final projectOk = _selectedProject != null;
    if (!projectOk) setState(() => _projectMissing = true);
    if (!formOk || !projectOk) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final created = await _controller.addToProject(
        _selectedProject!.id,
        name: _name.text.trim(),
        date: DateFormat('yyyy-MM-dd').format(_date),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
      );
      if (!mounted) return;
      final message = AppLocalizations.of(context).workOrderAdded;
      Navigator.of(context).pop(created);
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
    return AlertDialog(
      title: Text(l10n.newWorkOrder),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
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
                DropdownMenu<Project>(
                  controller: _projectField,
                  initialSelection: _selectedProject,
                  enabled: !_submitting,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  expandedInsets: EdgeInsets.zero,
                  inputDecorationTheme: theme.inputDecorationTheme,
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      theme.colorScheme.surfaceContainerHigh,
                    ),
                  ),
                  label: Text(l10n.colProject),
                  leadingIcon: const Icon(Icons.folder_outlined, size: 18),
                  errorText: _projectMissing ? l10n.selectProject : null,
                  onSelected: (p) => setState(() {
                    _selectedProject = p;
                    _projectMissing = false;
                  }),
                  dropdownMenuEntries: [
                    for (final p in _projects)
                      DropdownMenuEntry(value: p, label: p.name),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.workOrderNameLabel,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _submitting ? null : _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.dateLabel,
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(
                      formatDate(DateFormat('yyyy-MM-dd').format(_date)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l10n.descriptionLabel),
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
              : Text(l10n.add),
        ),
      ],
    );
  }
}
