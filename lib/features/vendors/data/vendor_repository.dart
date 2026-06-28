import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_shared/models/models.dart';

abstract class VendorRepository {
  /// Lists vendors (cursor-paginated), continuing after [cursor] (null = first page). Drives the
  /// table; includes active and inactive vendors.
  Future<Page<Vendor>> list({String? cursor});

  /// Every vendor (pages through `list`). For the assign-vendor picker, which needs the full set.
  Future<List<Vendor>> listAll();

  /// `phone`/`email` are supported by the backend but not collected by the current form.
  Future<Vendor> create({required String name, String? phone, String? email});

  /// Edit a vendor / toggle its active state. Only the provided fields are sent.
  Future<Vendor> update(
    String id, {
    String? name,
    String? phone,
    String? email,
    bool? isActive,
  });
}

class ApiVendorRepository implements VendorRepository {
  ApiVendorRepository(this._api);

  final DcplApi _api;

  @override
  Future<Page<Vendor>> list({String? cursor}) =>
      _api.vendors.list(cursor: cursor);

  @override
  Future<List<Vendor>> listAll() async {
    final all = <Vendor>[];
    String? cursor;
    do {
      final page = await list(cursor: cursor);
      all.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    return all;
  }

  @override
  Future<Vendor> create({required String name, String? phone, String? email}) =>
      _api.vendors.create(name: name, phone: phone, email: email);

  @override
  Future<Vendor> update(
    String id, {
    String? name,
    String? phone,
    String? email,
    bool? isActive,
  }) => _api.vendors.update(
    id,
    name: name,
    phone: phone,
    email: email,
    isActive: isActive,
  );
}
