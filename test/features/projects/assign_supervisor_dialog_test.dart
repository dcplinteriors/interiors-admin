import 'package:dcpl_admin/features/projects/projects.dart';
import 'package:dcpl_admin/features/supervisors/supervisors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_app.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

class MockSupervisorRepository extends Mock implements SupervisorRepository {}

void main() {
  late MockProjectRepository projects;
  late MockSupervisorRepository supervisors;

  const project = Project(
    id: 'p1',
    particular: 'Lobby',
    clientName: 'Acme',
    date: '2026-06-06',
    po: 'PO_26-27_06/0001',
    supervisorId: null,
    status: 'active',
    createdAt: '2026-06-06T00:00:00.000Z',
  );

  setUp(() {
    projects = MockProjectRepository();
    supervisors = MockSupervisorRepository();
    when(() => projects.list(cursor: any(named: 'cursor')))
        .thenAnswer((_) async => (items: [project], nextCursor: null));
  });
  tearDown(Get.reset);

  Future<void> openDialog(WidgetTester tester) async {
    Get.put(ProjectsController(projects, supervisors));
    await tester.pumpWidget(
      testApp(dialogHost((_) => const AssignSupervisorDialog(project: project))),
    );
    await tester.tap(find.text('__open__'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty hint when there are no supervisors', (tester) async {
    when(() => supervisors.listAll()).thenAnswer((_) async => const []);

    await openDialog(tester);

    expect(find.text('No supervisors yet. Add one in the Supervisors tab.'), findsOneWidget);
  });

  testWidgets('assigns the selected supervisor, closes, and shows a snackbar', (tester) async {
    when(() => supervisors.listAll()).thenAnswer(
      (_) async => const [Supervisor(uid: 'sup1', name: 'Ravi', email: 'r@x.com', phone: null)],
    );
    when(() => projects.assignSupervisor('p1', 'sup1')).thenAnswer(
      (_) async => const Project(
        id: 'p1',
        particular: 'Lobby',
        clientName: 'Acme',
        date: '2026-06-06',
        po: 'PO_26-27_06/0001',
        supervisorId: 'sup1',
        status: 'active',
        createdAt: '2026-06-06T00:00:00.000Z',
      ),
    );

    await openDialog(tester);
    await tester.tap(find.text('Ravi'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Assign'));
    await tester.pumpAndSettle();

    verify(() => projects.assignSupervisor('p1', 'sup1')).called(1);
    expect(find.byType(AssignSupervisorDialog), findsNothing);
    expect(find.text('Supervisor assigned'), findsOneWidget);
  });
}
