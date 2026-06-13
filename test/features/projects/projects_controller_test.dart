import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/projects/projects.dart';
import 'package:dcpl_admin/features/supervisors/supervisors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

class MockSupervisorRepository extends Mock implements SupervisorRepository {}

void main() {
  late MockProjectRepository repo;
  late MockSupervisorRepository supervisorRepo;
  late ProjectsController controller;

  final project = const Project(
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
    repo = MockProjectRepository();
    supervisorRepo = MockSupervisorRepository();
    controller = ProjectsController(repo, supervisorRepo);
  });

  test('fetch() populates projects and cursor on success', () async {
    when(() => repo.list(cursor: any(named: 'cursor')))
        .thenAnswer((_) async => (items: [project], nextCursor: 'c1'));
    await controller.fetch();
    expect(controller.projects, [project]);
    expect(controller.hasMore, isTrue);
    expect(controller.isLoading.value, isFalse);
    expect(controller.error.value, isNull);
  });

  test('fetch() sets error message on ApiException', () async {
    when(() => repo.list(cursor: any(named: 'cursor'))).thenThrow(ApiException(500, 'boom'));
    await controller.fetch();
    expect(controller.error.value, 'boom');
    expect(controller.projects, isEmpty);
    expect(controller.isLoading.value, isFalse);
  });

  test('loadMore() appends the next page and updates the cursor', () async {
    final p2 = const Project(
      id: 'p2',
      particular: 'Tower',
      clientName: 'Acme',
      date: '2026-06-05',
      po: 'PO_26-27_06/0002',
      supervisorId: null,
      status: 'active',
      createdAt: '2026-06-05T00:00:00.000Z',
    );
    when(() => repo.list(cursor: null))
        .thenAnswer((_) async => (items: [project], nextCursor: 'c1'));
    when(() => repo.list(cursor: 'c1'))
        .thenAnswer((_) async => (items: [p2], nextCursor: null));
    await controller.fetch();
    await controller.loadMore();
    expect(controller.projects, [project, p2]);
    expect(controller.hasMore, isFalse);
  });

  test('create() inserts the new project at the top of the list', () async {
    when(() => repo.create(
          particular: any(named: 'particular'),
          clientName: any(named: 'clientName'),
          date: any(named: 'date'),
        )).thenAnswer((_) async => project);
    final created = await controller.create(
      particular: 'Lobby',
      clientName: 'Acme',
      date: '2026-06-06',
    );
    expect(created, project);
    expect(controller.projects.first, project);
  });

  test('assign() replaces the project in the list with the updated one', () async {
    controller.projects.add(project);
    final assigned = const Project(
      id: 'p1',
      particular: 'Lobby',
      clientName: 'Acme',
      date: '2026-06-06',
      po: 'PO_26-27_06/0001',
      supervisorId: 'sup1',
      status: 'active',
      createdAt: '2026-06-06T00:00:00.000Z',
    );
    when(() => repo.assignSupervisor('p1', 'sup1')).thenAnswer((_) async => assigned);
    final result = await controller.assign('p1', 'sup1');
    expect(result.supervisorId, 'sup1');
    expect(controller.projects.single.supervisorId, 'sup1');
  });

  test('loadSupervisors() populates the supervisor list on success', () async {
    const sup = Supervisor(uid: 'sup1', name: 'Ravi', email: 'ravi@dcpl.test', phone: null);
    when(() => supervisorRepo.listAll()).thenAnswer((_) async => [sup]);
    await controller.loadSupervisors();
    expect(controller.supervisors, [sup]);
  });

  test('loadSupervisors() swallows ApiException (non-fatal) and leaves list empty', () async {
    when(() => supervisorRepo.listAll()).thenThrow(ApiException(500, 'boom'));
    await controller.loadSupervisors();
    expect(controller.supervisors, isEmpty);
  });

}
