import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/projects/projects_controller.dart';
import 'package:dcpl_admin/features/projects/widgets/assign_supervisor_dialog.dart';
import 'package:dcpl_admin/features/projects/widgets/assignment_chip.dart';
import 'package:dcpl_admin/features/projects/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Project detail + assign action. Reads the project from the controller by id so it
/// re-renders after an assignment updates the list.
class ProjectDetailDialog extends StatelessWidget {
  const ProjectDetailDialog({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = Get.find<ProjectsController>();

    return AlertDialog(
      content: SizedBox(
        width: 460,
        child: Obx(() {
          final project =
              controller.projects.firstWhereOrNull((p) => p.id == projectId);
          if (project == null) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Project not found'),
            );
          }
          final supervisorName = project.supervisorName;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(project.particular,
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  StatusChip(project.status),
                  AssignmentChip(name: project.isAssigned ? supervisorName : null),
                ],
              ),
              const SizedBox(height: 24),
              _DetailRow(label: l10n.colPo, value: project.po),
              _DetailRow(label: l10n.colClient, value: project.clientName),
              _DetailRow(label: l10n.colDate, value: formatDate(project.date)),
              const SizedBox(height: 16),
              if (!project.isAssigned)
                FilledButton.icon(
                  onPressed: () => _openAssign(context, controller, project.id),
                  icon: const Icon(Icons.person_add_alt),
                  label: Text(l10n.assignSupervisor),
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(supervisorName ?? '—'),
                  trailing: TextButton(
                    onPressed: () => _openAssign(context, controller, project.id),
                    child: Text(l10n.changeSupervisor),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  void _openAssign(BuildContext context, ProjectsController controller, String id) {
    final project = controller.projects.firstWhereOrNull((p) => p.id == id);
    if (project == null) return;
    showDialog(
      context: context,
      builder: (_) => AssignSupervisorDialog(project: project),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
