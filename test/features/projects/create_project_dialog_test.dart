import 'package:dcpl_admin/features/projects/projects.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_app.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

void main() {
  late MockProjectRepository projects;

  setUp(() {
    projects = MockProjectRepository();
    when(
      () => projects.list(cursor: any(named: 'cursor')),
    ).thenAnswer((_) async => const Page(items: <Project>[], nextCursor: null));
    Get.put(ProjectsController(projects));
  });
  tearDown(Get.reset);

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(dialogHost((_) => const CreateProjectDialog())),
    );
    await tester.tap(find.text('__open__'));
    await tester.pumpAndSettle();
  }

  testWidgets('validates project, client, engineer and the work-order name', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Create project'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a project name'), findsOneWidget);
    expect(find.text('Enter a client name'), findsOneWidget);
    expect(find.text('Enter a project engineer'), findsOneWidget);
    expect(find.text('Enter a work-order name'), findsOneWidget);
    verifyNever(
      () => projects.create(
        name: any(named: 'name'),
        clientName: any(named: 'clientName'),
        projectEngineer: any(named: 'projectEngineer'),
        workOrders: any(named: 'workOrders'),
      ),
    );
  });

  testWidgets('creates a project with a work order and shows a snackbar', (
    tester,
  ) async {
    when(
      () => projects.create(
        name: any(named: 'name'),
        clientName: any(named: 'clientName'),
        projectEngineer: any(named: 'projectEngineer'),
        workOrders: any(named: 'workOrders'),
      ),
    ).thenAnswer(
      (_) async => const Project(
        id: 'p1',
        number: '26-27_0001',
        name: 'Lobby',
        clientName: 'Acme',
        projectEngineer: 'Eng',
        status: ProjectStatus.active,
      ),
    );

    await openDialog(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Lobby'); // project name
    await tester.enterText(fields.at(1), 'Acme'); // client
    await tester.enterText(fields.at(2), 'Eng'); // engineer
    await tester.enterText(fields.at(3), 'Civil'); // work-order name
    await tester.tap(find.widgetWithText(FilledButton, 'Create project'));
    await tester.pumpAndSettle();

    final captured =
        verify(
              () => projects.create(
                name: 'Lobby',
                clientName: 'Acme',
                projectEngineer: 'Eng',
                workOrders: captureAny(named: 'workOrders'),
              ),
            ).captured.single
            as List<WorkOrderInput>;
    expect(captured.single.name, 'Civil');
    expect(find.byType(CreateProjectDialog), findsNothing);
    expect(find.text('Project created · 26-27_0001'), findsOneWidget);
  });
}
