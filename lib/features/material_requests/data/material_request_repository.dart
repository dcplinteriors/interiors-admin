import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_shared/models/material_request.dart';

/// One page of requests plus the cursor for the next page (null = last page).
typedef RequestPage = ({List<MaterialRequest> items, String? nextCursor});

abstract class MaterialRequestRepository {
  /// Lists requests (cursor-paginated), optionally filtered by [status] (null = all) and
  /// continuing after [cursor]. Admin sees all.
  Future<RequestPage> list({String? status, String? cursor});

  /// Accepts a `requested` item, attaching the admin's fulfilment details.
  Future<MaterialRequest> accept(
    String id, {
    required String expectedDate,
    required String vendor,
    String? remarks,
  });

  /// Declines a `requested` item, with an optional reason.
  Future<MaterialRequest> decline(String id, {String? remarks});
}

class ApiMaterialRequestRepository implements MaterialRequestRepository {
  ApiMaterialRequestRepository(this._api);

  final ApiClient _api;

  @override
  Future<RequestPage> list({String? status, String? cursor}) async {
    final data = await _api.get(
      '/material-requests',
      query: {'status': ?status, 'cursor': ?cursor},
    ) as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => MaterialRequest.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: items, nextCursor: data['nextCursor'] as String?);
  }

  @override
  Future<MaterialRequest> accept(
    String id, {
    required String expectedDate,
    required String vendor,
    String? remarks,
  }) async {
    final data = await _api.post('/material-requests/$id/accept', body: {
      'expectedDate': expectedDate,
      'vendor': vendor,
      // Omit remarks when empty — the backend treats it as optional.
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    });
    return MaterialRequest.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<MaterialRequest> decline(String id, {String? remarks}) async {
    final data = await _api.post('/material-requests/$id/decline', body: {
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    });
    return MaterialRequest.fromJson(data as Map<String, dynamic>);
  }
}
