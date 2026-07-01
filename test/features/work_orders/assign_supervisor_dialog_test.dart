import 'package:dcpl_admin/features/projects/projects.dart';
import 'package:dcpl_admin/features/supervisors/supervisors.dart';
import 'package:dcpl_admin/features/work_orders/work_orders.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_app.dart';

class MockWorkOrderRepository extends Mock implements WorkOrderRepository {}

class MockSupervisorRepository extends Mock implements SupervisorRepository {}

class MockProjectRepository extends Mock implements ProjectRepository {}

const workOrder = WorkOrder(
  id: 'w1',
  project: 'p1',
  number: '26-27_0001/0001',
  name: 'Civil',
  date: '2026-06-10',
  status: WorkOrderStatus.pending,
);

void main() {
  late MockWorkOrderRepository workOrders;
  late MockSupervisorRepository supervisors;
  late MockProjectRepository projects;

  setUp(() {
    workOrders = MockWorkOrderRepository();
    supervisors = MockSupervisorRepository();
    projects = MockProjectRepository();
    when(
      () => workOrders.list(
        project: any(named: 'project'),
        status: any(named: 'status'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async => const Page(items: <WorkOrder>[], nextCursor: null),
    );
    when(() => projects.listAll()).thenAnswer((_) async => <Project>[]);
  });
  tearDown(Get.reset);

  Future<void> openDialog(WidgetTester tester) async {
    Get.put(WorkOrdersController(workOrders, supervisors, projects));
    await tester.pumpWidget(
      testApp(
        dialogHost((_) => const AssignSupervisorDialog(workOrder: workOrder)),
      ),
    );
    await tester.tap(find.text('__open__'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty hint when there are no supervisors', (
    tester,
  ) async {
    when(() => supervisors.listAll()).thenAnswer((_) async => const []);

    await openDialog(tester);

    expect(
      find.text('No supervisors yet. Add one in the Supervisors tab.'),
      findsOneWidget,
    );
  });

  testWidgets('assigns the selected supervisor, closes, and shows a snackbar', (
    tester,
  ) async {
    when(() => supervisors.listAll()).thenAnswer(
      (_) async => const [
        Supervisor(uid: 'sup1', name: 'Ravi', phone: null),
      ],
    );
    when(() => workOrders.assign('w1', 'sup1')).thenAnswer(
      (_) async => const WorkOrder(
        id: 'w1',
        project: 'p1',
        number: '26-27_0001/0001',
        name: 'Civil',
        date: '2026-06-10',
        status: WorkOrderStatus.active,
        supervisorId: 'sup1',
      ),
    );

    await openDialog(tester);
    await tester.tap(find.text('Ravi'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Assign'));
    await tester.pumpAndSettle();

    verify(() => workOrders.assign('w1', 'sup1')).called(1);
    expect(find.byType(AssignSupervisorDialog), findsNothing);
    expect(find.text('Supervisor assigned'), findsOneWidget);
  });
}
