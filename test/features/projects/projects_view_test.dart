import 'dart:async';

import 'package:dcpl_admin/core/core.dart';
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
    particular: 'Lobby fit-out',
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
    when(() => supervisors.listAll()).thenAnswer((_) async => const []);
  });
  tearDown(Get.reset);

  Future<void> pumpView(WidgetTester tester) async {
    Get.put(ProjectsController(projects, supervisors));
    await tester.pumpWidget(testApp(const Scaffold(body: ProjectsView())));
  }

  testWidgets('shows a spinner while loading', (tester) async {
    final pending = Completer<ProjectPage>();
    when(() => projects.list(cursor: any(named: 'cursor')))
        .thenAnswer((_) => pending.future);

    await pumpView(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete((items: const <Project>[], nextCursor: null));
    await tester.pumpAndSettle();
  });

  testWidgets('shows the empty state when there are no projects', (tester) async {
    when(() => projects.list(cursor: any(named: 'cursor')))
        .thenAnswer((_) async => (items: const <Project>[], nextCursor: null));

    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text('No projects yet'), findsOneWidget);
  });

  testWidgets('shows the error state', (tester) async {
    when(() => projects.list(cursor: any(named: 'cursor')))
        .thenThrow(ApiException(500, 'service down'));

    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load projects"), findsOneWidget);
    expect(find.text('service down'), findsOneWidget);
  });

  testWidgets('renders a row with the project and PO number', (tester) async {
    when(() => projects.list(cursor: any(named: 'cursor')))
        .thenAnswer((_) async => (items: const [project], nextCursor: null));

    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text('Lobby fit-out'), findsOneWidget);
    expect(find.text('PO_26-27_06/0001'), findsOneWidget);
  });
}
