import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/supervisors/data/supervisor.dart';
import 'package:dcpl_admin/features/supervisors/data/supervisor_repository.dart';
import 'package:get/get.dart';

class SupervisorsController extends GetxController {
  SupervisorsController(this._repo);

  final SupervisorRepository _repo;

  final supervisors = <Supervisor>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();

  /// Cursor for the next page, or null when the loaded list is complete.
  final _nextCursor = RxnString();
  bool get hasMore => _nextCursor.value != null;

  /// Bumped on every `fetch()`. A `loadMore()` captures the current value and discards its
  /// result if a fetch superseded it meanwhile.
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
      // Each supervisor carries the names of their assigned projects, resolved by the backend.
      final page = await _repo.list();
      if (gen != _generation) return; // superseded by a newer fetch
      supervisors.value = page.items;
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
    final gen = _generation;
    isLoadingMore.value = true;
    try {
      final page = await _repo.list(cursor: _nextCursor.value);
      if (gen != _generation) return; // a refresh superseded this load
      supervisors.addAll(page.items);
      _nextCursor.value = page.nextCursor;
    } on ApiException catch (e) {
      if (gen == _generation) error.value = e.message;
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Creates a supervisor (the backend also emails them a set-password invite) and
  /// prepends it to the list. Throws [ApiException] on failure for the dialog to show.
  Future<Supervisor> create({
    required String name,
    required String email,
    String? phone,
  }) async {
    final created = await _repo.create(name: name, email: email, phone: phone);
    supervisors.insert(0, created);
    return created;
  }
}
