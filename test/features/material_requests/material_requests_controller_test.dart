import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/material_requests.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMaterialRequestRepository extends Mock implements MaterialRequestRepository {}

MaterialRequest req(String status, {String? vendor}) => MaterialRequest(
      id: 'r1',
      project: 'p1',
      orderBy: 'sup1',
      poNumber: 'PO_26-27_06/0001',
      jobNumber: 'JB_26-27_06/0001',
      batchId: 'b1',
      particular: 'Teak Ply',
      make: 'Greenlam',
      quantity: 12,
      unit: 'PCS',
      status: status,
      createdAt: '2026-06-05T00:00:00.000Z',
      vendor: vendor,
    );

void main() {
  late MockMaterialRequestRepository repo;
  late MaterialRequestsController controller;

  setUp(() {
    repo = MockMaterialRequestRepository();
    controller = MaterialRequestsController(repo);
  });

  test('defaults to the "all" filter (null)', () {
    expect(controller.statusFilter.value, isNull);
  });

  test('fetch() populates requests using the active filter', () async {
    controller.statusFilter.value = 'requested';
    when(() => repo.list(status: any(named: 'status')))
        .thenAnswer((_) async => (items: [req('requested')], nextCursor: null));
    await controller.fetch();
    expect(controller.requests, hasLength(1));
    verify(() => repo.list(status: 'requested')).called(1);
  });

  test('fetch() sets the error message on ApiException', () async {
    when(() => repo.list(status: any(named: 'status'))).thenThrow(ApiException(500, 'boom'));
    await controller.fetch();
    expect(controller.error.value, 'boom');
    expect(controller.requests, isEmpty);
  });

  test('setFilter() switches the filter and refetches', () async {
    when(() => repo.list(status: any(named: 'status')))
        .thenAnswer((_) async => (items: <MaterialRequest>[], nextCursor: null));
    await controller.setFilter('accepted');
    expect(controller.statusFilter.value, 'accepted');
    verify(() => repo.list(status: 'accepted')).called(1);
  });

  test('loadMore() appends the next page and updates hasMore', () async {
    // First page has a cursor → hasMore; loadMore fetches the second (final) page.
    when(() => repo.list(status: any(named: 'status'), cursor: null))
        .thenAnswer((_) async => (items: [req('requested')], nextCursor: 'c1'));
    await controller.fetch();
    expect(controller.requests, hasLength(1));
    expect(controller.hasMore, isTrue);

    when(() => repo.list(status: any(named: 'status'), cursor: 'c1'))
        .thenAnswer((_) async => (items: [req('accepted')], nextCursor: null));
    await controller.loadMore();
    expect(controller.requests, hasLength(2)); // appended, not replaced
    expect(controller.hasMore, isFalse);
  });

  test('loadMore() is a no-op when there is no next page', () async {
    when(() => repo.list(status: any(named: 'status'), cursor: any(named: 'cursor')))
        .thenAnswer((_) async => (items: <MaterialRequest>[], nextCursor: null));
    await controller.fetch();
    await controller.loadMore();
    expect(controller.hasMore, isFalse);
    // Only the fetch hit the repo — loadMore did nothing.
    verify(() => repo.list(status: any(named: 'status'), cursor: any(named: 'cursor'))).called(1);
  });

  test('accept() drops the row when it no longer matches the active filter', () async {
    controller.statusFilter.value = 'requested'; // viewing the review queue
    controller.requests.add(req('requested'));
    when(() => repo.accept('r1',
            expectedDate: any(named: 'expectedDate'),
            vendor: any(named: 'vendor'),
            remarks: any(named: 'remarks')))
        .thenAnswer((_) async => req('accepted', vendor: 'Hafele'));

    await controller.accept('r1', expectedDate: '2026-06-20', vendor: 'Hafele', remarks: '');

    expect(controller.requests, isEmpty);
  });

  test('accept() updates the row in place when viewing all', () async {
    controller.statusFilter.value = null; // all
    controller.requests.add(req('requested'));
    when(() => repo.accept('r1',
            expectedDate: any(named: 'expectedDate'),
            vendor: any(named: 'vendor'),
            remarks: any(named: 'remarks')))
        .thenAnswer((_) async => req('accepted', vendor: 'Hafele'));

    await controller.accept('r1', expectedDate: '2026-06-20', vendor: 'Hafele');

    expect(controller.requests.single.status, 'accepted');
  });

  test('decline() drops the row from the "requested" filter', () async {
    controller.statusFilter.value = 'requested';
    controller.requests.add(req('requested'));
    when(() => repo.decline('r1', remarks: any(named: 'remarks')))
        .thenAnswer((_) async => req('declined'));

    await controller.decline('r1', remarks: 'out of scope');

    expect(controller.requests, isEmpty);
  });
}
