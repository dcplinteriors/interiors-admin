import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/supervisors/supervisors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupervisorsView extends GetView<SupervisorsController> {
  const SupervisorsView({super.key});

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

class _Header extends GetView<SupervisorsController> {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Obx(
      () => PageHeader(
        title: l10n.navSupervisors,
        count: '${controller.supervisors.length}',
        actions: [
          RefreshButton(
            tooltip: l10n.refresh,
            onPressed: controller.fetch,
            isRefreshing:
                controller.isLoading.value && controller.supervisors.isNotEmpty,
          ),
          const _CreateAction(),
        ],
      ),
    );
  }
}

class _CreateAction extends StatelessWidget {
  const _CreateAction();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return context.isCompact
        ? IconButton.filled(
            tooltip: l10n.newSupervisor,
            onPressed: () => _openCreate(context),
            icon: const Icon(Icons.add),
          )
        : GradientButton(
            onPressed: () => _openCreate(context),
            icon: Icons.add,
            label: l10n.newSupervisor,
          );
  }
}

void _openCreate(BuildContext context) => showDialog(
  context: context,
  builder: (_) => const CreateSupervisorDialog(),
);

/// Confirms, then resets [s]'s password and shows the new one-time credentials.
Future<void> _resetPassword(BuildContext context, Supervisor s) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    // Pop via the dialog's OWN context: with go_router's shell navigator, popping through the
    // outer page context tears the page off the branch stack instead of closing the dialog.
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.resetPasswordTitle),
      content: Text(l10n.resetPasswordBody(s.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.resetPassword),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    final tempPassword = await Get.find<SupervisorsController>().resetPassword(
      s.uid,
    );
    if (!context.mounted) return;
    await showSupervisorCredentialsDialog(
      context,
      title: l10n.passwordResetTitle,
      phone: s.phone ?? '', // the panel formats it for display
      tempPassword: tempPassword,
    );
  } on ApiException catch (e) {
    showAppSnackbar(e.message);
  } catch (_) {
    // Anything unexpected must still surface as a message, never a blank screen.
    showAppSnackbar('Couldn\'t reset the password. Please try again.');
  }
}

class _Body extends GetView<SupervisorsController> {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Obx(() {
      if (controller.isLoading.value && controller.supervisors.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value != null) {
        return ErrorState(
          title: l10n.couldntLoadSupervisors,
          message: controller.error.value!,
          onRetry: controller.fetch,
        );
      }
      if (controller.supervisors.isEmpty) {
        return EmptyState(
          icon: Icons.badge_outlined,
          title: l10n.noSupervisorsTitle,
          body: l10n.noSupervisorsBody,
          action: FilledButton.icon(
            onPressed: () => _openCreate(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.newSupervisor),
          ),
        );
      }
      return context.isCompact
          ? _Cards(controller.supervisors.toList())
          : _Table(controller.supervisors.toList());
    });
  }
}

class _Cards extends StatelessWidget {
  const _Cards(this.supervisors);

  final List<Supervisor> supervisors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: supervisors.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final s = supervisors[i];
        final hasPhone = s.phone != null && s.phone!.isNotEmpty;
        return EntityCard(
          title: s.name,
          fields: [
            EntityField(
              l10n.colPhone,
              text: hasPhone ? formatPhone(s.phone!) : '—',
              muted: !hasPhone,
            ),
            EntityField(
              l10n.colWorkOrders,
              child: _AssignedWorkOrders(s.workOrders),
            ),
          ],
          footer: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _resetPassword(context, s),
              icon: const Icon(Icons.lock_reset, size: 18),
              label: Text(l10n.resetPassword),
            ),
          ),
        );
      },
    );
  }
}

class _Table extends StatelessWidget {
  const _Table(this.supervisors);

  final List<Supervisor> supervisors;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final l10n = AppLocalizations.of(context);
    return DcplTable(
      trailing: true,
      columns: [
        DcplColumn(l10n.colName, flex: 2),
        DcplColumn(l10n.colPhone, fixedWidth: 160),
        DcplColumn(l10n.colWorkOrders, flex: 3),
      ],
      rows: [
        for (final s in supervisors)
          DcplRow(
            cells: [
              PrimaryCell(s.name),
              s.phone == null || s.phone!.isEmpty
                  ? Text('—', style: TextStyle(color: muted))
                  : Text(formatPhone(s.phone!)),
              _AssignedWorkOrders(s.workOrders),
            ],
            actions: [
              IconButton(
                tooltip: l10n.resetPassword,
                icon: const Icon(Icons.lock_reset),
                onPressed: () => _resetPassword(context, s),
              ),
            ],
          ),
      ],
    );
  }
}

/// The work orders assigned to a supervisor, shown as a comma-separated list (capped with
/// a tooltip for the full set), or a muted dash when none are assigned.
class _AssignedWorkOrders extends StatelessWidget {
  const _AssignedWorkOrders(this.workOrders);

  final List<String> workOrders;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    if (workOrders.isEmpty) {
      return Text('—', style: TextStyle(color: muted));
    }
    final names = workOrders.join(', ');
    return Tooltip(
      message: names,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Text(names, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
