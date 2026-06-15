import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/supervisors/supervisors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupervisorsView extends GetView<SupervisorsController> {
  const SupervisorsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: context.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() => PageHeader(
                title: l10n.navSupervisors,
                count: '${controller.supervisors.length}',
                actions: [
                  Obx(() => RefreshButton(
                        tooltip: l10n.refresh,
                        onPressed: controller.fetch,
                        isRefreshing: controller.isLoading.value &&
                            controller.supervisors.isNotEmpty,
                      )),
                  context.isCompact
                      ? IconButton.filled(
                          tooltip: l10n.newSupervisor,
                          onPressed: () => _openCreate(context),
                          icon: const Icon(Icons.add),
                        )
                      : GradientButton(
                          onPressed: () => _openCreate(context),
                          icon: Icons.add,
                          label: l10n.newSupervisor,
                        ),
                ],
              )),
          const SizedBox(height: 24),
          Expanded(child: Obx(() => _body(context, l10n))),
          Obx(() => _loadMoreBar(l10n)),
        ],
      ),
    );
  }

  void _openCreate(BuildContext context) => showDialog(context: context, builder: (_) => const CreateSupervisorDialog());

  Widget _loadMoreBar(AppLocalizations l10n) {
    if (!controller.hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: controller.isLoadingMore.value
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : OutlinedButton.icon(onPressed: controller.loadMore, icon: const Icon(Icons.expand_more), label: Text(l10n.loadMore)),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n) {
    if (controller.isLoading.value && controller.supervisors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error.value != null) {
      return ErrorState(title: l10n.couldntLoadSupervisors, message: controller.error.value!, onRetry: controller.fetch);
    }
    if (controller.supervisors.isEmpty) {
      return EmptyState(
        icon: Icons.badge_outlined,
        title: l10n.noSupervisorsTitle,
        body: l10n.noSupervisorsBody,
        action: FilledButton.icon(onPressed: () => _openCreate(context), icon: const Icon(Icons.add), label: Text(l10n.newSupervisor)),
      );
    }
    return context.isCompact ? _cards(context, l10n) : _table(context, l10n);
  }

  Widget _cards(BuildContext context, AppLocalizations l10n) => ListView.separated(
    padding: EdgeInsets.zero,
    itemCount: controller.supervisors.length,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (context, i) {
      final s = controller.supervisors[i];
      final hasPhone = s.phone != null && s.phone!.isNotEmpty;
      return EntityCard(
        title: s.name,
        fields: [
          EntityField(l10n.colEmail, text: s.email),
          EntityField(l10n.colPhone, text: hasPhone ? s.phone! : '—', muted: !hasPhone),
          EntityField(l10n.colProjects, child: _AssignedProjects(s.projects)),
        ],
      );
    },
  );

  Widget _table(BuildContext context, AppLocalizations l10n) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return DcplTable(
      columns: [
        DcplColumn(l10n.colName, flex: 2),
        DcplColumn(l10n.colEmail, flex: 3),
        DcplColumn(l10n.colPhone, fixedWidth: 140),
        DcplColumn(l10n.colProjects, flex: 3),
      ],
      rows: [
        for (final s in controller.supervisors)
          DcplRow(
            cells: [
              PrimaryCell(s.name),
              Text(s.email),
              s.phone == null || s.phone!.isEmpty
                  ? Text('—', style: TextStyle(color: muted))
                  : Text(s.phone!),
              _AssignedProjects(s.projects),
            ],
          ),
      ],
    );
  }
}

/// The projects assigned to a supervisor, shown as a comma-separated list (capped with
/// a tooltip for the full set), or a muted dash when none are assigned.
class _AssignedProjects extends StatelessWidget {
  const _AssignedProjects(this.projects);

  final List<String> projects;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    if (projects.isEmpty) {
      return Text('—', style: TextStyle(color: muted));
    }
    final names = projects.join(', ');
    return Tooltip(
      message: names,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Text(names, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
