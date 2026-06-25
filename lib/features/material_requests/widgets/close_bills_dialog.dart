import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/data/data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shows a closed item's bill image(s) (tap to enlarge) and the supervisor's optional
/// close note. Each object path is resolved to a short-lived signed URL on open.
class CloseBillsDialog extends StatefulWidget {
  const CloseBillsDialog({super.key, required this.billImages, this.note});

  final List<String> billImages;
  final String? note;

  @override
  State<CloseBillsDialog> createState() => _CloseBillsDialogState();
}

class _CloseBillsDialogState extends State<CloseBillsDialog> {
  final AttachmentRepository _repo = Get.find();
  late final List<Future<String>> _urls;

  @override
  void initState() {
    super.initState();
    _urls = widget.billImages.map(_repo.downloadUrl).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final note = widget.note?.trim() ?? '';
    return AlertDialog(
      title: Text(l10n.billsTitle),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (note.isNotEmpty) ...[
                Text(l10n.closeNoteTitle, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(note),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final f in _urls) _BillPhoto(urlFuture: f)],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _BillPhoto extends StatelessWidget {
  const _BillPhoto({required this.urlFuture});
  final Future<String> urlFuture;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<String>(
      future: urlFuture,
      builder: (context, snap) {
        Widget child;
        if (snap.connectionState != ConnectionState.done) {
          child = const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
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
                  : const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
              errorBuilder: (ctx, e, s) =>
                  Icon(Icons.broken_image_outlined, color: scheme.error),
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
      child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
    ),
  );
}
