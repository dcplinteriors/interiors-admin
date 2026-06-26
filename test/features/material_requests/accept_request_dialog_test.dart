import 'package:dcpl_admin/features/material_requests/material_requests.dart';
import 'package:dcpl_admin/features/projects/projects.dart';
import 'package:dcpl_admin/features/supervisors/supervisors.dart';
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
  status: MaterialRequestStatus.requested,
  createdAt: '2026-06-05T00:00:00.000Z',
);

void main() {
  late MockMaterialRequestRepository repo;
  late MockProjectRepository projectRepo;
  late MockWorkOrderRepository workOrderRepo;
  late MockSupervisorRepository supervisorRepo;

  setUp(() {
    repo = MockMaterialRequestRepository();
    projectRepo = MockProjectRepository();
    workOrderRepo = MockWorkOrderRepository();
    supervisorRepo = MockSupervisorRepository();
    when(
      () => repo.list(
        status: any(named: 'status'),
        project: any(named: 'project'),
        workOrder: any(named: 'workOrder'),
        supervisor: any(named: 'supervisor'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async => const Page(items: <MaterialRequest>[], nextCursor: null),
    );
    when(() => projectRepo.listAll()).thenAnswer((_) async => <Project>[]);
    when(() => supervisorRepo.listAll()).thenAnswer((_) async => <Supervisor>[]);
    Get.put(
      MaterialRequestsController(repo, projectRepo, workOrderRepo, supervisorRepo),
    );
  });
  tearDown(Get.reset);

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(dialogHost((_) => const AcceptRequestDialog(request: request))),
    );
    await tester.tap(find.text('__open__'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'accepts a request into processing, closes, and shows a snackbar',
    (tester) async {
      when(
        () => repo.accept('r1', remarks: any(named: 'remarks')),
      ).thenAnswer((_) async => request);

      await openDialog(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Accept request'));
      await tester.pumpAndSettle();

      verify(() => repo.accept('r1', remarks: any(named: 'remarks'))).called(1);
      expect(find.byType(AcceptRequestDialog), findsNothing);
      expect(find.text('Request accepted'), findsOneWidget);
    },
  );
}
