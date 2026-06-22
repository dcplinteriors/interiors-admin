import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_shared/models/models.dart';

/// Port for work-order data. The controller depends on this abstraction (testable with a fake).
abstract class WorkOrderRepository {
  /// Lists work orders (cursor-paginated), optionally scoped to a [project] and/or [status],
  /// continuing after [cursor] (null = first page).
  Future<Page<WorkOrder>> list({
    String? project,
    WorkOrderStatus? status,
    String? cursor,
  });

  /// Every work order under [project] (pages through `list`) — for the request work-order filter.
  Future<List<WorkOrder>> listAllForProject(String project);

  Future<WorkOrder> get(String id);

  /// Assigns a supervisor (pending → active).
  Future<WorkOrder> assign(String id, String supervisorId);

  /// Removes the assignment (active → pending). Rejected by the backend if open items exist.
  Future<WorkOrder> unassign(String id);

  /// Marks the work order completed.
  Future<WorkOrder> complete(String id);

  /// Cancels an (unassigned) work order.
  Future<WorkOrder> cancel(String id);
}

class ApiWorkOrderRepository implements WorkOrderRepository {
  ApiWorkOrderRepository(this._api);

  final DcplApi _api;

  @override
  Future<Page<WorkOrder>> list({
    String? project,
    WorkOrderStatus? status,
    String? cursor,
  }) => _api.workOrders.list(project: project, status: status, cursor: cursor);

  @override
  Future<List<WorkOrder>> listAllForProject(String project) async {
    final all = <WorkOrder>[];
    String? cursor;
    do {
      final page = await _api.workOrders.list(project: project, cursor: cursor);
      all.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    return all;
  }

  @override
  Future<WorkOrder> get(String id) => _api.workOrders.get(id);

  @override
  Future<WorkOrder> assign(String id, String supervisorId) =>
      _api.workOrders.assign(id, supervisorId);

  @override
  Future<WorkOrder> unassign(String id) => _api.workOrders.unassign(id);

  @override
  Future<WorkOrder> complete(String id) => _api.workOrders.complete(id);

  @override
  Future<WorkOrder> cancel(String id) => _api.workOrders.cancel(id);
}
