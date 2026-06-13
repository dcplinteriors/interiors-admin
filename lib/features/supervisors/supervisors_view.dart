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
          Row(
            children: [
              // Title + count share a flexible slot so the title can ellipsize
              // on narrow widths; the actions then sit flush-right (no Spacer to
              // fight over slack, so no stray gap).
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(l10n.navSupervisors, style: Theme.of(context).textTheme.headlineSmall, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 12),
                    Obx(
                      () => Text(
                        l10n.countSupervisors(controller.supervisors.length),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              Obx(
                () => RefreshButton(
                  tooltip: l10n.refresh,
                  onPressed: controller.fetch,
                  isRefreshing: controller.isLoading.value && controller.supervisors.isNotEmpty,
                ),
              ),
              const SizedBox(width: 4),
              // On phones the "+" alone is enough; the label needs room.
              if (context.isCompact)
                IconButton.filled(
                  tooltip: l10n.newSupervisor,
                  onPressed: () => _openCreate(context),
                  icon: const Icon(Icons.add),
                )
              else
                FilledButton.icon(
                  onPressed: () => _openCreate(context),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.newSupervisor),
                ),
            ],
          ),
          const SizedBox(height: 16),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) => ScrollableTable(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: DataTable(
            columnSpacing: 24,
            columns: [
              DataColumn(label: Text(l10n.colName)),
              DataColumn(label: Text(l10n.colEmail)),
              DataColumn(label: Text(l10n.colPhone)),
              DataColumn(label: Text(l10n.colProjects)),
            ],
            rows: [
              for (final s in controller.supervisors)
                DataRow(
                  cells: [
                    DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(s.email)),
                    DataCell(s.phone == null || s.phone!.isEmpty ? Text('—', style: TextStyle(color: muted)) : Text(s.phone!)),
                    DataCell(_AssignedProjects(s.projects)),
                  ],
                ),
            ],
          ),
        ),
      ),
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
