import 'dart:async';

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

MaterialRequest req(MaterialRequestStatus status, {String? vendor}) =>
    MaterialRequest(
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
      status: status,
      createdAt: '2026-06-05T00:00:00.000Z',
      vendor: vendor,
      // Names resolved by the backend and arriving on the request.
      workOrderName: 'Civil',
      clientName: 'Acme',
      supervisorName: 'Ravi',
    );

void main() {
  late MockMaterialRequestRepository repo;
  late MockProjectRepository projectRepo;
  late MockWorkOrderRepository workOrderRepo;

  setUp(() {
    repo = MockMaterialRequestRepository();
    projectRepo = MockProjectRepository();
    workOrderRepo = MockWorkOrderRepository();
    when(() => projectRepo.listAll()).thenAnswer((_) async => <Project>[]);
  });
  tearDown(Get.reset);

  void stubList(List<MaterialRequest> items) {
    when(
      () => repo.list(
        status: any(named: 'status'),
        project: any(named: 'project'),
        workOrder: any(named: 'workOrder'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => Page(items: items, nextCursor: null));
  }

  Future<void> pumpView(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Get.put(MaterialRequestsController(repo, projectRepo, workOrderRepo));
    await tester.pumpWidget(testApp(const Scaffold(body: RequestsView())));
  }

  testWidgets('shows a spinner while loading', (tester) async {
    final pending = Completer<Page<MaterialRequest>>();
    when(
      () => repo.list(
        status: any(named: 'status'),
        project: any(named: 'project'),
        workOrder: any(named: 'workOrder'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) => pending.future);

    await pumpView(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(const Page(items: <MaterialRequest>[], nextCursor: null));
    await tester.pumpAndSettle();
  });

  testWidgets('shows the empty state when there are no requests', (
    tester,
  ) async {
    stubList([]);
    await pumpView(tester);
    await tester.pumpAndSettle();
    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('shows the error state', (tester) async {
    when(
      () => repo.list(
        status: any(named: 'status'),
        project: any(named: 'project'),
        workOrder: any(named: 'workOrder'),
        cursor: any(named: 'cursor'),
      ),
    ).thenThrow(ApiException(500, 'service down'));

    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load requests"), findsOneWidget);
    expect(find.text('service down'), findsOneWidget);
  });

  testWidgets(
    'renders a requested row with resolved names and action buttons',
    (tester) async {
      stubList([req(MaterialRequestStatus.requested)]);
      await pumpView(tester);
      await tester.pumpAndSettle();

      expect(find.text('Teak Ply'), findsOneWidget);
      expect(find.text('Ravi'), findsOneWidget); // resolved supervisor name
      expect(find.text('12 PCS'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Accept'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Decline'), findsOneWidget);
    },
  );

  testWidgets('a processing row offers "Assign vendor"', (tester) async {
    stubList([req(MaterialRequestStatus.processing)]);
    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Assign vendor'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Accept'), findsNothing);
  });

  testWidgets('an accepted row shows the vendor instead of buttons', (
    tester,
  ) async {
    stubList([req(MaterialRequestStatus.accepted, vendor: 'Hafele')]);
    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text('→ Hafele'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Accept'), findsNothing);
  });

  testWidgets('tapping Accept opens the accept dialog', (tester) async {
    stubList([req(MaterialRequestStatus.requested)]);
    await pumpView(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
    await tester.pumpAndSettle();

    expect(find.byType(AcceptRequestDialog), findsOneWidget);
  });
}
