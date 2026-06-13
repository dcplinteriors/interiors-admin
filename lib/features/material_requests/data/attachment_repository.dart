import 'package:dcpl_admin/core/core.dart';

/// Resolves a stored attachment object path to a short-lived signed read URL
/// (the backend `/uploads/download-url` endpoint). Clients never touch Storage directly.
abstract class AttachmentRepository {
  Future<String> downloadUrl(String path);
}

class ApiAttachmentRepository implements AttachmentRepository {
  ApiAttachmentRepository(this._api);

  final ApiClient _api;

  @override
  Future<String> downloadUrl(String path) async {
    final data = await _api.post('/uploads/download-url', body: {'path': path});
    return (data as Map<String, dynamic>)['url'] as String;
  }
}
