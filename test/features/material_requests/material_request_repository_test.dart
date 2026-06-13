import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/material_requests.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late ApiMaterialRequestRepository repo;

  setUp(() {
    api = MockApiClient();
    repo = ApiMaterialRequestRepository(api);
  });

  Map<String, dynamic> reqJson({String status = 'requested', String? vendor}) => {
        'id': 'r1',
        'project': 'p1',
        'orderBy': 'sup1',
        'poNumber': 'PO_26-27_06/0001',
        'jobNumber': 'JB_26-27_06/0001',
        'batchId': 'b1',
        'particular': 'Teak Ply',
        'make': 'Greenlam',
        'quantity': 12,
        'unit': 'PCS',
        'status': status,
        'createdAt': '2026-06-05T00:00:00.000Z',
        'expectedDate': null,
        'vendor': vendor,
        'remarks': null,
      };

  test('fromJson parses fields; quantityLabel + isPending', () {
    final r = MaterialRequest.fromJson(reqJson());
    expect(r.id, 'r1');
    expect(r.particular, 'Teak Ply');
    expect(r.quantityLabel, '12');
    expect(r.isPending, isTrue);
    expect(MaterialRequest.fromJson(reqJson(status: 'accepted')).isPending, isFalse);
  });

  test('quantityLabel keeps a decimal when present', () {
    final r = MaterialRequest.fromJson({...reqJson(), 'quantity': 2.5});
    expect(r.quantityLabel, '2.5');
  });

  test('list() parses the page + omits status/cursor query params when absent', () async {
    when(() => api.get('/material-requests', query: any(named: 'query')))
        .thenAnswer((_) async => {'items': [reqJson()], 'nextCursor': 'c1'});
    final res = await repo.list();
    expect(res.items, hasLength(1));
    expect(res.nextCursor, 'c1');
    final q = verify(() => api.get('/material-requests', query: captureAny(named: 'query')))
        .captured
        .single as Map;
    expect(q.containsKey('status'), isFalse);
    expect(q.containsKey('cursor'), isFalse);
  });

  test('list(status, cursor) sends both query params', () async {
    when(() => api.get('/material-requests', query: any(named: 'query')))
        .thenAnswer((_) async => {'items': [], 'nextCursor': null});
    await repo.list(status: 'accepted', cursor: 'c1');
    final q = verify(() => api.get('/material-requests', query: captureAny(named: 'query')))
        .captured
        .single as Map;
    expect(q['status'], 'accepted');
    expect(q['cursor'], 'c1');
  });

  test('accept() posts expectedDate/vendor/remarks and parses the result', () async {
    when(() => api.post('/material-requests/r1/accept', body: any(named: 'body')))
        .thenAnswer((_) async => reqJson(status: 'accepted', vendor: 'Hafele'));
    final r = await repo.accept('r1', expectedDate: '2026-06-20', vendor: 'Hafele', remarks: 'urgent');
    expect(r.status, 'accepted');
    final body = verify(() => api.post('/material-requests/r1/accept', body: captureAny(named: 'body')))
        .captured
        .single as Map;
    expect(body['expectedDate'], '2026-06-20');
    expect(body['vendor'], 'Hafele');
    expect(body['remarks'], 'urgent');
  });

  test('accept() omits an empty remarks', () async {
    when(() => api.post('/material-requests/r1/accept', body: any(named: 'body')))
        .thenAnswer((_) async => reqJson(status: 'accepted'));
    await repo.accept('r1', expectedDate: '2026-06-20', vendor: 'Hafele', remarks: '');
    final body = verify(() => api.post('/material-requests/r1/accept', body: captureAny(named: 'body')))
        .captured
        .single as Map;
    expect(body.containsKey('remarks'), isFalse);
  });

  test('decline() posts remarks when present', () async {
    when(() => api.post('/material-requests/r1/decline', body: any(named: 'body')))
        .thenAnswer((_) async => reqJson(status: 'declined'));
    final r = await repo.decline('r1', remarks: 'out of scope');
    expect(r.status, 'declined');
    final body = verify(() => api.post('/material-requests/r1/decline', body: captureAny(named: 'body')))
        .captured
        .single as Map;
    expect(body['remarks'], 'out of scope');
  });
}
