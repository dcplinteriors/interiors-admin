import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/projects/projects.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late ApiProjectRepository repo;

  setUp(() {
    api = MockApiClient();
    repo = ApiProjectRepository(DcplApi(api));
  });

  Map<String, dynamic> projectJson() => {
    'id': 'p1',
    'number': '26-27_0001',
    'name': 'Lobby',
    'clientName': 'Acme',
    'projectEngineer': 'Eng',
    'status': 'active',
    'createdAt': '2026-06-06T00:00:00.000Z',
    'workOrderCount': 2,
  };

  Map<String, dynamic> workOrderJson() => {
    'id': 'w1',
    'project': 'p1',
    'number': '26-27_0001/0001',
    'name': 'Civil',
    'date': '2026-06-10',
    'status': 'pending',
  };

  test('list() GETs /projects and parses the page', () async {
    when(() => api.get('/projects', query: any(named: 'query'))).thenAnswer(
      (_) async => {
        'items': [projectJson()],
        'nextCursor': 'c1',
      },
    );
    final result = await repo.list();
    expect(result.items, hasLength(1));
    expect(result.items.first.name, 'Lobby');
    expect(result.items.first.workOrderCount, 2);
    expect(result.nextCursor, 'c1');
  });

  test('listAll() pages through every project', () async {
    var call = 0;
    when(() => api.get('/projects', query: any(named: 'query'))).thenAnswer((
      _,
    ) async {
      call++;
      return call == 1
          ? {
              'items': [projectJson()],
              'nextCursor': 'c1',
            }
          : {'items': <dynamic>[], 'nextCursor': null};
    });
    final all = await repo.listAll();
    expect(all, hasLength(1));
    verify(() => api.get('/projects', query: any(named: 'query'))).called(2);
  });

  test('create() POSTs /projects with the project + work orders', () async {
    when(() => api.post('/projects', body: any(named: 'body'))).thenAnswer(
      (_) async => {
        ...projectJson(),
        'workOrders': [workOrderJson()],
      },
    );
    final p = await repo.create(
      name: 'Lobby',
      clientName: 'Acme',
      projectEngineer: 'Eng',
      workOrders: const [WorkOrderInput(name: 'Civil', date: '2026-06-10')],
    );
    expect(p.workOrders, hasLength(1));
    final body =
        verify(
              () => api.post('/projects', body: captureAny(named: 'body')),
            ).captured.single
            as Map;
    expect(body['name'], 'Lobby');
    expect(body['projectEngineer'], 'Eng');
    expect((body['workOrders'] as List).single, {
      'name': 'Civil',
      'date': '2026-06-10',
    });
  });

  test('addWorkOrder() POSTs to the project work-orders path', () async {
    when(
      () => api.post('/projects/p1/work-orders', body: any(named: 'body')),
    ).thenAnswer((_) async => workOrderJson());
    final w = await repo.addWorkOrder(
      'p1',
      const WorkOrderInput(name: 'Civil', date: '2026-06-10'),
    );
    expect(w.id, 'w1');
  });

  test('complete() POSTs to the complete path', () async {
    when(
      () => api.post('/projects/p1/complete'),
    ).thenAnswer((_) async => {...projectJson(), 'status': 'completed'});
    final p = await repo.complete('p1');
    expect(p.status.wire, 'completed');
  });
}
