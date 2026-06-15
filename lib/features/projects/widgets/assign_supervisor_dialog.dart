import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/projects/projects_controller.dart';
import 'package:dcpl_admin/features/supervisors/supervisors.dart';
import 'package:dcpl_shared/models/project.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AssignSupervisorDialog extends StatefulWidget {
  const AssignSupervisorDialog({super.key, required this.project});

  final Project project;

  @override
  State<AssignSupervisorDialog> createState() => _AssignSupervisorDialogState();
}

class _AssignSupervisorDialogState extends State<AssignSupervisorDialog> {
  String? _selectedUid;
  bool _submitting = false;
  String? _error;

  ProjectsController get _controller => Get.find<ProjectsController>();

  @override
  void initState() {
    super.initState();
    // Load the supervisor list for the picker each time the dialog opens, so a supervisor
    // added since is pickable. This is the only caller of loadSupervisors (the projects
    // table itself reads the backend-resolved name off each project). Body is reactive (Obx).
    _controller.loadSupervisors();
  }

  // Add a supervisor without leaving the assign flow: open the create dialog,
  // then refresh the picker and pre-select the newly-created supervisor.
  Future<void> _openCreate() async {
    final created = await showDialog<Supervisor>(
      context: context,
      builder: (_) => const CreateSupervisorDialog(),
    );
    if (!mounted) return;
    await _controller.loadSupervisors();
    if (created != null && mounted) {
      setState(() => _selectedUid = created.uid);
    }
  }

  Future<void> _assign() async {
    if (_selectedUid == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _controller.assign(widget.project.id, _selectedUid!);
      if (!mounted) return;
      final message = AppLocalizations.of(context).supervisorAssigned;
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
      title: Text(l10n.selectSupervisor),
      content: SizedBox(
        width: 420,
        child: Obx(() {
          final supervisors = _controller.supervisors;
          if (supervisors.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.noSupervisorsYet, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _openCreate,
                    icon: const Icon(Icons.person_add_alt),
                    label: Text(l10n.newSupervisor),
                  ),
                ],
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 8),
              ],
              Flexible(
                child: RadioGroup<String>(
                  groupValue: _selectedUid,
                  onChanged: (v) {
                    if (!_submitting) setState(() => _selectedUid = v);
                  },
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final s in supervisors)
                        RadioListTile<String>(
                          value: s.uid,
                          title: Text(s.name),
                          subtitle: Text(s.email),
                          secondary: CircleAvatar(child: Text(_initials(s.name))),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _submitting ? null : _openCreate,
                  icon: const Icon(Icons.person_add_alt, size: 18),
                  label: Text(l10n.newSupervisor),
                ),
              ),
            ],
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: (_selectedUid == null || _submitting) ? null : _assign,
          child: _submitting
              ? const SizedBox(
                  height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.assign),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
