import 'dart:async';

import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/data/material_request_repository.dart';
import 'package:dcpl_admin/features/material_requests/requests_badge_controller.dart';
import 'package:dcpl_admin/features/projects/data/project_repository.dart';
import 'package:dcpl_admin/features/supervisors/data/supervisor.dart';
import 'package:dcpl_admin/features/supervisors/data/supervisor_repository.dart';
import 'package:dcpl_admin/features/work_orders/data/work_order_repository.dart';
import 'package:dcpl_shared/models/models.dart';
import 'package:get/get.dart';

class MaterialRequestsController extends PaginatedController<MaterialRequest> {
  MaterialRequestsController(
    this._repo,
    this._projectRepo,
    this._workOrderRepo,
    this._supervisorRepo,
  );

  final MaterialRequestRepository _repo;
  final ProjectRepository _projectRepo;
  final WorkOrderRepository _workOrderRepo;
  final SupervisorRepository _supervisorRepo;

  final requests = <MaterialRequest>[].obs;

  /// Filters. `statusFilter` null = all; `projectFilter`/`workOrderFilter`/`supervisorFilter`
  /// are ids (supervisor = the item's current assignee).
  final statusFilter = Rxn<MaterialRequestStatus>();
  final projectFilter = RxnString();
  final workOrderFilter = RxnString();
  final supervisorFilter = RxnString();

  /// Filter-dropdown options. Work orders cascade from the selected project; supervisors are a
  /// flat list (a supervisor's items can span projects).
  final projects = <Project>[].obs;
  final workOrders = <WorkOrder>[].obs;
  final supervisors = <Supervisor>[].obs;

  @override
  RxList<MaterialRequest> get items => requests;

  @override
  Future<Page<MaterialRequest>> fetchPage({String? cursor}) => _repo.list(
    status: statusFilter.value,
    // A work order already implies its project, so drop the redundant project filter when one is
    // selected — it keeps the query to a single index (project+workOrder has none) and gives the
    // same results.
    project: workOrderFilter.value == null ? projectFilter.value : null,
    workOrder: workOrderFilter.value,
    supervisor: supervisorFilter.value,
    cursor: cursor,
  );

  @override
  void onInit() {
    super.onInit();
    loadProjects();
    loadSupervisors();
  }

  Future<void> setStatusFilter(MaterialRequestStatus? status) async {
    if (statusFilter.value == status) return;
    statusFilter.value = status;
    await fetch();
  }

  /// Selecting a project narrows the work-order filter to that project; clearing it
  /// resets the work-order filter + options.
  Future<void> setProjectFilter(String? projectId) async {
    if (projectFilter.value == projectId) return;
    projectFilter.value = projectId;
    workOrderFilter.value = null;
    workOrders.clear();
    if (projectId != null) unawaited(loadWorkOrders(projectId));
    await fetch();
  }

  Future<void> setWorkOrderFilter(String? workOrderId) async {
    if (workOrderFilter.value == workOrderId) return;
    workOrderFilter.value = workOrderId;
    await fetch();
  }

  Future<void> setSupervisorFilter(String? supervisorUid) async {
    if (supervisorFilter.value == supervisorUid) return;
    supervisorFilter.value = supervisorUid;
    await fetch();
  }

  Future<void> loadSupervisors() async {
    try {
      supervisors.value = await _supervisorRepo.listAll();
    } on ApiException catch (_) {
      // Filter simply shows no supervisor options.
    }
  }

  Future<void> loadProjects() async {
    try {
      projects.value = await _projectRepo.listAll();
    } on ApiException catch (_) {
      // Filter simply shows no project options.
    }
  }

  Future<void> loadWorkOrders(String projectId) async {
    try {
      workOrders.value = await _workOrderRepo.listAllForProject(projectId);
    } on ApiException catch (_) {
      // Cascade simply shows no work-order options.
    }
  }

  /// Step 1 of fulfilment: approve a `requested` item into `processing`.
  Future<MaterialRequest> acceptToProcessing(
    String id, {
    String? remarks,
  }) async {
    final updated = await _repo.accept(id, remarks: remarks);
    _applyDecision(updated);
    _notifyActionableQueueChanged(); // requested → processing (still actionable)
    return updated;
  }

  /// Step 2: assign the vendor to a `processing` item (→ `accepted`).
  Future<MaterialRequest> assignVendor(
    String id, {
    required String expectedDate,
    required String vendorId,
    String? poNumber,
    String? remarks,
  }) async {
    final updated = await _repo.assignVendor(
      id,
      expectedDate: expectedDate,
      vendorId: vendorId,
      poNumber: poNumber,
      remarks: remarks,
    );
    _applyDecision(updated);
    _notifyActionableQueueChanged(); // processing → accepted (left the queue)
    return updated;
  }

  Future<MaterialRequest> decline(String id, String reason) async {
    final updated = await _repo.decline(id, reason);
    _applyDecision(updated);
    _notifyActionableQueueChanged(); // left the requested queue
    return updated;
  }

  /// Admin corrects the supervisor's item entry. Status is unchanged, so the row just updates in
  /// place (and the actionable badge count is unaffected).
  Future<MaterialRequest> editItem(
    String id, {
    String? particular,
    String? make,
    String? size,
    num? quantity,
    String? unit,
  }) async {
    final updated = await _repo.editItem(
      id,
      particular: particular,
      make: make,
      size: size,
      quantity: quantity,
      unit: unit,
    );
    _applyDecision(updated);
    return updated;
  }

  /// After a decision the row's status changes: drop it from view when it no longer
  /// matches the active status filter (e.g. processing while viewing "requested"), else update.
  void _applyDecision(MaterialRequest updated) {
    final i = requests.indexWhere((r) => r.id == updated.id);
    if (i == -1) return;
    final filter = statusFilter.value;
    if (filter != null && filter != updated.status) {
      requests.removeAt(i);
    } else {
      requests[i] = updated;
    }
  }

  /// Asks the (permanent) badge controller to re-pull the server-side actionable count
  /// (requested + processing) after an admin decision changes it. No-op in tests where the
  /// badge controller isn't registered.
  void _notifyActionableQueueChanged() {
    if (Get.isRegistered<RequestsBadgeController>()) {
      Get.find<RequestsBadgeController>().refreshCount();
    }
  }
}
