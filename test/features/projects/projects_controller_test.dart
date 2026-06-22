import 'package:dcpl_admin/features/projects/projects.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

Project _project({
  String id = 'p1',
  ProjectStatus status = ProjectStatus.active,
  int? count,
}) => Project(
  id: id,
  number: '26-27_0001',
  name: 'Lobby',
  clientName: 'Acme',
  projectEngineer: 'Eng',
  status: status,
  createdAt: '2026-06-06T00:00:00.000Z',
  workOrderCount: count,
);

void main() {
  late MockProjectRepository repo;
  late ProjectsController controller;

  setUp(() {
    repo = MockProjectRepository();
    controller = ProjectsController(repo);
  });

  test('fetch() populates projects and cursor on success', () async {
    when(
      () => repo.list(cursor: any(named: 'cursor')),
    ).thenAnswer((_) async => Page(items: [_project()], nextCursor: 'c1'));
    await controller.fetch();
    expect(controller.projects, hasLength(1));
    expect(controller.hasMore, isTrue);
    expect(controller.isLoading.value, isFalse);
    expect(controller.error.value, isNull);
  });

  test('fetch() sets error message on ApiException', () async {
    when(
      () => repo.list(cursor: any(named: 'cursor')),
    ).thenThrow(ApiException(500, 'boom'));
    await controller.fetch();
    expect(controller.error.value, 'boom');
    expect(controller.projects, isEmpty);
  });

  test('loadMore() appends the next page and updates the cursor', () async {
    when(
      () => repo.list(cursor: null),
    ).thenAnswer((_) async => Page(items: [_project()], nextCursor: 'c1'));
    when(() => repo.list(cursor: 'c1')).thenAnswer(
      (_) async => Page(items: [_project(id: 'p2')], nextCursor: null),
    );
    await controller.fetch();
    await controller.loadMore();
    expect(controller.projects.map((p) => p.id), ['p1', 'p2']);
    expect(controller.hasMore, isFalse);
  });

  test('create() inserts the new project at the top', () async {
    when(
      () => repo.create(
        name: any(named: 'name'),
        clientName: any(named: 'clientName'),
        projectEngineer: any(named: 'projectEngineer'),
        workOrders: any(named: 'workOrders'),
      ),
    ).thenAnswer((_) async => _project(id: 'new'));
    final created = await controller.create(
      name: 'Lobby',
      clientName: 'Acme',
      projectEngineer: 'Eng',
      workOrders: const [WorkOrderInput(name: 'Civil', date: '2026-06-10')],
    );
    expect(created.id, 'new');
    expect(controller.projects.first.id, 'new');
  });

  test('complete() replaces the project in the list', () async {
    controller.projects.add(_project());
    when(
      () => repo.complete('p1'),
    ).thenAnswer((_) async => _project(status: ProjectStatus.completed));
    final result = await controller.complete('p1');
    expect(result.status, ProjectStatus.completed);
    expect(controller.projects.single.status, ProjectStatus.completed);
  });

  test('detail() delegates to the repository', () async {
    when(() => repo.get('p1')).thenAnswer((_) async => _project());
    final p = await controller.detail('p1');
    expect(p.id, 'p1');
    verify(() => repo.get('p1')).called(1);
  });
}
