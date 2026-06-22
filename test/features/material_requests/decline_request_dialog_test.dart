import 'package:dcpl_admin/features/material_requests/material_requests.dart';
import 'package:dcpl_admin/features/projects/projects.dart';
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

  setUp(() {
    repo = MockMaterialRequestRepository();
    projectRepo = MockProjectRepository();
    workOrderRepo = MockWorkOrderRepository();
    when(
      () => repo.list(
        status: any(named: 'status'),
        project: any(named: 'project'),
        workOrder: any(named: 'workOrder'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async => const Page(items: <MaterialRequest>[], nextCursor: null),
    );
    when(() => projectRepo.listAll()).thenAnswer((_) async => <Project>[]);
    Get.put(MaterialRequestsController(repo, projectRepo, workOrderRepo));
  });
  tearDown(Get.reset);

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(dialogHost((_) => const DeclineRequestDialog(request: request))),
    );
    await tester.tap(find.text('__open__'));
    await tester.pumpAndSettle();
  }

  testWidgets('declines with a reason, closes, and shows a snackbar', (
    tester,
  ) async {
    when(() => repo.decline('r1', any())).thenAnswer((_) async => request);

    await openDialog(tester);
    await tester.enterText(find.byType(TextFormField), 'Out of project scope');
    await tester.tap(find.widgetWithText(FilledButton, 'Decline'));
    await tester.pumpAndSettle();

    verify(() => repo.decline('r1', 'Out of project scope')).called(1);
    expect(find.byType(DeclineRequestDialog), findsNothing);
    expect(find.text('Request declined'), findsOneWidget);
  });

  testWidgets('a reason is required', (tester) async {
    await openDialog(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Decline'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a reason'), findsOneWidget);
    verifyNever(() => repo.decline(any(), any()));
  });
}
