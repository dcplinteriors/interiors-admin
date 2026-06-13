import 'dart:async';

import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/material_requests.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_app.dart';

class MockMaterialRequestRepository extends Mock implements MaterialRequestRepository {}

MaterialRequest req(String status, {String? vendor}) => MaterialRequest(
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
      status: status,
      createdAt: '2026-06-05T00:00:00.000Z',
      vendor: vendor,
      // Names are resolved by the backend and arrive on the request.
      clientName: 'Acme',
      supervisorName: 'Ravi',
    );

void main() {
  late MockMaterialRequestRepository repo;

  setUp(() {
    repo = MockMaterialRequestRepository();
  });
  tearDown(Get.reset);

  Future<void> pumpView(WidgetTester tester) async {
    // Wide viewport so the 9-column table + 5-segment filter aren't scrolled off-screen.
    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Get.put(MaterialRequestsController(repo));
    await tester.pumpWidget(testApp(const Scaffold(body: RequestsView())));
  }

  testWidgets('shows a spinner while loading', (tester) async {
    final pending = Completer<RequestPage>();
    when(() => repo.list(status: any(named: 'status'))).thenAnswer((_) => pending.future);

    await pumpView(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete((items: <MaterialRequest>[], nextCursor: null));
    await tester.pumpAndSettle();
  });

  testWidgets('shows the positive "all caught up" empty state on the review queue',
      (tester) async {
    when(() => repo.list(status: any(named: 'status')))
        .thenAnswer((_) async => (items: <MaterialRequest>[], nextCursor: null));

    await pumpView(tester);
    await tester.pumpAndSettle();
    // Default tab is "All"; switch to the review queue to get the positive empty state.
    await tester.tap(find.text('To review'));
    await tester.pumpAndSettle();

    expect(find.text("You're all caught up"), findsOneWidget);
  });

  testWidgets('shows the error state', (tester) async {
    when(() => repo.list(status: any(named: 'status'))).thenThrow(ApiException(500, 'service down'));

    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load requests"), findsOneWidget);
    expect(find.text('service down'), findsOneWidget);
  });

  testWidgets('renders a pending row with resolved names and action buttons', (tester) async {
    when(() => repo.list(status: any(named: 'status')))
        .thenAnswer((_) async => (items: [req('requested')], nextCursor: null));

    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text('Teak Ply'), findsOneWidget);
    expect(find.text('Acme'), findsOneWidget); // resolved client name
    expect(find.text('Ravi'), findsOneWidget); // resolved supervisor name
    expect(find.text('12 PCS'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Accept'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Decline'), findsOneWidget);
  });

  testWidgets('a terminal (accepted) row shows the vendor instead of buttons', (tester) async {
    when(() => repo.list(status: any(named: 'status')))
        .thenAnswer((_) async => (items: [req('accepted', vendor: 'Hafele')], nextCursor: null));

    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text('→ Hafele'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Accept'), findsNothing);
  });

  testWidgets('tapping Accept opens the accept dialog', (tester) async {
    when(() => repo.list(status: any(named: 'status')))
        .thenAnswer((_) async => (items: [req('requested')], nextCursor: null));

    await pumpView(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
    await tester.pumpAndSettle();

    expect(find.byType(AcceptRequestDialog), findsOneWidget);
  });

  testWidgets('changing the filter refetches with the new status', (tester) async {
    when(() => repo.list(status: any(named: 'status')))
        .thenAnswer((_) async => (items: <MaterialRequest>[], nextCursor: null));

    await pumpView(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Accepted'));
    await tester.pumpAndSettle();

    verify(() => repo.list(status: 'accepted')).called(1);
  });
}
