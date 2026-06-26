import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_shared/models/models.dart';

abstract class MaterialRequestRepository {
  /// Lists requests (cursor-paginated), optionally filtered by [status], [project] and/or
  /// [workOrder], continuing after [cursor] (null = first page). Admin sees all.
  Future<Page<MaterialRequest>> list({
    MaterialRequestStatus? status,
    String? project,
    String? workOrder,
    String? cursor,
  });

  /// Server-side count of matching items (no pagination) — drives the review badge.
  /// Pass [statuses] to count several statuses in one call.
  Future<int> count({
    MaterialRequestStatus? status,
    List<MaterialRequestStatus>? statuses,
  });

  /// Approves a `requested` item into `processing` (vendor not yet assigned).
  Future<MaterialRequest> accept(String id, {String? remarks});

  /// Assigns the vendor + fulfilment details to a `processing` item (→ `accepted`).
  Future<MaterialRequest> assignVendor(
    String id, {
    required String expectedDate,
    required String vendor,
    String? poNumber,
    String? remarks,
  });

  /// Declines a `requested` item, with a required reason.
  Future<MaterialRequest> decline(String id, String remarks);

  /// Corrects the supervisor-entered item fields (allowed only while `requested`/`processing`).
  /// Only non-null fields are sent.
  Future<MaterialRequest> editItem(
    String id, {
    String? particular,
    String? make,
    String? size,
    num? quantity,
    String? unit,
  });
}

class ApiMaterialRequestRepository implements MaterialRequestRepository {
  ApiMaterialRequestRepository(this._api);

  final DcplApi _api;

  @override
  Future<Page<MaterialRequest>> list({
    MaterialRequestStatus? status,
    String? project,
    String? workOrder,
    String? cursor,
  }) => _api.materialRequests.list(
    status: status,
    project: project,
    workOrder: workOrder,
    cursor: cursor,
  );

  @override
  Future<int> count({
    MaterialRequestStatus? status,
    List<MaterialRequestStatus>? statuses,
  }) => _api.materialRequests.count(status: status, statuses: statuses);

  @override
  Future<MaterialRequest> accept(String id, {String? remarks}) =>
      _api.materialRequests.accept(id, remarks: remarks);

  @override
  Future<MaterialRequest> assignVendor(
    String id, {
    required String expectedDate,
    required String vendor,
    String? poNumber,
    String? remarks,
  }) => _api.materialRequests.assignVendor(
    id,
    expectedDate: expectedDate,
    vendor: vendor,
    poNumber: poNumber,
    remarks: remarks,
  );

  @override
  Future<MaterialRequest> decline(String id, String remarks) =>
      _api.materialRequests.decline(id, remarks);

  @override
  Future<MaterialRequest> editItem(
    String id, {
    String? particular,
    String? make,
    String? size,
    num? quantity,
    String? unit,
  }) => _api.materialRequests.editItem(
    id,
    particular: particular,
    make: make,
    size: size,
    quantity: quantity,
    unit: unit,
  );
}
