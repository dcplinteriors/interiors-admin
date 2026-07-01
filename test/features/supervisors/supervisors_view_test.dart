import 'dart:async';

import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/supervisors/supervisors.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_app.dart';

class MockSupervisorRepository extends Mock implements SupervisorRepository {}

void main() {
  late MockSupervisorRepository repo;

  setUp(() {
    repo = MockSupervisorRepository();
  });
  tearDown(Get.reset);

  Future<void> pumpView(WidgetTester tester) async {
    Get.put(SupervisorsController(repo));
    await tester.pumpWidget(testApp(const Scaffold(body: SupervisorsView())));
  }

  testWidgets('shows a spinner while loading', (tester) async {
    final pending = Completer<Page<Supervisor>>();
    when(
      () => repo.list(cursor: any(named: 'cursor')),
    ).thenAnswer((_) => pending.future);

    await pumpView(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(const Page(items: <Supervisor>[], nextCursor: null));
    await tester.pumpAndSettle();
  });

  testWidgets('shows the empty state when there are no supervisors', (
    tester,
  ) async {
    when(() => repo.list(cursor: any(named: 'cursor'))).thenAnswer(
      (_) async => const Page(items: <Supervisor>[], nextCursor: null),
    );

    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text('No supervisors yet'), findsOneWidget);
    // Two CTAs: the molten header button and the empty-state button.
    expect(
      find.widgetWithText(GradientButton, 'New supervisor'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'New supervisor'), findsOneWidget);
  });

  testWidgets('shows the error state then recovers on retry', (tester) async {
    when(
      () => repo.list(cursor: any(named: 'cursor')),
    ).thenThrow(ApiException(500, 'service down'));

    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load supervisors"), findsOneWidget);
    expect(find.text('service down'), findsOneWidget);

    when(() => repo.list(cursor: any(named: 'cursor'))).thenAnswer(
      (_) async => const Page(
        items: [Supervisor(uid: '1', name: 'Ravi', phone: null)],
        nextCursor: null,
      ),
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Ravi'), findsOneWidget);
  });

  testWidgets(
    'renders rows with assigned projects and a muted em-dash for a missing phone',
    (tester) async {
      when(() => repo.list(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => const Page(
          items: [
            Supervisor(
              uid: '1',
              name: 'Ravi',
              phone: '999',
              workOrders: ['Lobby'],
            ),
            Supervisor(uid: '2', name: 'Meera', phone: null),
          ],
          nextCursor: null,
        ),
      );

      await pumpView(tester);
      await tester.pumpAndSettle();

      expect(find.text('Ravi'), findsOneWidget);
      expect(find.text('Meera'), findsOneWidget);
      expect(find.text('999'), findsOneWidget);
      expect(find.text('Lobby'), findsOneWidget); // Ravi's assigned work order
      // Meera has no phone AND no work orders → two muted dashes.
      expect(find.text('—'), findsNWidgets(2));
    },
  );

  testWidgets('opens the create dialog from the header button', (tester) async {
    when(() => repo.list(cursor: any(named: 'cursor'))).thenAnswer(
      (_) async => const Page(items: <Supervisor>[], nextCursor: null),
    );

    await pumpView(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'New supervisor').first);
    await tester.pumpAndSettle();

    expect(find.byType(CreateSupervisorDialog), findsOneWidget);
  });

  testWidgets('reset password: confirms, then shows the new credentials', (
    tester,
  ) async {
    when(() => repo.list(cursor: any(named: 'cursor'))).thenAnswer(
      (_) async => const Page(
        items: [Supervisor(uid: '1', name: 'Ravi', phone: '9876543210')],
        nextCursor: null,
      ),
    );
    when(() => repo.resetPassword('1')).thenAnswer((_) async => 'New-5678');

    await pumpView(tester);
    await tester.pumpAndSettle();

    // The row action is hover-revealed but still hit-testable.
    await tester.tap(find.byIcon(Icons.lock_reset).first);
    await tester.pumpAndSettle();

    expect(find.text('Reset password?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
    await tester.pumpAndSettle();

    verify(() => repo.resetPassword('1')).called(1);
    expect(find.text('New temporary password'), findsOneWidget);
    expect(find.text('New-5678'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    expect(find.text('New temporary password'), findsNothing);
  });
}
