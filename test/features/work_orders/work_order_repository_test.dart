import 'package:dcpl_admin/features/work_orders/work_orders.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late ApiWorkOrderRepository repo;

  setUp(() {
    api = MockApiClient();
    repo = ApiWorkOrderRepository(DcplApi(api));
  });

  Map<String, dynamic> workOrderJson({String status = 'pending'}) => {
    'id': 'w1',
    'project': 'p1',
    'number': '26-27_0001/0001',
    'name': 'Civil',
    'date': '2026-06-10',
    'status': status,
    'supervisorId': status == 'pending' ? null : 's1',
  };

  test('list() forwards project + status filters', () async {
    when(() => api.get('/work-orders', query: any(named: 'query'))).thenAnswer(
      (_) async => {
        'items': [workOrderJson()],
        'nextCursor': null,
      },
    );
    await repo.list(project: 'p1', status: WorkOrderStatus.active);
    final query =
        verify(
              () => api.get('/work-orders', query: captureAny(named: 'query')),
            ).captured.single
            as Map;
    expect(query['project'], 'p1');
    expect(query['status'], 'active');
  });

  test('listAllForProject() pages through every work order', () async {
    var call = 0;
    when(() => api.get('/work-orders', query: any(named: 'query'))).thenAnswer((
      _,
    ) async {
      call++;
      return call == 1
          ? {
              'items': [workOrderJson()],
              'nextCursor': 'c1',
            }
          : {'items': <dynamic>[], 'nextCursor': null};
    });
    final all = await repo.listAllForProject('p1');
    expect(all, hasLength(1));
    verify(() => api.get('/work-orders', query: any(named: 'query'))).called(2);
  });

  test('assign() POSTs the supervisorId', () async {
    when(
      () => api.post('/work-orders/w1/assign', body: any(named: 'body')),
    ).thenAnswer((_) async => workOrderJson(status: 'active'));
    final w = await repo.assign('w1', 's1');
    expect(w.status, WorkOrderStatus.active);
    final body =
        verify(
              () => api.post(
                '/work-orders/w1/assign',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as Map;
    expect(body['supervisorId'], 's1');
  });

  test('unassign / complete / cancel POST to their paths', () async {
    when(
      () => api.post('/work-orders/w1/unassign'),
    ).thenAnswer((_) async => workOrderJson());
    when(
      () => api.post('/work-orders/w1/complete'),
    ).thenAnswer((_) async => workOrderJson(status: 'completed'));
    when(
      () => api.post('/work-orders/w1/cancel'),
    ).thenAnswer((_) async => workOrderJson(status: 'cancelled'));

    expect((await repo.unassign('w1')).status, WorkOrderStatus.pending);
    expect((await repo.complete('w1')).status, WorkOrderStatus.completed);
    expect((await repo.cancel('w1')).status, WorkOrderStatus.cancelled);
  });
}
