import 'package:dcpl_admin/features/material_requests/material_requests.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late ApiMaterialRequestRepository repo;

  setUp(() {
    api = MockApiClient();
    repo = ApiMaterialRequestRepository(DcplApi(api));
  });

  Map<String, dynamic> requestJson({String status = 'requested'}) => {
    'id': 'mr1',
    'itemNumber': '26-27_0001/0001/0001',
    'workOrder': 'w1',
    'project': 'p1',
    'orderBy': 's1',
    'batchId': 'b1',
    'particular': 'Hinges',
    'make': 'Hettich',
    'size': '4 inch',
    'quantity': 2,
    'unit': 'PCS',
    'status': status,
    'createdAt': '2026-06-06T00:00:00.000Z',
    'attachments': {'photos': <String>[]},
  };

  test(
    'list() forwards status/project/workOrder filters and parses the page',
    () async {
      when(
        () => api.get('/material-requests', query: any(named: 'query')),
      ).thenAnswer(
        (_) async => {
          'items': [requestJson()],
          'nextCursor': null,
        },
      );
      await repo.list(
        status: MaterialRequestStatus.requested,
        project: 'p1',
        workOrder: 'w1',
      );
      final query =
          verify(
                () => api.get(
                  '/material-requests',
                  query: captureAny(named: 'query'),
                ),
              ).captured.single
              as Map;
      expect(query['status'], 'requested');
      expect(query['project'], 'p1');
      expect(query['workOrder'], 'w1');
    },
  );

  test('accept() POSTs to the accept path (→ processing)', () async {
    when(
      () => api.post('/material-requests/mr1/accept', body: any(named: 'body')),
    ).thenAnswer((_) async => requestJson(status: 'processing'));
    final r = await repo.accept('mr1', remarks: 'ok');
    expect(r.status, MaterialRequestStatus.processing);
    final body =
        verify(
              () => api.post(
                '/material-requests/mr1/accept',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as Map;
    expect(body['remarks'], 'ok');
  });

  test(
    'assignVendor() POSTs vendor details to the assign-vendor path',
    () async {
      when(
        () => api.post(
          '/material-requests/mr1/assign-vendor',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => requestJson(status: 'accepted'));
      final r = await repo.assignVendor(
        'mr1',
        expectedDate: '2026-06-20',
        vendorId: 'v1',
        poNumber: 'PO-1',
      );
      expect(r.status, MaterialRequestStatus.accepted);
      final body =
          verify(
                () => api.post(
                  '/material-requests/mr1/assign-vendor',
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as Map;
      expect(body['expectedDate'], '2026-06-20');
      expect(body['vendorId'], 'v1');
      expect(body['poNumber'], 'PO-1');
    },
  );

  test('decline() POSTs the required reason', () async {
    when(
      () =>
          api.post('/material-requests/mr1/decline', body: any(named: 'body')),
    ).thenAnswer((_) async => requestJson(status: 'declined'));
    await repo.decline('mr1', 'no stock');
    final body =
        verify(
              () => api.post(
                '/material-requests/mr1/decline',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as Map;
    expect(body['remarks'], 'no stock');
  });
}
