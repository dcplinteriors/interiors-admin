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
    await tester.pumpWidget(testApp(dialogHost((_) => AcceptRequestDialog(request: request))));
    await tester.tap(find.text('__open__'));
    await tester.pumpAndSettle();
  }

  testWidgets('requires an expected date and a vendor', (tester) async {
    await openDialog(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Accept request'));
    await tester.pumpAndSettle();

    expect(find.text('Select an expected date'), findsOneWidget);
    expect(find.text('Enter a vendor'), findsOneWidget);
    verifyNever(() => repo.accept(any(),
        expectedDate: any(named: 'expectedDate'),
        vendor: any(named: 'vendor'),
        remarks: any(named: 'remarks')));
  });

  testWidgets('accepts with a picked date + vendor, closes, and shows a snackbar', (tester) async {
    when(() => repo.accept('r1',
            expectedDate: any(named: 'expectedDate'),
            vendor: any(named: 'vendor'),
            remarks: any(named: 'remarks')))
        .thenAnswer((_) async => request);

    await openDialog(tester);

    // Pick a date (defaults to today via the picker's OK).
    await tester.tap(find.text('Select a date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Hafele Traders');
    await tester.tap(find.widgetWithText(FilledButton, 'Accept request'));
    await tester.pumpAndSettle();

    verify(() => repo.accept('r1',
        expectedDate: any(named: 'expectedDate'),
        vendor: 'Hafele Traders',
        remarks: any(named: 'remarks'))).called(1);
    expect(find.byType(AcceptRequestDialog), findsNothing);
    expect(find.text('Request accepted'), findsOneWidget);
  });
}
