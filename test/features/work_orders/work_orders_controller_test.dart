import 'package:dcpl_admin/features/projects/projects.dart';
import 'package:dcpl_admin/features/supervisors/supervisors.dart';
import 'package:dcpl_admin/features/work_orders/work_orders.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkOrderRepository extends Mock implements WorkOrderRepository {}

class MockSupervisorRepository extends Mock implements SupervisorRepository {}

class MockProjectRepository extends Mock implements ProjectRepository {}

WorkOrder _wo({
  String id = 'w1',
  WorkOrderStatus status = WorkOrderStatus.pending,
}) => WorkOrder(
  id: id,
  project: 'p1',
  number: '26-27_0001/0001',
  name: 'Civil',
  date: '2026-06-10',
  status: status,
  supervisorId: status == WorkOrderStatus.pending ? null : 's1',
);

void main() {
  late MockWorkOrderRepository repo;
  late MockSupervisorRepository supervisorRepo;
  late MockProjectRepository projectRepo;
  late WorkOrdersController controller;

  setUp(() {
    repo = MockWorkOrderRepository();
    supervisorRepo = MockSupervisorRepository();
    projectRepo = MockProjectRepository();
    controller = WorkOrdersController(repo, supervisorRepo, projectRepo);
  });

  void stubList(List<WorkOrder> items, {String? cursor}) {
    when(
      () => repo.list(
        project: any(named: 'project'),
        status: any(named: 'status'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => Page(items: items, nextCursor: cursor));
  }

  test('fetch() populates work orders and cursor', () async {
    stubList([_wo()], cursor: 'c1');
    await controller.fetch();
    expect(controller.workOrders, hasLength(1));
    expect(controller.hasMore, isTrue);
  });

  test('setStatusFilter() refetches with the status', () async {
    stubList([_wo()]);
    await controller.setStatusFilter(WorkOrderStatus.active);
    verify(
      () => repo.list(
        project: any(named: 'project'),
        status: WorkOrderStatus.active,
        cursor: any(named: 'cursor'),
      ),
    ).called(1);
  });

  test('assign() updates the row in place under the all filter', () async {
    controller.workOrders.add(_wo());
    when(
      () => repo.assign('w1', 's1'),
    ).thenAnswer((_) async => _wo(status: WorkOrderStatus.active));
    await controller.assign('w1', 's1');
    expect(controller.workOrders.single.status, WorkOrderStatus.active);
  });

  test('complete() drops the row when filtering by active', () async {
    controller.statusFilter.value = WorkOrderStatus.active;
    controller.workOrders.add(_wo(status: WorkOrderStatus.active));
    when(
      () => repo.complete('w1'),
    ).thenAnswer((_) async => _wo(status: WorkOrderStatus.completed));
    await controller.complete('w1');
    expect(controller.workOrders, isEmpty);
  });

  test('cancel() delegates and applies the update', () async {
    controller.workOrders.add(_wo());
    when(
      () => repo.cancel('w1'),
    ).thenAnswer((_) async => _wo(status: WorkOrderStatus.cancelled));
    await controller.cancel('w1');
    expect(controller.workOrders.single.status, WorkOrderStatus.cancelled);
  });

  test('loadSupervisors() swallows ApiException (non-fatal)', () async {
    when(() => supervisorRepo.listAll()).thenThrow(ApiException(500, 'boom'));
    await controller.loadSupervisors();
    expect(controller.supervisors, isEmpty);
  });

  test('loadProjects() populates the project filter options', () async {
    const project = Project(
      id: 'p1',
      number: '26-27_0001',
      name: 'Lobby',
      clientName: 'Acme',
      projectEngineer: 'Eng',
      status: ProjectStatus.active,
    );
    when(() => projectRepo.listAll()).thenAnswer((_) async => [project]);
    await controller.loadProjects();
    expect(controller.projects, [project]);
  });
}
