import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/projects/projects.dart';
import 'package:dcpl_admin/features/supervisors/supervisors.dart';
import 'package:dcpl_admin/features/work_orders/data/work_order_repository.dart';
import 'package:dcpl_shared/models/models.dart';
import 'package:get/get.dart';

class WorkOrdersController extends PaginatedController<WorkOrder> {
  WorkOrdersController(this._repo, this._supervisorRepo, this._projectRepo);

  final WorkOrderRepository _repo;
  final SupervisorRepository _supervisorRepo;
  final ProjectRepository _projectRepo;

  final workOrders = <WorkOrder>[].obs;

  /// Filters. `projectFilter` is a project id; null means "all projects".
  final projectFilter = RxnString();
  final statusFilter = Rxn<WorkOrderStatus>();

  /// Options for the filter dropdown / assign picker (loaded lazily).
  final projects = <Project>[].obs;
  final supervisors = <Supervisor>[].obs;

  @override
  RxList<WorkOrder> get items => workOrders;

  @override
  Future<Page<WorkOrder>> fetchPage({String? cursor}) => _repo.list(
    project: projectFilter.value,
    status: statusFilter.value,
    cursor: cursor,
  );

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  Future<void> setProjectFilter(String? projectId) async {
    if (projectFilter.value == projectId) return;
    projectFilter.value = projectId;
    await fetch();
  }

  Future<void> setStatusFilter(WorkOrderStatus? status) async {
    if (statusFilter.value == status) return;
    statusFilter.value = status;
    await fetch();
  }

  /// Loads the project list for the filter dropdown. Non-fatal.
  Future<void> loadProjects() async {
    try {
      projects.value = await _projectRepo.listAll();
    } on ApiException catch (_) {
      // Filter simply shows no project options.
    }
  }

  /// Loads the supervisor list for the assign picker (called when the dialog opens). Non-fatal.
  Future<void> loadSupervisors() async {
    try {
      supervisors.value = await _supervisorRepo.listAll();
    } on ApiException catch (_) {
      // The picker shows no options.
    }
  }

  Future<WorkOrder> assign(String id, String supervisorId) async {
    final updated = await _repo.assign(id, supervisorId);
    _apply(updated);
    return updated;
  }

  Future<WorkOrder> unassign(String id) async {
    final updated = await _repo.unassign(id);
    _apply(updated);
    return updated;
  }

  Future<WorkOrder> complete(String id) async {
    final updated = await _repo.complete(id);
    _apply(updated);
    return updated;
  }

  Future<WorkOrder> cancel(String id) async {
    final updated = await _repo.cancel(id);
    _apply(updated);
    return updated;
  }

  /// After an action the row's status changes: drop it from view when it no longer matches
  /// the active status filter (e.g. completed while viewing "active"), else update it in place.
  void _apply(WorkOrder updated) {
    final i = workOrders.indexWhere((w) => w.id == updated.id);
    if (i == -1) return;
    final filter = statusFilter.value;
    if (filter != null && filter != updated.status) {
      workOrders.removeAt(i);
    } else {
      workOrders[i] = updated;
    }
  }
}
