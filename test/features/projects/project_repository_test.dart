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
    repo = ApiProjectRepository(api);
  });

  Map<String, dynamic> projectJson({String? supervisorId}) => {
        'id': 'p1',
        'particular': 'Lobby',
        'clientName': 'Acme',
        'date': '2026-06-06',
        'po': 'PO_26-27_06/0001',
        'supervisorId': supervisorId,
        'status': 'active',
        'createdAt': '2026-06-06T00:00:00.000Z',
      };

  test('Project.fromJson parses fields and isAssigned', () {
    final p = Project.fromJson(projectJson(supervisorId: 'sup1'));
    expect(p.id, 'p1');
    expect(p.particular, 'Lobby');
    expect(p.po, 'PO_26-27_06/0001');
    expect(p.isAssigned, isTrue);
    expect(Project.fromJson(projectJson()).isAssigned, isFalse);
  });

  test('list() GETs /projects and parses the page', () async {
    when(() => api.get('/projects', query: any(named: 'query')))
        .thenAnswer((_) async => {
              'items': [projectJson()],
              'nextCursor': 'c1',
            });
    final result = await repo.list();
    expect(result.items, hasLength(1));
    expect(result.items.first.particular, 'Lobby');
    expect(result.nextCursor, 'c1');
    verify(() => api.get('/projects', query: any(named: 'query'))).called(1);
  });

  test('list(cursor:) forwards the cursor in the query', () async {
    when(() => api.get('/projects', query: any(named: 'query')))
        .thenAnswer((_) async => {'items': <dynamic>[], 'nextCursor': null});
    await repo.list(cursor: 'abc');
    final query = verify(() => api.get('/projects', query: captureAny(named: 'query')))
        .captured
        .single as Map;
    expect(query['cursor'], 'abc');
  });

  test('create() POSTs /projects with the form body and parses the result', () async {
    when(() => api.post('/projects', body: any(named: 'body')))
        .thenAnswer((_) async => projectJson());
    final p = await repo.create(particular: 'Lobby', clientName: 'Acme', date: '2026-06-06');
    expect(p.po, 'PO_26-27_06/0001');
    final body = verify(() => api.post('/projects', body: captureAny(named: 'body')))
        .captured
        .single as Map;
    expect(body['particular'], 'Lobby');
    expect(body['clientName'], 'Acme');
    expect(body['date'], '2026-06-06');
  });

  test('assignSupervisor() POSTs to the assign path with supervisorId', () async {
    when(() => api.post('/projects/p1/assign', body: any(named: 'body')))
        .thenAnswer((_) async => projectJson(supervisorId: 'sup1'));
    final p = await repo.assignSupervisor('p1', 'sup1');
    expect(p.supervisorId, 'sup1');
    final body = verify(() => api.post('/projects/p1/assign', body: captureAny(named: 'body')))
        .captured
        .single as Map;
    expect(body['supervisorId'], 'sup1');
  });
}
