import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/vendors/data/vendor_repository.dart';
import 'package:dcpl_shared/models/models.dart';
import 'package:get/get.dart';

class VendorsController extends PaginatedController<Vendor> {
  VendorsController(this._repo);

  final VendorRepository _repo;

  final vendors = <Vendor>[].obs;

  @override
  RxList<Vendor> get items => vendors;

  @override
  Future<Page<Vendor>> fetchPage({String? cursor}) => _repo.list(cursor: cursor);

  /// Adds a vendor and prepends it to the list. Throws [ApiException] for the dialog to show.
  Future<Vendor> create({required String name}) async {
    final created = await _repo.create(name: name);
    vendors.insert(0, created);
    return created;
  }

  /// Edits a vendor's name and/or active state; updates it in place. (Named `edit` to avoid
  /// clashing with GetxController.update.)
  Future<Vendor> edit(String id, {String? name, bool? isActive}) async {
    final updated = await _repo.update(id, name: name, isActive: isActive);
    final i = vendors.indexWhere((v) => v.id == id);
    if (i != -1) vendors[i] = updated;
    return updated;
  }
}
