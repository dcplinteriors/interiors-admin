import 'package:dcpl_admin/core/core.dart';

/// Resolves a stored attachment object path to a short-lived signed read URL
/// (the backend `/uploads/download-url` endpoint). Clients never touch Storage directly.
abstract class AttachmentRepository {
  Future<String> downloadUrl(String path);
}

/// Caches each path→URL resolution for [_ttl], so reopening a dialog (or the same
/// image appearing in both the detail dialog and a viewer) doesn't re-hit the
/// backend every time. The stable URL is also what lets `Image.network` and the
/// browser reuse the already-downloaded bytes instead of refetching on each open.
///
/// Backend read URLs are valid for 1 hour; [_ttl] expires our cache well short of
/// that so a cached link never strands a viewer on an expired URL. The repo is a
/// session singleton (registered with `Get.lazyPut`), so the cache lives as long
/// as the app does.
class ApiAttachmentRepository implements AttachmentRepository {
  ApiAttachmentRepository(this._api);

  final DcplApi _api;

  static const _ttl = Duration(minutes: 50);
  final Map<String, _CachedUrl> _cache = {};

  @override
  Future<String> downloadUrl(String path) {
    final now = DateTime.now();
    final hit = _cache[path];
    if (hit != null && now.difference(hit.at) < _ttl) return hit.future;

    // Cache the in-flight future (so concurrent callers share one request), keyed
    // by path. Drop it on failure so a transient error isn't replayed on reopen.
    final future = _api.uploads.downloadUrl(path);
    final entry = _CachedUrl(future, now);
    _cache[path] = entry;
    future.then(
      (_) {},
      onError: (_) {
        if (identical(_cache[path], entry)) _cache.remove(path);
      },
    );
    return future;
  }
}

class _CachedUrl {
  _CachedUrl(this.future, this.at);

  final Future<String> future;
  final DateTime at;
}
