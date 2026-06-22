import 'package:dcpl_admin/features/material_requests/material_requests.dart';
import 'package:dcpl_admin/features/projects/projects.dart';
import 'package:dcpl_admin/features/work_orders/work_orders.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockMaterialRequestRepository extends Mock
    implements MaterialRequestRepository {}

class MockProjectRepository extends Mock implements ProjectRepository {}

class MockWorkOrderRepository extends Mock implements WorkOrderRepository {}

MaterialRequest _req({
  String id = 'mr1',
  MaterialRequestStatus status = MaterialRequestStatus.requested,
}) => MaterialRequest(
  id: id,
  itemNumber: '26-27_0001/0001/0001',
  workOrder: 'w1',
  project: 'p1',
  orderBy: 's1',
  batchId: 'b1',
  particular: 'Hinges',
  make: 'Hettich',
  quantity: 2,
  unit: 'PCS',
  status: status,
  createdAt: '2026-06-06T00:00:00.000Z',
);

void main() {
  late MockMaterialRequestRepository repo;
  late MockProjectRepository projectRepo;
  late MockWorkOrderRepository workOrderRepo;
  late MaterialRequestsController controller;

  setUp(() {
    repo = MockMaterialRequestRepository();
    projectRepo = MockProjectRepository();
    workOrderRepo = MockWorkOrderRepository();
    controller = MaterialRequestsController(repo, projectRepo, workOrderRepo);
  });

  void stubList(List<MaterialRequest> items, {String? cursor}) {
    when(
      () => repo.list(
        status: any(named: 'status'),
        project: any(named: 'project'),
        workOrder: any(named: 'workOrder'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => Page(items: items, nextCursor: cursor));
  }

  test('fetch() populates requests and cursor', () async {
    stubList([
      _req(),
      _req(id: 'mr2', status: MaterialRequestStatus.accepted),
    ], cursor: 'c1');
    await controller.fetch();
    expect(controller.requests, hasLength(2));
    expect(controller.hasMore, isTrue);
  });

  test('setStatusFilter() refetches with the new status', () async {
    stubList([_req()]);
    await controller.setStatusFilter(MaterialRequestStatus.processing);
    expect(controller.statusFilter.value, MaterialRequestStatus.processing);
    verify(
      () => repo.list(
        status: MaterialRequestStatus.processing,
        project: any(named: 'project'),
        workOrder: any(named: 'workOrder'),
        cursor: any(named: 'cursor'),
      ),
    ).called(1);
  });

  test(
    'setProjectFilter() loads cascade work orders and resets the work-order filter',
    () async {
      stubList([]);
      when(
        () => workOrderRepo.listAllForProject('p1'),
      ).thenAnswer((_) async => []);
      controller.workOrderFilter.value = 'w9';
      await controller.setProjectFilter('p1');
      expect(controller.projectFilter.value, 'p1');
      expect(controller.workOrderFilter.value, isNull);
      verify(() => workOrderRepo.listAllForProject('p1')).called(1);
    },
  );

  test(
    'acceptToProcessing() updates the row in place under the all filter',
    () async {
      controller.requests.add(_req());
      when(
        () => repo.accept('mr1', remarks: any(named: 'remarks')),
      ).thenAnswer((_) async => _req(status: MaterialRequestStatus.processing));
      await controller.acceptToProcessing('mr1');
      expect(
        controller.requests.single.status,
        MaterialRequestStatus.processing,
      );
    },
  );

  test(
    'acceptToProcessing() drops the row when it no longer matches the filter',
    () async {
      controller.statusFilter.value = MaterialRequestStatus.requested;
      controller.requests.add(_req());
      when(
        () => repo.accept('mr1', remarks: any(named: 'remarks')),
      ).thenAnswer((_) async => _req(status: MaterialRequestStatus.processing));
      await controller.acceptToProcessing('mr1');
      expect(controller.requests, isEmpty);
    },
  );

  test('assignVendor() delegates and applies the update', () async {
    controller.requests.add(_req(status: MaterialRequestStatus.processing));
    when(
      () => repo.assignVendor(
        'mr1',
        expectedDate: any(named: 'expectedDate'),
        vendor: any(named: 'vendor'),
        poNumber: any(named: 'poNumber'),
        remarks: any(named: 'remarks'),
      ),
    ).thenAnswer((_) async => _req(status: MaterialRequestStatus.accepted));
    await controller.assignVendor(
      'mr1',
      expectedDate: '2026-06-20',
      vendor: 'V Co',
    );
    expect(controller.requests.single.status, MaterialRequestStatus.accepted);
  });

  test('decline() delegates with the reason', () async {
    controller.requests.add(_req());
    when(
      () => repo.decline('mr1', 'no stock'),
    ).thenAnswer((_) async => _req(status: MaterialRequestStatus.declined));
    await controller.decline('mr1', 'no stock');
    verify(() => repo.decline('mr1', 'no stock')).called(1);
    expect(controller.requests.single.status, MaterialRequestStatus.declined);
  });

  test(
    'acceptToProcessing refreshes the nav badge (item left the queue)',
    () async {
      // A registered badge controller is poked after the decision → it re-pulls the count.
      when(
        () => repo.count(statuses: any(named: 'statuses')),
      ).thenAnswer((_) async => 0);
      Get.put<RequestsBadgeController>(RequestsBadgeController(repo));
      addTearDown(Get.reset);

      controller.requests.add(_req());
      when(
        () => repo.accept('mr1', remarks: any(named: 'remarks')),
      ).thenAnswer((_) async => _req(status: MaterialRequestStatus.processing));
      await controller.acceptToProcessing('mr1');

      verify(
        () => repo.count(
          statuses: [
            MaterialRequestStatus.requested,
            MaterialRequestStatus.processing,
          ],
        ),
      ).called(1);
    },
  );
}
