import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/supervisors/supervisors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late ApiSupervisorRepository repo;

  setUp(() {
    api = MockApiClient();
    repo = ApiSupervisorRepository(api);
  });

  final supervisorJson = {
    'uid': 'sup1',
    'name': 'Ravi',
    'email': 'ravi@dcpl.test',
    'phone': '9876543210',
    'role': 'supervisor',
  };

  test('Supervisor.fromJson parses fields', () {
    final s = Supervisor.fromJson(supervisorJson);
    expect(s.uid, 'sup1');
    expect(s.name, 'Ravi');
    expect(s.email, 'ravi@dcpl.test');
    expect(s.phone, '9876543210');
  });

  test('list() GETs /supervisors and parses the page', () async {
    when(() => api.get('/supervisors', query: any(named: 'query')))
        .thenAnswer((_) async => {
              'items': [supervisorJson],
              'nextCursor': 'c1',
            });
    final result = await repo.list();
    expect(result.items, hasLength(1));
    expect(result.items.first.name, 'Ravi');
    expect(result.nextCursor, 'c1');
    verify(() => api.get('/supervisors', query: any(named: 'query'))).called(1);
  });

  test('listAll() pages through every supervisor until the cursor runs out', () async {
    final second = {...supervisorJson, 'uid': 'sup2', 'name': 'Asha'};
    when(() => api.get('/supervisors', query: any(named: 'query'))).thenAnswer((invocation) async {
      final query = invocation.namedArguments[#query] as Map?;
      if (query?['cursor'] == null) {
        return {'items': [supervisorJson], 'nextCursor': 'c1'};
      }
      return {'items': [second], 'nextCursor': null};
    });
    final all = await repo.listAll();
    expect(all.map((s) => s.uid), ['sup1', 'sup2']);
    verify(() => api.get('/supervisors', query: any(named: 'query'))).called(2);
  });

  test('create() POSTs /supervisors with the form body', () async {
    when(() => api.post('/supervisors', body: any(named: 'body')))
        .thenAnswer((_) async => supervisorJson);
    final s = await repo.create(name: 'Ravi', email: 'ravi@dcpl.test', phone: '9876543210');
    expect(s.email, 'ravi@dcpl.test');
    final body = verify(() => api.post('/supervisors', body: captureAny(named: 'body')))
        .captured
        .single as Map;
    expect(body['name'], 'Ravi');
    expect(body['email'], 'ravi@dcpl.test');
    expect(body['phone'], '9876543210');
  });
}
