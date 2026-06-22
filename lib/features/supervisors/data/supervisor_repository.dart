import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/supervisors/data/supervisor.dart';

abstract class SupervisorRepository {
  /// Lists supervisors (cursor-paginated), continuing after [cursor] (null = first page).
  /// Drives the table.
  Future<Page<Supervisor>> list({String? cursor});

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

  final DcplApi _api;

  @override
  Future<Page<Supervisor>> list({String? cursor}) async {
    final page = await _api.supervisors.list(cursor: cursor);
    return Page(
      items: page.items.map(Supervisor.fromUser).toList(),
      nextCursor: page.nextCursor,
    );
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
    final user = await _api.supervisors.create(
      name: name,
      email: email,
      phone: phone,
    );
    return Supervisor.fromUser(user);
  }
}
