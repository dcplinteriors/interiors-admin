import 'package:dcpl_shared/models/models.dart';

/// A supervisor (the feature's view of a backend `users` record where role == supervisor).
///
/// Supervisors sign in with their phone number (a synthetic email runs underneath in
/// Firebase, but that's never shown), so phone — not email — is their identity here.
class Supervisor {
  const Supervisor({
    required this.uid,
    required this.name,
    required this.phone,
    this.workOrders = const [],
  });

  factory Supervisor.fromUser(User u) => Supervisor(
    uid: u.uid,
    name: u.name,
    phone: u.phone,
    workOrders: u.workOrders,
  );

  final String uid;
  final String name;
  final String? phone;

  /// Names of the work orders currently assigned to this supervisor (resolved by the backend).
  final List<String> workOrders;
}
