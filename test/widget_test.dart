import 'package:dcpl_admin/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('route paths are defined', () {
    expect(AppRoutes.login, '/login');
    expect(AppRoutes.projects, '/projects');
    expect(AppRoutes.supervisors, '/supervisors');
    expect(AppRoutes.requests, '/requests');
  });
}
