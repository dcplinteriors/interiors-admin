import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/supervisors/supervisors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSupervisorRepository extends Mock implements SupervisorRepository {}

void main() {
  late MockSupervisorRepository repo;
  late SupervisorsController controller;

  const supervisor = Supervisor(
    uid: 'sup1',
    name: 'Ravi',
    email: 'ravi@dcpl.test',
    phone: '9876543210',
    projects: ['Lobby'],
  );

  setUp(() {
    repo = MockSupervisorRepository();
    controller = SupervisorsController(repo);
  });

  test('fetch() populates supervisors and cursor on success', () async {
    when(() => repo.list(cursor: any(named: 'cursor')))
        .thenAnswer((_) async => (items: [supervisor], nextCursor: 'c1'));
    await controller.fetch();
    expect(controller.supervisors, [supervisor]);
    expect(controller.hasMore, isTrue);
    expect(controller.isLoading.value, isFalse);
    expect(controller.error.value, isNull);
  });

  test('fetch() sets error message on ApiException', () async {
    when(() => repo.list(cursor: any(named: 'cursor'))).thenThrow(ApiException(500, 'boom'));
    await controller.fetch();
    expect(controller.error.value, 'boom');
    expect(controller.supervisors, isEmpty);
    expect(controller.isLoading.value, isFalse);
  });

  test('loadMore() appends the next page and clears the cursor', () async {
    const s2 = Supervisor(
      uid: 'sup2',
      name: 'Asha',
      email: 'asha@dcpl.test',
      phone: null,
      projects: [],
    );
    when(() => repo.list(cursor: null))
        .thenAnswer((_) async => (items: [supervisor], nextCursor: 'c1'));
    when(() => repo.list(cursor: 'c1'))
        .thenAnswer((_) async => (items: [s2], nextCursor: null));
    await controller.fetch();
    await controller.loadMore();
    expect(controller.supervisors, [supervisor, s2]);
    expect(controller.hasMore, isFalse);
  });

  test('create() prepends the new supervisor and returns it', () async {
    when(() => repo.create(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
        )).thenAnswer((_) async => supervisor);
    final created = await controller.create(
      name: 'Ravi',
      email: 'ravi@dcpl.test',
      phone: '9876543210',
    );
    expect(created, supervisor);
    expect(controller.supervisors.first, supervisor);
  });

  test('create() propagates ApiException (dialog surfaces it)', () async {
    when(() => repo.create(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
        )).thenThrow(ApiException(409, 'A user with this email already exists'));
    expect(
      () => controller.create(name: 'Ravi', email: 'ravi@dcpl.test'),
      throwsA(isA<ApiException>()),
    );
  });
}
