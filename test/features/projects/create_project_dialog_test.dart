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

  setUp(() {
    projects = MockProjectRepository();
    supervisors = MockSupervisorRepository();
    when(() => projects.list(cursor: any(named: 'cursor')))
        .thenAnswer((_) async => (items: <Project>[], nextCursor: null));
    when(() => supervisors.listAll()).thenAnswer((_) async => <Supervisor>[]);
    Get.put(ProjectsController(projects, supervisors));
  });
  tearDown(Get.reset);

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(testApp(dialogHost((_) => const CreateProjectDialog())));
    await tester.tap(find.text('__open__'));
    await tester.pumpAndSettle();
  }

  testWidgets('validates required project and client names', (tester) async {
    await openDialog(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Create project'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a project name'), findsOneWidget);
    expect(find.text('Enter a client name'), findsOneWidget);
    verifyNever(
      () => projects.create(
        particular: any(named: 'particular'),
        clientName: any(named: 'clientName'),
        date: any(named: 'date'),
      ),
    );
  });

  testWidgets('creates a project, closes, and shows a snackbar with the PO', (tester) async {
    when(() => projects.create(
          particular: any(named: 'particular'),
          clientName: any(named: 'clientName'),
          date: any(named: 'date'),
        )).thenAnswer(
      (_) async => const Project(
        id: 'p1',
        particular: 'Lobby',
        clientName: 'Acme',
        date: '2026-06-06',
        po: 'PO_26-27_06/0001',
        supervisorId: null,
        status: 'active',
        createdAt: '2026-06-06T00:00:00.000Z',
      ),
    );

    await openDialog(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Lobby');
    await tester.enterText(fields.at(1), 'Acme');
    await tester.tap(find.widgetWithText(FilledButton, 'Create project'));
    await tester.pumpAndSettle();

    verify(() => projects.create(
          particular: 'Lobby',
          clientName: 'Acme',
          date: any(named: 'date'),
        )).called(1);
    expect(find.byType(CreateProjectDialog), findsNothing);
    expect(find.text('Project created · PO_26-27_06/0001'), findsOneWidget);
  });
}
