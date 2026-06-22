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
    // The controller fetches supervisors on init; keep that quiet for dialog tests.
    when(() => repo.list(cursor: any(named: 'cursor'))).thenAnswer(
      (_) async => const Page(items: <Supervisor>[], nextCursor: null),
    );
    Get.put(SupervisorsController(repo));
  });
  tearDown(Get.reset);

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(dialogHost((_) => const CreateSupervisorDialog())),
    );
    await tester.tap(find.text('__open__'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester, {
    required String name,
    required String email,
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), name);
    await tester.enterText(fields.at(1), email);
  }

  testWidgets('validates required name and email', (tester) async {
    await openDialog(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Send invite'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Enter an email address'), findsOneWidget);
    verifyNever(
      () => repo.create(
        name: any(named: 'name'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
      ),
    );
  });

  testWidgets('rejects an invalid email format', (tester) async {
    await openDialog(tester);
    await fill(tester, name: 'Ravi', email: 'not-an-email');

    await tester.tap(find.widgetWithText(FilledButton, 'Send invite'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('submits a lowercased email, closes, and shows a snackbar', (
    tester,
  ) async {
    when(
      () => repo.create(
        name: any(named: 'name'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
      ),
    ).thenAnswer(
      (_) async => const Supervisor(
        uid: '1',
        name: 'Ravi',
        email: 'ravi@x.com',
        phone: null,
      ),
    );

    await openDialog(tester);
    await fill(tester, name: 'Ravi', email: 'Ravi@X.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Send invite'));
    await tester.pumpAndSettle();

    verify(
      () => repo.create(name: 'Ravi', email: 'ravi@x.com', phone: ''),
    ).called(1);
    expect(find.byType(CreateSupervisorDialog), findsNothing);
    expect(find.text('Invite sent to ravi@x.com'), findsOneWidget);
  });

  testWidgets('keeps the dialog open and flags the field on a 409', (
    tester,
  ) async {
    when(
      () => repo.create(
        name: any(named: 'name'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
      ),
    ).thenThrow(ApiException(409, 'A user with this email already exists'));

    await openDialog(tester);
    await fill(tester, name: 'Ravi', email: 'ravi@x.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Send invite'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateSupervisorDialog), findsOneWidget);
    expect(find.text('That email already has an account.'), findsOneWidget);
    expect(find.text('Already in use'), findsOneWidget);
  });

  testWidgets('shows the backend message on a non-409 error', (tester) async {
    when(
      () => repo.create(
        name: any(named: 'name'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
      ),
    ).thenThrow(ApiException(500, 'server boom'));

    await openDialog(tester);
    await fill(tester, name: 'Ravi', email: 'ravi@x.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Send invite'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateSupervisorDialog), findsOneWidget);
    expect(find.text('server boom'), findsOneWidget);
  });
}
