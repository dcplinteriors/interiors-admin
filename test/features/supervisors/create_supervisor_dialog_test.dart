import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/supervisors/supervisors.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter/services.dart';
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

  void stubCreate({String tempPassword = 'Temp-1234'}) {
    when(
      () => repo.create(name: any(named: 'name'), phone: any(named: 'phone')),
    ).thenAnswer(
      (_) async => (
        supervisor: const Supervisor(
          uid: '1',
          name: 'Ravi',
          phone: '9876543210',
        ),
        tempPassword: tempPassword,
      ),
    );
  }

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
    required String phone,
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), name);
    await tester.enterText(fields.at(1), phone);
  }

  testWidgets('validates required name and phone', (tester) async {
    await openDialog(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Enter a phone number'), findsOneWidget);
    verifyNever(
      () => repo.create(name: any(named: 'name'), phone: any(named: 'phone')),
    );
  });

  testWidgets('rejects a phone that is not 10 digits', (tester) async {
    await openDialog(tester);
    await fill(tester, name: 'Ravi', phone: '12345');

    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a 10-digit phone number'), findsOneWidget);
    verifyNever(
      () => repo.create(name: any(named: 'name'), phone: any(named: 'phone')),
    );
  });

  testWidgets(
    'on success shows the one-time credentials, then Done returns the supervisor',
    (tester) async {
      stubCreate();
      Supervisor? popped;
      await tester.pumpWidget(testApp(const Scaffold()));
      // Open the dialog directly so we can read its pop value.
      final ctx = tester.element(find.byType(Scaffold));
      final future = showDialog<Supervisor>(
        context: ctx,
        builder: (_) => const CreateSupervisorDialog(),
      ).then((v) => popped = v);
      await tester.pumpAndSettle();

      await fill(tester, name: 'Ravi', phone: '9876543210');
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      verify(() => repo.create(name: 'Ravi', phone: '9876543210')).called(1);
      // Credentials panel is shown (not closed).
      expect(find.byType(CreateSupervisorDialog), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('Temp-1234'), findsOneWidget);
      expect(
        find.text("Save these now — the password won't be shown again."),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();
      await future;

      expect(find.byType(CreateSupervisorDialog), findsNothing);
      expect(popped?.uid, '1');
    },
  );

  testWidgets('copies the phone + password pair to the clipboard', (tester) async {
    stubCreate();
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );

    await openDialog(tester);
    await fill(tester, name: 'Ravi', phone: '9876543210');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    // A single button copies both, labelled.
    await tester.tap(find.widgetWithText(FilledButton, 'Copy phone & password'));
    await tester.pumpAndSettle();

    expect(
      clipboardText,
      'Phone: +91 98765 43210\nTemporary password: Temp-1234',
    );
    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('shows the backend message and stays open on error', (
    tester,
  ) async {
    when(
      () => repo.create(name: any(named: 'name'), phone: any(named: 'phone')),
    ).thenThrow(ApiException(409, 'phone already in use'));

    await openDialog(tester);
    await fill(tester, name: 'Ravi', phone: '9876543210');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateSupervisorDialog), findsOneWidget);
    expect(find.text('phone already in use'), findsOneWidget);
  });
}
