import 'package:dcpl_admin/features/material_requests/material_requests.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMaterialRequestRepository extends Mock
    implements MaterialRequestRepository {}

void main() {
  late MockMaterialRequestRepository repo;
  late RequestsBadgeController controller;

  setUp(() {
    repo = MockMaterialRequestRepository();
    controller = RequestsBadgeController(repo);
  });

  test('refreshCount requests the actionable statuses in one call', () async {
    when(
      () => repo.count(statuses: any(named: 'statuses')),
    ).thenAnswer((_) async => 7);
    await controller.refreshCount();
    expect(controller.count.value, 7);
    verify(
      () => repo.count(
        statuses: [
          MaterialRequestStatus.requested,
          MaterialRequestStatus.processing,
        ],
      ),
    ).called(1);
  });

  test('refreshCount swallows ApiException, keeping the last value', () async {
    when(
      () => repo.count(statuses: any(named: 'statuses')),
    ).thenAnswer((_) async => 7);
    await controller.refreshCount();
    expect(controller.count.value, 7);

    when(
      () => repo.count(statuses: any(named: 'statuses')),
    ).thenThrow(ApiException(500, 'boom'));
    await controller.refreshCount();
    expect(controller.count.value, 7);
  });
}
