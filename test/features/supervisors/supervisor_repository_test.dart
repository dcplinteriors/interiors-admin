import 'package:dcpl_admin/features/supervisors/supervisors.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late ApiSupervisorRepository repo;

  setUp(() {
    api = MockApiClient();
    repo = ApiSupervisorRepository(DcplApi(api));
  });

  final supervisorJson = {
    'uid': 'sup1',
    'name': 'Ravi',
    'email': 'ravi@dcpl.test',
    'phone': '9876543210',
    'role': 'supervisor',
    'workOrders': ['Lobby'],
  };

  test('list() GETs /supervisors and maps users to supervisors', () async {
    when(() => api.get('/supervisors', query: any(named: 'query'))).thenAnswer(
      (_) async => {
        'items': [supervisorJson],
        'nextCursor': 'c1',
      },
    );
    final result = await repo.list();
    expect(result.items, hasLength(1));
    expect(result.items.first.name, 'Ravi');
    expect(result.items.first.workOrders, ['Lobby']);
    expect(result.nextCursor, 'c1');
  });

  test(
    'listAll() pages through every supervisor until the cursor runs out',
    () async {
      final second = {...supervisorJson, 'uid': 'sup2', 'name': 'Asha'};
      when(
        () => api.get('/supervisors', query: any(named: 'query')),
      ).thenAnswer((invocation) async {
        final query = invocation.namedArguments[#query] as Map?;
        if (query?['cursor'] == null) {
          return {
            'items': [supervisorJson],
            'nextCursor': 'c1',
          };
        }
        return {
          'items': [second],
          'nextCursor': null,
        };
      });
      final all = await repo.listAll();
      expect(all.map((s) => s.uid), ['sup1', 'sup2']);
      verify(
        () => api.get('/supervisors', query: any(named: 'query')),
      ).called(2);
    },
  );

  test(
    'create() POSTs name + phone and returns the supervisor + temp password',
    () async {
      when(() => api.post('/supervisors', body: any(named: 'body'))).thenAnswer(
        (_) async => {...supervisorJson, 'tempPassword': 'Temp-1234'},
      );
      final result = await repo.create(name: 'Ravi', phone: '9876543210');
      expect(result.supervisor.name, 'Ravi');
      expect(result.supervisor.phone, '9876543210');
      expect(result.tempPassword, 'Temp-1234');
      final body =
          verify(
                () => api.post('/supervisors', body: captureAny(named: 'body')),
              ).captured.single
              as Map;
      expect(body, {'name': 'Ravi', 'phone': '9876543210'});
    },
  );

  test('resetPassword() POSTs and returns the new temp password', () async {
    when(
      () => api.post('/supervisors/sup1/reset-password'),
    ).thenAnswer((_) async => {'tempPassword': 'New-5678'});
    final pw = await repo.resetPassword('sup1');
    expect(pw, 'New-5678');
    verify(() => api.post('/supervisors/sup1/reset-password')).called(1);
  });
}
