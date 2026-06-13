import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/data/data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shows a request's attachments: photo thumbnails (tap to enlarge) + an audio note
/// player. Each object path is resolved to a short-lived signed URL on open.
class RequestAttachmentsDialog extends StatefulWidget {
  const RequestAttachmentsDialog({super.key, required this.attachments});

  final Attachments attachments;

  @override
  State<RequestAttachmentsDialog> createState() => _RequestAttachmentsDialogState();
}

class _RequestAttachmentsDialogState extends State<RequestAttachmentsDialog> {
  final AttachmentRepository _repo = Get.find();

  // Resolve each path to a signed URL once (memoized so rebuilds don't re-fetch).
  late final List<Future<String>> _photoUrls;
  Future<String>? _audioUrl;

  @override
  void initState() {
    super.initState();
    _photoUrls = widget.attachments.photos.map(_repo.downloadUrl).toList();
    final audio = widget.attachments.audio;
    if (audio != null) _audioUrl = _repo.downloadUrl(audio);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.attachments),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_photoUrls.isNotEmpty) ...[
                Text(l10n.photos, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final f in _photoUrls) _PhotoThumb(urlFuture: f)],
                ),
                const SizedBox(height: 16),
              ],
              if (_audioUrl != null) ...[
                Text(l10n.audioNote, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _AudioNote(urlFuture: _audioUrl!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close)),
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.urlFuture});
  final Future<String> urlFuture;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<String>(
      future: urlFuture,
      builder: (context, snap) {
        Widget child;
        if (snap.connectionState != ConnectionState.done) {
          child = const Center(child: SizedBox(
              height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)));
        } else if (snap.hasError || snap.data == null) {
          child = Icon(Icons.broken_image_outlined, color: scheme.error);
        } else {
          final url = snap.data!;
          child = InkWell(
            onTap: () => _openFull(context, url),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, w, p) => p == null
                  ? w
                  : const Center(child: SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              errorBuilder: (ctx, e, s) => Icon(Icons.broken_image_outlined, color: scheme.error),
            ),
          );
        }
        return Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        );
      },
    );
  }

  void _openFull(BuildContext context, String url) => showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      );
}

class _AudioNote extends StatefulWidget {
  const _AudioNote({required this.urlFuture});
  final Future<String> urlFuture;

  @override
  State<_AudioNote> createState() => _AudioNoteState();
}

class _AudioNoteState extends State<_AudioNote> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _sub;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _sub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playing = s == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle(String url) async {
    if (_playing) {
      await _player.pause();
    } else if (_player.state == PlayerState.paused) {
      await _player.resume(); // continue from where it was paused
    } else {
      await _player.play(UrlSource(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<String>(
      future: widget.urlFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snap.hasError || snap.data == null) {
          return Text(l10n.couldntLoadAttachment, style: TextStyle(color: scheme.error));
        }
        final url = snap.data!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _toggle(url),
                icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle),
              ),
              const SizedBox(width: 4),
              Icon(Icons.graphic_eq, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}
