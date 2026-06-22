import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/supervisors/data/supervisor.dart';
import 'package:dcpl_admin/features/supervisors/data/supervisor_repository.dart';
import 'package:get/get.dart';

class SupervisorsController extends PaginatedController<Supervisor> {
  SupervisorsController(this._repo);

  final SupervisorRepository _repo;

  final supervisors = <Supervisor>[].obs;

  @override
  RxList<Supervisor> get items => supervisors;

  @override
  Future<Page<Supervisor>> fetchPage({String? cursor}) =>
      _repo.list(cursor: cursor);

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
