import 'package:dcpl_admin/features/material_requests/material_requests.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_app.dart';

class MockMaterialRequestRepository extends Mock implements MaterialRequestRepository {}

final request = const MaterialRequest(
  id: 'r1',
  project: 'p1',
  orderBy: 'sup1',
  poNumber: 'PO_26-27_06/0001',
  jobNumber: 'JB_26-27_06/0001',
  batchId: 'b1',
  particular: 'Teak Ply',
  make: 'Greenlam',
  quantity: 12,
  unit: 'PCS',
  status: 'requested',
  createdAt: '2026-06-05T00:00:00.000Z',
);

void main() {
  late MockMaterialRequestRepository repo;

  setUp(() {
    repo = MockMaterialRequestRepository();
    when(() => repo.list(status: any(named: 'status')))
        .thenAnswer((_) async => (items: <MaterialRequest>[], nextCursor: null));
    Get.put(MaterialRequestsController(repo));
  });
  tearDown(Get.reset);

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(testApp(dialogHost((_) => DeclineRequestDialog(request: request))));
    await tester.tap(find.text('__open__'));
    await tester.pumpAndSettle();
  }

  testWidgets('declines with a reason, closes, and shows a snackbar', (tester) async {
    when(() => repo.decline('r1', remarks: any(named: 'remarks')))
        .thenAnswer((_) async => request);

    await openDialog(tester);
    await tester.enterText(find.byType(TextField), 'Out of project scope');
    await tester.tap(find.widgetWithText(FilledButton, 'Decline'));
    await tester.pumpAndSettle();

    verify(() => repo.decline('r1', remarks: 'Out of project scope')).called(1);
    expect(find.byType(DeclineRequestDialog), findsNothing);
    expect(find.text('Request declined'), findsOneWidget);
  });

  testWidgets('declining without a reason is allowed (remarks optional)', (tester) async {
    when(() => repo.decline('r1', remarks: any(named: 'remarks')))
        .thenAnswer((_) async => request);

    await openDialog(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Decline'));
    await tester.pumpAndSettle();

    verify(() => repo.decline('r1', remarks: '')).called(1);
    expect(find.byType(DeclineRequestDialog), findsNothing);
  });
}
