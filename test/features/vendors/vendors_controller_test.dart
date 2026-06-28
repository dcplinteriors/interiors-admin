import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/vendors/vendors.dart';
import 'package:dcpl_shared/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockVendorRepository extends Mock implements VendorRepository {}

void main() {
  late MockVendorRepository repo;
  late VendorsController controller;

  const vendor = Vendor(id: 'v1', name: 'Steel Co');

  setUp(() {
    repo = MockVendorRepository();
    controller = VendorsController(repo);
  });

  test('fetch() populates vendors and cursor on success', () async {
    when(
      () => repo.list(cursor: any(named: 'cursor')),
    ).thenAnswer((_) async => const Page(items: [vendor], nextCursor: 'c1'));
    await controller.fetch();
    expect(controller.vendors, [vendor]);
    expect(controller.hasMore, isTrue);
    expect(controller.error.value, isNull);
  });

  test('fetch() sets the error message on ApiException', () async {
    when(
      () => repo.list(cursor: any(named: 'cursor')),
    ).thenThrow(ApiException(500, 'boom'));
    await controller.fetch();
    expect(controller.error.value, 'boom');
    expect(controller.vendors, isEmpty);
  });

  test('loadMore() appends the next page', () async {
    const v2 = Vendor(id: 'v2', name: 'Hettich');
    when(
      () => repo.list(cursor: null),
    ).thenAnswer((_) async => const Page(items: [vendor], nextCursor: 'c1'));
    when(
      () => repo.list(cursor: 'c1'),
    ).thenAnswer((_) async => const Page(items: [v2], nextCursor: null));
    await controller.fetch();
    await controller.loadMore();
    expect(controller.vendors, [vendor, v2]);
    expect(controller.hasMore, isFalse);
  });

  test('create() prepends the new vendor and returns it', () async {
    when(() => repo.create(name: any(named: 'name'))).thenAnswer(
      (_) async => const Vendor(id: 'v2', name: 'Hettich'),
    );
    final created = await controller.create(name: 'Hettich');
    expect(created.id, 'v2');
    expect(controller.vendors.first.id, 'v2');
  });

  test('edit() updates the vendor in place (e.g. deactivate)', () async {
    controller.vendors.add(vendor);
    when(
      () => repo.update(
        'v1',
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        email: any(named: 'email'),
        isActive: any(named: 'isActive'),
      ),
    ).thenAnswer((_) async => const Vendor(id: 'v1', name: 'Steel Co', isActive: false));
    final updated = await controller.edit('v1', isActive: false);
    expect(updated.isActive, isFalse);
    expect(controller.vendors.single.isActive, isFalse);
  });
}
