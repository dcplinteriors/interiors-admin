import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_shared/models/project.dart';

/// One page of projects plus the cursor for the next page (null = last page).
typedef ProjectPage = ({List<Project> items, String? nextCursor});

/// Port for project data. The controller depends on this abstraction (testable with a fake).
abstract class ProjectRepository {
  /// Lists projects (cursor-paginated), continuing after [cursor] (null = first page).
  Future<ProjectPage> list({String? cursor});
  Future<Project> create({
    required String particular,
    required String clientName,
    required String date,
  });
  Future<Project> assignSupervisor(String projectId, String supervisorId);
}

class ApiProjectRepository implements ProjectRepository {
  ApiProjectRepository(this._api);

  final ApiClient _api;

  @override
  Future<ProjectPage> list({String? cursor}) async {
    final data = await _api.get(
      '/projects',
      query: {'cursor': ?cursor},
    ) as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => Project.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: items, nextCursor: data['nextCursor'] as String?);
  }

  @override
  Future<Project> create({
    required String particular,
    required String clientName,
    required String date,
  }) async {
    final data = await _api.post('/projects', body: {
      'particular': particular,
      'clientName': clientName,
      'date': date,
    });
    return Project.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Project> assignSupervisor(String projectId, String supervisorId) async {
    final data = await _api.post('/projects/$projectId/assign', body: {
      'supervisorId': supervisorId,
    });
    return Project.fromJson(data as Map<String, dynamic>);
  }
}
