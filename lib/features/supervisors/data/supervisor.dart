/// A supervisor (mirrors the backend `users` record where role == supervisor).
class Supervisor {

  const Supervisor({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.projects = const [],
  });

  factory Supervisor.fromJson(Map<String, dynamic> json) => Supervisor(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      projects: (json['projects'] as List?)?.map((e) => e as String).toList() ?? const [],
    );
  final String uid;
  final String name;
  final String email;
  final String? phone;

  /// Names of the projects assigned to this supervisor (resolved by the backend).
  final List<String> projects;
}
