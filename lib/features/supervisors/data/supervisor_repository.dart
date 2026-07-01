import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/supervisors/data/supervisor.dart';

/// The created supervisor plus the one-time temporary password to hand over
/// (the password is never retrievable again).
typedef CreatedSupervisorResult = ({Supervisor supervisor, String tempPassword});

abstract class SupervisorRepository {
  /// Lists supervisors (cursor-paginated), continuing after [cursor] (null = first page).
  /// Drives the table.
  Future<Page<Supervisor>> list({String? cursor});

  /// Every supervisor (pages through `list`). For the assign picker, which needs the full set.
  Future<List<Supervisor>> listAll();

  /// Creates a supervisor from name + 10-digit [phone]. The backend provisions the
  /// Firebase account and returns the supervisor plus a one-time temporary password.
  Future<CreatedSupervisorResult> create({
    required String name,
    required String phone,
  });

  /// Resets a supervisor's password, returning the new one-time temporary password.
  Future<String> resetPassword(String uid);
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
  Future<CreatedSupervisorResult> create({
    required String name,
    required String phone,
  }) async {
    final created = await _api.supervisors.create(name: name, phone: phone);
    return (
      supervisor: Supervisor.fromUser(created.supervisor),
      tempPassword: created.tempPassword,
    );
  }

  @override
  Future<String> resetPassword(String uid) =>
      _api.supervisors.resetPassword(uid);
}
