import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/supervisors/data/supervisor.dart';

/// One page of supervisors plus the cursor for the next page (null = last page).
typedef SupervisorPage = ({List<Supervisor> items, String? nextCursor});

abstract class SupervisorRepository {
  /// Lists supervisors (cursor-paginated), continuing after [cursor] (null = first page).
  /// Drives the table.
  Future<SupervisorPage> list({String? cursor});

  /// Every supervisor (pages through `list`). For the assign picker, which needs the full set.
  Future<List<Supervisor>> listAll();

  Future<Supervisor> create({
    required String name,
    required String email,
    String? phone,
  });
}

class ApiSupervisorRepository implements SupervisorRepository {
  ApiSupervisorRepository(this._api);

  final ApiClient _api;

  @override
  Future<SupervisorPage> list({String? cursor}) async {
    final data = await _api.get(
      '/supervisors',
      query: {'cursor': ?cursor},
    ) as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => Supervisor.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: items, nextCursor: data['nextCursor'] as String?);
  }

  @override
  Future<List<Supervisor>> listAll() async {
    final all = <Supervisor>[];
    String? cursor;
    do {
      final page = await list(cursor: cursor);
      all.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    return all;
  }

  @override
  Future<Supervisor> create({
    required String name,
    required String email,
    String? phone,
  }) async {
    final data = await _api.post('/supervisors', body: {
      'name': name,
      'email': email,
      // Omit phone when empty — the backend treats it as optional, not nullable.
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return Supervisor.fromJson(data as Map<String, dynamic>);
  }
}
