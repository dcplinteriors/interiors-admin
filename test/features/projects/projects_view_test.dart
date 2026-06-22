import 'dart:async';

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

  const project = Project(
    id: 'p1',
    number: '26-27_0001',
    name: 'Lobby fit-out',
    clientName: 'Acme',
    projectEngineer: 'Eng',
    status: ProjectStatus.active,
    workOrderCount: 2,
  );

  setUp(() {
    projects = MockProjectRepository();
  });
  tearDown(Get.reset);

  Future<void> pumpView(WidgetTester tester) async {
    Get.put(ProjectsController(projects));
    await tester.pumpWidget(testApp(const Scaffold(body: ProjectsView())));
  }

  testWidgets('shows a spinner while loading', (tester) async {
    final pending = Completer<Page<Project>>();
    when(
      () => projects.list(cursor: any(named: 'cursor')),
    ).thenAnswer((_) => pending.future);

    await pumpView(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(const Page(items: <Project>[], nextCursor: null));
    await tester.pumpAndSettle();
  });

  testWidgets('shows the empty state when there are no projects', (
    tester,
  ) async {
    when(
      () => projects.list(cursor: any(named: 'cursor')),
    ).thenAnswer((_) async => const Page(items: <Project>[], nextCursor: null));

    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text('No projects yet'), findsOneWidget);
  });

  testWidgets('shows the error state', (tester) async {
    when(
      () => projects.list(cursor: any(named: 'cursor')),
    ).thenThrow(ApiException(500, 'service down'));

    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load projects"), findsOneWidget);
    expect(find.text('service down'), findsOneWidget);
  });

  testWidgets('renders a row with the project name and number', (tester) async {
    when(
      () => projects.list(cursor: any(named: 'cursor')),
    ).thenAnswer((_) async => const Page(items: [project], nextCursor: null));

    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text('Lobby fit-out'), findsOneWidget);
    expect(find.text('26-27_0001'), findsOneWidget);
  });
}
