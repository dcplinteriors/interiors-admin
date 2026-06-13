import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/projects/data/project_repository.dart';
import 'package:dcpl_admin/features/supervisors/supervisors.dart';
import 'package:dcpl_shared/models/project.dart';
import 'package:get/get.dart';

class ProjectsController extends GetxController {
  ProjectsController(this._repo, this._supervisorRepo);

  final ProjectRepository _repo;
  final SupervisorRepository _supervisorRepo;

  final projects = <Project>[].obs;
  final supervisors = <Supervisor>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();

  /// Cursor for the next page, or null when the loaded list is complete.
  final _nextCursor = RxnString();
  bool get hasMore => _nextCursor.value != null;

  /// Bumped on every `fetch()` (first page). A `loadMore()` captures the current value and
  /// discards its result if a fetch superseded it meanwhile.
  int _generation = 0;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  /// Loads the first page, replacing the list.
  Future<void> fetch() async {
    final gen = ++_generation;
    isLoading.value = true;
    error.value = null;
    try {
      // Each project carries its supervisorName, resolved by the backend.
      final page = await _repo.list();
      if (gen != _generation) return; // superseded by a newer fetch
      projects.value = page.items;
      _nextCursor.value = page.nextCursor;
    } on ApiException catch (e) {
      if (gen == _generation) error.value = e.message;
    } finally {
      if (gen == _generation) isLoading.value = false;
    }
  }

  /// Appends the next page. No-op if already loading or there's nothing more.
  Future<void> loadMore() async {
    if (isLoadingMore.value || _nextCursor.value == null) return;
    final gen = _generation; // a fetch() would bump this and invalidate us
    isLoadingMore.value = true;
    try {
      final page = await _repo.list(cursor: _nextCursor.value);
      if (gen != _generation) return; // a refresh superseded this load
      projects.addAll(page.items);
      _nextCursor.value = page.nextCursor;
    } on ApiException catch (e) {
      if (gen == _generation) error.value = e.message;
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Loads the supervisor list for the assign picker (called when the dialog opens).
  /// Non-fatal — the picker simply shows no options if it fails.
  Future<void> loadSupervisors() async {
    try {
      supervisors.value = await _supervisorRepo.listAll();
    } on ApiException catch (_) {
      // The picker shows no options.
    }
  }

  /// Creates a project and prepends it. Throws [ApiException] on failure.
  Future<Project> create({
    required String particular,
    required String clientName,
    required String date,
  }) async {
    final created = await _repo.create(
      particular: particular,
      clientName: clientName,
      date: date,
    );
    projects.insert(0, created);
    return created;
  }

  /// Assigns a supervisor and replaces the project in the list. Throws on failure.
  Future<Project> assign(String projectId, String supervisorId) async {
    final updated = await _repo.assignSupervisor(projectId, supervisorId);
    final index = projects.indexWhere((p) => p.id == projectId);
    if (index != -1) projects[index] = updated;
    return updated;
  }
}
