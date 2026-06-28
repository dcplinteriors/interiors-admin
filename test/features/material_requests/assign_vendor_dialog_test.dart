import 'package:dcpl_admin/features/material_requests/material_requests.dart';
import 'package:dcpl_admin/features/projects/projects.dart';
import 'package:dcpl_admin/features/supervisors/supervisors.dart';
import 'package:dcpl_admin/features/vendors/vendors.dart';
import 'package:dcpl_admin/features/work_orders/work_orders.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_app.dart';

class MockMaterialRequestRepository extends Mock
    implements MaterialRequestRepository {}

class MockProjectRepository extends Mock implements ProjectRepository {}

class MockWorkOrderRepository extends Mock implements WorkOrderRepository {}

class MockSupervisorRepository extends Mock implements SupervisorRepository {}

class MockVendorRepository extends Mock implements VendorRepository {}

const request = MaterialRequest(
  id: 'r1',
  itemNumber: '26-27_0001/0001/0001',
  workOrder: 'w1',
  project: 'p1',
  orderBy: 'sup1',
  batchId: 'b1',
  particular: 'Teak Ply',
  make: 'Greenlam',
  quantity: 12,
  unit: 'PCS',
  status: MaterialRequestStatus.processing,
  createdAt: '2026-06-05T00:00:00.000Z',
);

void main() {
  late MockMaterialRequestRepository repo;
  late MockProjectRepository projectRepo;
  late MockWorkOrderRepository workOrderRepo;
  late MockSupervisorRepository supervisorRepo;
  late MockVendorRepository vendorRepo;

  setUp(() {
    repo = MockMaterialRequestRepository();
    projectRepo = MockProjectRepository();
    workOrderRepo = MockWorkOrderRepository();
    supervisorRepo = MockSupervisorRepository();
    vendorRepo = MockVendorRepository();
    when(
      () => repo.list(
        status: any(named: 'status'),
        project: any(named: 'project'),
        workOrder: any(named: 'workOrder'),
        supervisor: any(named: 'supervisor'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => const Page(items: <MaterialRequest>[], nextCursor: null));
    when(() => projectRepo.listAll()).thenAnswer((_) async => <Project>[]);
    when(() => supervisorRepo.listAll()).thenAnswer((_) async => <Supervisor>[]);
    when(() => vendorRepo.listAll()).thenAnswer(
      (_) async => const [Vendor(id: 'v1', name: 'Steel Co'), Vendor(id: 'v2', name: 'Hettich')],
    );
    Get.put<VendorRepository>(vendorRepo);
    Get.put(
      MaterialRequestsController(repo, projectRepo, workOrderRepo, supervisorRepo),
    );
  });
  tearDown(Get.reset);

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(dialogHost((_) => const AssignVendorDialog(request: request))),
    );
    await tester.tap(find.text('__open__'));
    await tester.pumpAndSettle(); // open + load vendors
  }

  testWidgets('typing over a picked vendor clears the selection (no stale submit)', (
    tester,
  ) async {
    await openDialog(tester);

    // Pick "Steel Co" from the searchable menu.
    await tester.tap(find.byType(DropdownMenu<Vendor>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Steel Co').last);
    await tester.pumpAndSettle();

    // Type over the field without re-selecting a menu entry.
    await tester.enterText(find.byType(TextField).first, 'het');
    await tester.pumpAndSettle();

    // Attempt to assign: the guard should have dropped the stale selection, so the request is
    // never assigned and the vendor field flags the missing selection.
    await tester.tap(find.widgetWithText(FilledButton, 'Assign vendor'));
    await tester.pumpAndSettle();

    verifyNever(
      () => repo.assignVendor(
        any(),
        expectedDate: any(named: 'expectedDate'),
        vendorId: any(named: 'vendorId'),
        poNumber: any(named: 'poNumber'),
        remarks: any(named: 'remarks'),
      ),
    );
    expect(find.text('Select a vendor'), findsOneWidget);
    expect(find.byType(AssignVendorDialog), findsOneWidget);
  });
}
