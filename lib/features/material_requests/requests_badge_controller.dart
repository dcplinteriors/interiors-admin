import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/data/material_request_repository.dart';
import 'package:dcpl_shared/models/models.dart';
import 'package:get/get.dart';

/// Holds the count of items awaiting an admin action for the Requests nav badge —
/// `requested` (needs accept/decline) plus `processing` (needs a vendor assigned).
///
/// Server-truth (the backend count endpoint), not derived from the loaded list. The home shell
/// loads it when the nav appears (post-login); the requests controller refreshes it after the
/// admin accepts/declines/assigns-a-vendor (each changes the actionable queue). Permanent (app
/// session).
class RequestsBadgeController extends GetxController {
  RequestsBadgeController(this._repo);

  final MaterialRequestRepository _repo;

  /// Statuses that still need an admin decision (the badge total).
  static const _actionable = [
    MaterialRequestStatus.requested,
    MaterialRequestStatus.processing,
  ];

  final count = 0.obs;

  /// Fetches the current actionable count ([_actionable]) in a single call (the count
  /// endpoint's `statusIn`). Best-effort — keeps the last value on error.
  Future<void> refreshCount() async {
    try {
      count.value = await _repo.count(statuses: _actionable);
    } on ApiException catch (_) {
      // Leave the last known value.
    }
  }
}
