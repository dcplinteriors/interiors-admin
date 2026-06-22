import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/projects/data/project_repository.dart';
import 'package:dcpl_shared/models/models.dart';
import 'package:get/get.dart';

class ProjectsController extends PaginatedController<Project> {
  ProjectsController(this._repo);

  final ProjectRepository _repo;

  final projects = <Project>[].obs;

  @override
  RxList<Project> get items => projects;

  @override
  Future<Page<Project>> fetchPage({String? cursor}) =>
      _repo.list(cursor: cursor);

  /// Loads the full project (with work orders) for the detail view.
  Future<Project> detail(String id) => _repo.get(id);

  /// Creates a project (with its initial work orders) and prepends it. Throws [ApiException].
  Future<Project> create({
    required String name,
    required String clientName,
    required String projectEngineer,
    required List<WorkOrderInput> workOrders,
  }) async {
    final created = await _repo.create(
      name: name,
      clientName: clientName,
      projectEngineer: projectEngineer,
      workOrders: workOrders,
    );
    projects.insert(0, created);
    return created;
  }

  /// Marks a project completed and replaces it in the list. Throws on failure.
  Future<Project> complete(String id) async {
    final updated = await _repo.complete(id);
    final i = projects.indexWhere((p) => p.id == id);
    if (i != -1) projects[i] = updated;
    return updated;
  }
}
