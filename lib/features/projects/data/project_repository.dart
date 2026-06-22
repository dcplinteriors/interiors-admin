import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_shared/models/models.dart';

/// Port for project data. The controller depends on this abstraction (testable with a fake).
abstract class ProjectRepository {
  /// Lists projects (cursor-paginated), continuing after [cursor] (null = first page).
  Future<Page<Project>> list({String? cursor});

  /// Every project (pages through `list`) — for the request/work-order project filters.
  Future<List<Project>> listAll();

  /// The full project with its work orders.
  Future<Project> get(String id);

  /// Creates a project together with its initial work orders.
  Future<Project> create({
    required String name,
    required String clientName,
    required String projectEngineer,
    required List<WorkOrderInput> workOrders,
  });

  /// Adds a work order to an existing project.
  Future<WorkOrder> addWorkOrder(String projectId, WorkOrderInput input);

  /// Marks a project completed.
  Future<Project> complete(String id);
}

class ApiProjectRepository implements ProjectRepository {
  ApiProjectRepository(this._api);

  final DcplApi _api;

  @override
  Future<Page<Project>> list({String? cursor}) =>
      _api.projects.list(cursor: cursor);

  @override
  Future<List<Project>> listAll() async {
    final all = <Project>[];
    String? cursor;
    do {
      final page = await _api.projects.list(cursor: cursor);
      all.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    return all;
  }

  @override
  Future<Project> get(String id) => _api.projects.get(id);

  @override
  Future<Project> create({
    required String name,
    required String clientName,
    required String projectEngineer,
    required List<WorkOrderInput> workOrders,
  }) => _api.projects.create(
    name: name,
    clientName: clientName,
    projectEngineer: projectEngineer,
    workOrders: workOrders,
  );

  @override
  Future<WorkOrder> addWorkOrder(String projectId, WorkOrderInput input) =>
      _api.projects.addWorkOrder(projectId, input);

  @override
  Future<Project> complete(String id) => _api.projects.complete(id);
}
