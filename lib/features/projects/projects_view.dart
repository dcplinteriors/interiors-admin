import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/projects/projects.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProjectsView extends GetView<ProjectsController> {
  const ProjectsView({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: context.pagePadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        const SizedBox(height: 24),
        const Expanded(child: _Body()),
        LoadMoreBar(
          controller: controller,
          label: AppLocalizations.of(context).loadMore,
        ),
      ],
    ),
  );
}

class _Header extends GetView<ProjectsController> {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Obx(
      () => PageHeader(
        title: l10n.navProjects,
        count: '${controller.projects.length}',
        actions: [
          RefreshButton(
            tooltip: l10n.refresh,
            onPressed: controller.fetch,
            isRefreshing:
                controller.isLoading.value && controller.projects.isNotEmpty,
          ),
          const _CreateAction(),
        ],
      ),
    );
  }
}

/// Primary action: a full molten button on wide layouts, a compact "+" on phones.
class _CreateAction extends StatelessWidget {
  const _CreateAction();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return context.isCompact
        ? IconButton.filled(
            tooltip: l10n.newProject,
            onPressed: () => _openCreate(context),
            icon: const Icon(Icons.add),
          )
        : GradientButton(
            onPressed: () => _openCreate(context),
            icon: Icons.add,
            label: l10n.newProject,
          );
  }
}

void _openCreate(BuildContext context) =>
    showDialog(context: context, builder: (_) => const CreateProjectDialog());

void _openDetail(BuildContext context, String id) => showDialog(
  context: context,
  builder: (_) => ProjectDetailDialog(projectId: id),
);

class _Body extends GetView<ProjectsController> {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Obx(() {
      if (controller.isLoading.value && controller.projects.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value != null) {
        return ErrorState(
          title: l10n.couldntLoadProjects,
          message: controller.error.value!,
          onRetry: controller.fetch,
        );
      }
      if (controller.projects.isEmpty) {
        return EmptyState(
          icon: Icons.folder_open,
          title: l10n.noProjectsTitle,
          body: l10n.noProjectsBody,
          action: FilledButton.icon(
            onPressed: () => _openCreate(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.newProject),
          ),
        );
      }
      final projects = controller.projects.toList();
      return context.isCompact ? _Cards(projects) : _Table(projects);
    });
  }
}

class _Cards extends StatelessWidget {
  const _Cards(this.projects);

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = context.statusColors;
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: projects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = projects[i];
        return EntityCard(
          eyebrow: l10n.colProject,
          railColor: status.forProject(p.status.wire).ink,
          title: p.name,
          trailing: StatusChip(p.status),
          onTap: () => _openDetail(context, p.id),
          fields: [
            EntityField(l10n.colNumber, text: p.number, muted: true),
            EntityField(l10n.colClient, text: p.clientName),
            EntityField(l10n.colEngineer, text: p.projectEngineer),
            EntityField(l10n.colWorkOrders, text: '${p.workOrderCount ?? 0}'),
          ],
        );
      },
    );
  }
}

class _Table extends StatelessWidget {
  const _Table(this.projects);

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = context.statusColors;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return DcplTable(
      columns: [
        DcplColumn(l10n.colProject, flex: 3),
        DcplColumn(l10n.colNumber, fixedWidth: 128),
        DcplColumn(l10n.colClient, flex: 2),
        DcplColumn(l10n.colEngineer, flex: 2),
        DcplColumn(l10n.colWorkOrders, fixedWidth: 110, numeric: true),
        DcplColumn(l10n.colStatus, fixedWidth: 160),
      ],
      rows: [
        for (final p in projects)
          DcplRow(
            railColor: status.forProject(p.status.wire).ink,
            onTap: () => _openDetail(context, p.id),
            cells: [
              PrimaryCell(p.name),
              Text(p.number, style: TextStyle(color: muted)),
              Text(p.clientName),
              Text(p.projectEngineer),
              Text('${p.workOrderCount ?? 0}'),
              StatusChip(p.status),
            ],
          ),
      ],
    );
  }
}
