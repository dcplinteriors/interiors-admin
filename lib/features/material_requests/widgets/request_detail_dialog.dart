import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/widgets/close_bills_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/edit_request_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/request_attachments_dialog.dart';
import 'package:dcpl_admin/features/material_requests/widgets/request_status_chip.dart';
import 'package:dcpl_shared/dcpl_shared.dart';
import 'package:flutter/material.dart';

/// Read-only detail for one material request — the single place the admin sees
/// **every** field, including ones the summary card/table omit (item number,
/// project/work-order numbers, and the admin's own vendor/expected-date/PO/
/// remarks, which are otherwise write-only). Opened by tapping a row or card, so
/// the desktop table and mobile card always expose the same complete picture.
///
/// The request is already fully loaded by the list (the backend denormalizes the
/// display names), so this needs no fetch — it just renders what it's handed.
class RequestDetailDialog extends StatefulWidget {
  const RequestDetailDialog({super.key, required this.request});

  final MaterialRequest request;

  @override
  State<RequestDetailDialog> createState() => _RequestDetailDialogState();
}

class _RequestDetailDialogState extends State<RequestDetailDialog> {
  /// The current item — updated in place after an admin edit.
  late MaterialRequest _request = widget.request;

  /// `Name (Number)` when a number is present, else the name (or an em dash).
  static String _nameWithNumber(String? name, String? number) {
    final n = name ?? 'N/A';
    return (number != null && number.isNotEmpty) ? '$n ($number)' : n;
  }

  Future<void> _edit() async {
    final updated = await showDialog<MaterialRequest>(
      context: context,
      builder: (_) => EditRequestDialog(request: _request),
    );
    if (updated != null && mounted) setState(() => _request = updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = _request;
    // Item details are correctable only before a vendor is assigned (backend-enforced).
    final canEdit =
        r.status == MaterialRequestStatus.requested ||
        r.status == MaterialRequestStatus.processing;
    // Vendor/expected/PO are "supply details"; remarks doubles as the decline
    // reason, so it's shown on its own (not under that heading) when it stands
    // alone — e.g. on a declined item with no vendor.
    final hasVendorInfo =
        _present(r.vendor) ||
        _present(r.expectedDate) ||
        _present(r.poNumber);

    return AlertDialog(
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      r.particular,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (canEdit)
                    TextButton.icon(
                      onPressed: _edit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(l10n.editItemAction),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RequestStatusChip(r.status),
              const SizedBox(height: 20),

              // Identity + item.
              _Row(l10n.colItemNumber, r.itemNumber),
              _Row(l10n.colMake, r.make),
              if (r.size.isNotEmpty) _Row(l10n.colSize, r.size),
              _Row(l10n.colQty, l10n.qtyWithUnit(r.quantityLabel, r.unit)),

              const _Gap(),
              // Where it sits + who/when.
              _Row(
                l10n.colProject,
                _nameWithNumber(r.projectName, r.projectNumber),
              ),
              _Row(
                l10n.colWorkOrder,
                _nameWithNumber(r.workOrderName, r.workOrderNumber),
              ),
              _Row(l10n.colClient, r.clientName ?? 'N/A'),
              _Row(l10n.colSupervisor, r.supervisorName ?? 'N/A'),
              _Row(l10n.colSubmitted, formatDate(r.createdAt)),

              // Admin's vendor/supply inputs — otherwise never shown again.
              if (hasVendorInfo) ...[
                const _Gap(),
                _Section(l10n.supplyDetailsSection),
                if (_present(r.vendor)) _Row(l10n.vendorLabel, r.vendor!),
                if (_present(r.expectedDate))
                  _Row(l10n.expectedDateLabel, formatDate(r.expectedDate!)),
                if (_present(r.poNumber)) _Row(l10n.poNumberLabel, r.poNumber!),
                if (_present(r.remarks)) _Row(l10n.remarksLabel, r.remarks!),
              ] else if (_present(r.remarks)) ...[
                const _Gap(),
                _Row(l10n.remarksLabel, r.remarks!),
              ],

              // Supervisor's close note (bills open in their own viewer below).
              if (_present(r.closeNote)) ...[
                const _Gap(),
                _Row(l10n.closeNoteTitle, r.closeNote!),
              ],

              if (r.attachments.isNotEmpty || r.billImages.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (r.attachments.isNotEmpty)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: Text(
                          '${l10n.attachments} '
                          '(${r.attachments.photos.length + (r.attachments.audio != null ? 1 : 0)})',
                        ),
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => RequestAttachmentsDialog(
                            attachments: r.attachments,
                          ),
                        ),
                      ),
                    if (r.billImages.isNotEmpty)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.receipt_long_outlined, size: 18),
                        label: Text(
                          '${l10n.billsTitle} (${r.billImages.length})',
                        ),
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => CloseBillsDialog(
                            billImages: r.billImages,
                            note: r.closeNote,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static bool _present(String? s) => s != null && s.isNotEmpty;
}

/// A label/value line — label in a fixed muted column, value selectable so the
/// admin can copy an item/PO number.
class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _Gap extends StatelessWidget {
  const _Gap();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 20);
}
