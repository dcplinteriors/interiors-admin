import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/data/material_request_repository.dart';
import 'package:dcpl_shared/models/material_request.dart';
import 'package:get/get.dart';

class MaterialRequestsController extends GetxController {
  MaterialRequestsController(this._repo);

  final MaterialRequestRepository _repo;

  final requests = <MaterialRequest>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();

  /// The active status filter; null means "all" (the default tab).
  final statusFilter = RxnString();

  /// Cursor for the next page, or null when the loaded list is complete.
  final _nextCursor = RxnString();
  bool get hasMore => _nextCursor.value != null;

  /// Bumped on every `fetch()` (a new filter / first page). A `loadMore()` captures the
  /// current value and discards its result if a fetch superseded it meanwhile.
  int _generation = 0;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  /// Loads the first page for the active filter, replacing the list.
  Future<void> fetch() async {
    final gen = ++_generation;
    isLoading.value = true;
    error.value = null;
    try {
      // Each request carries its clientName + supervisorName, resolved by the backend.
      final page = await _repo.list(status: statusFilter.value);
      if (gen != _generation) return; // superseded by a newer fetch
      requests.value = page.items;
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
    final gen = _generation; // a fetch() (filter change) would bump this and invalidate us
    isLoadingMore.value = true;
    try {
      final page = await _repo.list(status: statusFilter.value, cursor: _nextCursor.value);
      if (gen != _generation) return; // a filter change superseded this load
      requests.addAll(page.items);
      _nextCursor.value = page.nextCursor;
    } on ApiException catch (e) {
      if (gen == _generation) error.value = e.message;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> setFilter(String? status) async {
    if (statusFilter.value == status) return;
    statusFilter.value = status;
    await fetch();
  }

  Future<MaterialRequest> accept(
    String id, {
    required String expectedDate,
    required String vendor,
    String? remarks,
  }) async {
    final updated = await _repo.accept(
      id,
      expectedDate: expectedDate,
      vendor: vendor,
      remarks: remarks,
    );
    _applyDecision(updated);
    return updated;
  }

  Future<MaterialRequest> decline(String id, {String? remarks}) async {
    final updated = await _repo.decline(id, remarks: remarks);
    _applyDecision(updated);
    return updated;
  }

  /// After a decision the row's status changes: drop it from view when it no longer
  /// matches the active filter (e.g. accepted while viewing "To review"), else update it.
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
}
