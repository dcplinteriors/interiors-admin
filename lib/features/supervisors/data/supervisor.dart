import 'package:dcpl_shared/models/models.dart';

/// A supervisor (the feature's view of a backend `users` record where role == supervisor).
class Supervisor {
  const Supervisor({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.workOrders = const [],
  });

  factory Supervisor.fromUser(User u) => Supervisor(
    uid: u.uid,
    name: u.name,
    email: u.email ?? '',
    phone: u.phone,
    workOrders: u.workOrders,
  );

  final String uid;
  final String name;
  final String email;
  final String? phone;

  /// Names of the work orders currently assigned to this supervisor (resolved by the backend).
  final List<String> workOrders;
}
