import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'domain/models.dart';
import 'domain/receipts.dart';
import 'domain/settlements.dart';
import 'importers/biedronka_parser.dart';
import 'state/household_controller.dart';
import 'ui/common_widgets.dart';
import 'ui/dashboard_screen.dart';
import 'ui/receipt_detail_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SplitkaApp());
}

class SplitkaApp extends StatefulWidget {
  const SplitkaApp({super.key, HouseholdController? controller})
    : _injectedController = controller;

  final HouseholdController? _injectedController;

  @override
  State<SplitkaApp> createState() => _SplitkaAppState();
}

class _SplitkaAppState extends State<SplitkaApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final HouseholdController _controller;
  String? _openReceiptId;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _controller = widget._injectedController ?? HouseholdController();
    unawaited(_controller.boot());
  }

  @override
  void dispose() {
    if (widget._injectedController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      title: 'Splitka',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (!_controller.loaded) {
            return const _LoadingScreen();
          }

          final openReceipt = _findReceipt(_openReceiptId);

          if (_openReceiptId != null && openReceipt == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _openReceiptId = null);
              }
            });
          }

          if (openReceipt != null) {
            return ReceiptDetailScreen(
              key: ValueKey(openReceipt.id),
              household: _controller.household,
              receipt: openReceipt,
              onBack: () => setState(() => _openReceiptId = null),
              onSetPayer: (payerId) => unawaited(
                _updateReceipt(
                  openReceipt.id,
                  (receipt) => receipt.copyWith(payerId: payerId),
                ),
              ),
              onAssignAllProducts: () =>
                  unawaited(_assignAllProducts(openReceipt.id)),
              onClearProductAssignments: () =>
                  unawaited(_clearProductAssignments(openReceipt.id)),
              onSetItemParticipants: (itemId, participantIds) => unawaited(
                _setItemParticipants(openReceipt.id, itemId, participantIds),
              ),
              onToggleItemParticipant: (itemId, personId) => unawaited(
                _toggleItemParticipant(openReceipt.id, itemId, personId),
              ),
              onToggleItemSkipped: (itemId) =>
                  unawaited(_toggleItemSkipped(openReceipt.id, itemId)),
              onAddItem: (input, participantIds) =>
                  _addItem(openReceipt.id, input, participantIds),
              onUpdateItem: (itemId, update) => _updateReceipt(
                openReceipt.id,
                (receipt) => updateReceiptItem(receipt, itemId, update),
              ),
              onDeleteItem: (itemId) =>
                  unawaited(_deleteItem(openReceipt.id, itemId)),
              onDeleteReceipt: () => unawaited(_deleteReceipt(openReceipt.id)),
            );
          }

          return DashboardScreen(
            controller: _controller,
            importing: _importing,
            onImport: () => unawaited(_importBiedronkaJson()),
            onAddManualReceipt: _addManualReceipt,
            onClearAll: () => unawaited(_clearAllReceipts()),
            onOpenReceipt: (receiptId) =>
                setState(() => _openReceiptId = receiptId),
          );
        },
      ),
    );
  }

  Receipt? _findReceipt(String? receiptId) {
    if (receiptId == null) {
      return null;
    }

    for (final receipt in _controller.household.receipts) {
      if (receipt.id == receiptId) {
        return receipt;
      }
    }

    return null;
  }

  Future<void> _importBiedronkaJson() async {
    if (_importing) {
      return;
    }

    setState(() => _importing = true);

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['json', 'txt'],
      );

      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();

      final imported = parseBiedronkaReceipt(
        utf8.decode(bytes),
        _controller.household.members,
      );

      final saved = await _controller.commit(
        (household) => household.copyWith(
          receipts: [imported.receipt, ...household.receipts],
        ),
      );

      if (!mounted) {
        return;
      }

      if (!saved) {
        _showSaveError();
        return;
      }

      setState(() => _openReceiptId = imported.receipt.id);

      final warning = imported.warnings.isEmpty
          ? null
          : imported.warnings.first;
      _showSnack(
        warning == null
            ? 'Paragon zaimportowany.'
            : 'Paragon zaimportowany. $warning',
      );
    } catch (error) {
      if (mounted) {
        _showSnack('Import nie wyszedl: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  Future<bool> _addManualReceipt(ManualReceiptInput input) async {
    final receipt = createManualReceipt(_controller.household.members, input);

    final saved = await _controller.commit(
      (household) =>
          household.copyWith(receipts: [receipt, ...household.receipts]),
    );

    if (!saved) {
      _showSaveError();
      return false;
    }
    if (mounted) {
      setState(() => _openReceiptId = receipt.id);
    }
    return true;
  }

  Future<void> _clearAllReceipts() async {
    if (_controller.household.receipts.isEmpty) {
      return;
    }

    final receiptIds = _controller.household.receipts.map((r) => r.id).toSet();
    final confirmed = await _confirm(
      title: 'Wyczyscic rachunki?',
      message: 'Usunie to wszystkie paragony w tym pokoju.',
      confirmLabel: 'Wyczysc',
    );

    if (confirmed != true) {
      return;
    }

    final saved = await _controller.commit(
      (household) => household.copyWith(
        receipts: household.receipts
            .where((r) => !receiptIds.contains(r.id))
            .toList(),
      ),
    );

    if (!saved) {
      _showSaveError();
      return;
    }

    if (mounted) {
      setState(() => _openReceiptId = null);
      _showSnack('Rachunki wyczyszczone.');
    }
  }

  Future<void> _deleteReceipt(String receiptId) async {
    final receipt = _findReceipt(receiptId);
    if (receipt == null) {
      return;
    }

    final confirmed = await _confirm(
      title: 'Usunac paragon?',
      message: receipt.title.isEmpty ? receipt.storeName : receipt.title,
      confirmLabel: 'Usun',
    );

    if (confirmed != true) {
      return;
    }

    final saved = await _controller.commit(
      (household) => household.copyWith(
        receipts: household.receipts
            .where((item) => item.id != receiptId)
            .toList(),
      ),
    );

    if (!saved) {
      _showSaveError();
      return;
    }

    if (mounted) {
      setState(() => _openReceiptId = null);
      _showSnack('Paragon usuniety.');
    }
  }

  Future<bool> _updateReceipt(
    String receiptId,
    Receipt Function(Receipt receipt) updater,
  ) async {
    final saved = await _controller.commit((household) {
      if (!household.receipts.any((receipt) => receipt.id == receiptId)) {
        throw const FormatException('Ten paragon został już usunięty.');
      }
      return household.copyWith(
        receipts: household.receipts.map((receipt) {
          return receipt.id == receiptId ? updater(receipt) : receipt;
        }).toList(),
      );
    });
    if (!saved) _showSaveError();
    return saved;
  }

  Future<void> _assignAllProducts(String receiptId) async {
    final allMemberIds = _controller.household.members
        .map((person) => person.id)
        .toList();

    await _updateReceipt(
      receiptId,
      (receipt) => receipt.copyWith(
        assignments: {
          ...receipt.assignments,
          for (final item in receipt.items.where(
            (item) => item.kind == ReceiptItemKind.product,
          ))
            item.id: createAssignment(item.id, allMemberIds),
        },
      ),
    );
  }

  Future<void> _clearProductAssignments(String receiptId) async {
    await _updateReceipt(
      receiptId,
      (receipt) => receipt.copyWith(
        assignments: {
          ...receipt.assignments,
          for (final item in receipt.items.where(
            (item) => item.kind == ReceiptItemKind.product,
          ))
            item.id: createAssignment(item.id),
        },
      ),
    );
  }

  Future<void> _setItemParticipants(
    String receiptId,
    String itemId,
    List<String> participantIds,
  ) async {
    await _updateReceipt(
      receiptId,
      (receipt) => updateReceiptAssignment(
        receipt,
        itemId,
        (assignment) => assignment.copyWith(
          participantIds: _normalizeParticipants(participantIds),
          skipped: false,
        ),
      ),
    );
  }

  Future<void> _toggleItemParticipant(
    String receiptId,
    String itemId,
    String personId,
  ) async {
    await _updateReceipt(
      receiptId,
      (receipt) => updateReceiptAssignment(receipt, itemId, (assignment) {
        final selected = assignment.participantIds.toSet();

        if (selected.contains(personId)) {
          selected.remove(personId);
        } else {
          selected.add(personId);
        }

        return assignment.copyWith(
          participantIds: _normalizeParticipants(selected.toList()),
          skipped: false,
        );
      }),
    );
  }

  Future<void> _toggleItemSkipped(String receiptId, String itemId) async {
    final memberIds = _controller.household.members
        .map((person) => person.id)
        .toList();

    await _updateReceipt(
      receiptId,
      (receipt) => updateReceiptAssignment(receipt, itemId, (assignment) {
        final item = receipt.items
            .where((receiptItem) => receiptItem.id == itemId)
            .firstOrNull;
        final shouldRestoreAll =
            item?.kind == ReceiptItemKind.depositReturn &&
            assignment.participantIds.isEmpty;

        return assignment.copyWith(
          participantIds: shouldRestoreAll
              ? memberIds
              : assignment.participantIds,
          skipped: !assignment.skipped,
        );
      }),
    );
  }

  Future<bool> _addItem(
    String receiptId,
    ManualProductItemInput input,
    List<String> participantIds,
  ) async {
    final item = createManualProductItem(input);
    final assignment = createAssignment(
      item.id,
      _normalizeParticipants(participantIds),
    );

    return _updateReceipt(
      receiptId,
      (receipt) => addReceiptItem(receipt, item, assignment),
    );
  }

  Future<void> _deleteItem(String receiptId, String itemId) async {
    final confirmed = await _confirm(
      title: 'Usunąć pozycję?',
      message: 'Pozycja zostanie usunięta z tego rachunku.',
      confirmLabel: 'Usuń',
    );
    if (confirmed != true) return;
    await _updateReceipt(
      receiptId,
      (receipt) => removeReceiptItem(receipt, itemId),
    );
  }

  List<String> _normalizeParticipants(List<String> participantIds) {
    final selected = participantIds.toSet();
    return _controller.household.members
        .where((person) => selected.contains(person.id))
        .map((person) => person.id)
        .toList();
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: _navigatorKey.currentContext!,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    _messengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.cardAlt,
        ),
      );
  }

  void _showSaveError() {
    _showSnack(_controller.error ?? 'Zmiana nie została zapisana.');
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: PageFrame(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 14),
                Text(
                  'Ladowanie Splitki...',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
