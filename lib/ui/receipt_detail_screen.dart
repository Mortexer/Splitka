import 'package:flutter/material.dart';

import '../domain/money.dart';
import '../domain/models.dart';
import '../domain/receipts.dart';
import '../domain/settlements.dart';
import 'common_widgets.dart';

class ReceiptDetailScreen extends StatelessWidget {
  const ReceiptDetailScreen({
    super.key,
    required this.household,
    required this.receipt,
    required this.onBack,
    required this.onSetPayer,
    required this.onAssignAllProducts,
    required this.onClearProductAssignments,
    required this.onSetItemParticipants,
    required this.onToggleItemParticipant,
    required this.onToggleItemSkipped,
    required this.onAddItem,
    required this.onUpdateItem,
    required this.onDeleteItem,
    required this.onDeleteReceipt,
  });

  final Household household;
  final Receipt receipt;
  final VoidCallback onBack;
  final ValueChanged<String> onSetPayer;
  final VoidCallback onAssignAllProducts;
  final VoidCallback onClearProductAssignments;
  final void Function(String itemId, List<String> participantIds)
  onSetItemParticipants;
  final void Function(String itemId, String personId) onToggleItemParticipant;
  final ValueChanged<String> onToggleItemSkipped;
  final Future<bool> Function(
    ManualProductItemInput input,
    List<String> participantIds,
  )
  onAddItem;
  final Future<bool> Function(String itemId, ProductItemUpdate update)
  onUpdateItem;
  final ValueChanged<String> onDeleteItem;
  final VoidCallback onDeleteReceipt;

  @override
  Widget build(BuildContext context) {
    final totals = getReceiptTotals(receipt);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: PageFrame(
            child: Column(
              children: [
                _DetailHeader(
                  receipt: receipt,
                  pendingCount: totals.unassignedCount,
                  onBack: onBack,
                  onDeleteReceipt: onDeleteReceipt,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
                    children: [
                      _PayerSection(
                        receipt: receipt,
                        members: household.members,
                        onSetPayer: onSetPayer,
                      ),
                      const SizedBox(height: 14),
                      _TotalsSection(
                        receipt: receipt,
                        totals: totals,
                        members: household.members,
                      ),
                      const SizedBox(height: 14),
                      AddItemForm(
                        members: household.members,
                        onAddItem: onAddItem,
                      ),
                      const SizedBox(height: 14),
                      _ItemsHeader(
                        count: receipt.items.length,
                        onAssignAll: onAssignAllProducts,
                        onClearAssignments: onClearProductAssignments,
                      ),
                      const SizedBox(height: 10),
                      ...receipt.items.map(
                        (item) => Padding(
                          key: ValueKey(item.id),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ItemCard(
                            item: item,
                            assignment: getAssignment(receipt, item.id),
                            members: household.members,
                            onAll: () => onSetItemParticipants(
                              item.id,
                              household.members
                                  .map((person) => person.id)
                                  .toList(),
                            ),
                            onNobody: () =>
                                onSetItemParticipants(item.id, const []),
                            onTogglePerson: (personId) =>
                                onToggleItemParticipant(item.id, personId),
                            onToggleSkipped: () => onToggleItemSkipped(item.id),
                            onUpdate: (update) => onUpdateItem(item.id, update),
                            onDelete: () => onDeleteItem(item.id),
                          ),
                        ),
                      ),
                    ],
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

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.receipt,
    required this.pendingCount,
    required this.onBack,
    required this.onDeleteReceipt,
  });

  final Receipt receipt;
  final int pendingCount;
  final VoidCallback onBack;
  final VoidCallback onDeleteReceipt;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.card,
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                fixedSize: const Size(38, 38),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.title.isEmpty ? receipt.storeName : receipt.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    formatReceiptDate(receipt.boughtAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (pendingCount > 0) ...[
              StatusPill(
                label: '$pendingCount do podziału',
                tone: PillTone.amber,
              ),
              const SizedBox(width: 4),
            ],
            PopupMenuButton<_ReceiptAction>(
              key: const ValueKey('receipt-actions'),
              tooltip: 'Więcej opcji',
              color: AppColors.cardAlt,
              icon: const Icon(Icons.more_vert_rounded, size: 19),
              onSelected: (action) {
                if (action == _ReceiptAction.delete) onDeleteReceipt();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _ReceiptAction.delete,
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Usuń paragon',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PayerSection extends StatelessWidget {
  const _PayerSection({
    required this.receipt,
    required this.members,
    required this.onSetPayer,
  });

  final Receipt receipt;
  final List<Person> members;
  final ValueChanged<String> onSetPayer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zapłacił(a)',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: members.map((person) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: PersonChoice(
                    person: person,
                    selected: receipt.payerId == person.id,
                    onPressed: () => onSetPayer(person.id),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TotalsSection extends StatelessWidget {
  const _TotalsSection({
    required this.receipt,
    required this.totals,
    required this.members,
  });

  final Receipt receipt;
  final ReceiptTotals totals;
  final List<Person> members;

  @override
  Widget build(BuildContext context) {
    Person? payer;
    for (final person in members) {
      if (person.id == receipt.payerId) {
        payer = person;
        break;
      }
    }

    return AppCard(
      child: Column(
        children: [
          MoneyRow(
            label: 'Suma pozycji',
            value: formatMoney(receipt.grossCents),
            icon: Icons.receipt_long_rounded,
          ),
          MoneyRow(
            label: 'Rabaty',
            value: '-${formatMoney(receipt.discountCents)}',
            icon: Icons.local_offer_rounded,
            color: AppColors.primary,
          ),
          MoneyRow(
            label: 'Kaucja (pomijana)',
            value: formatMoney(receipt.depositCents),
            icon: Icons.paid_rounded,
            color: AppColors.blue,
          ),
          MoneyRow(
            label: 'Zwrot opakowań',
            value: '-${formatMoney(receipt.depositReturnCents)}',
            icon: Icons.savings_rounded,
            color: AppColors.blue,
          ),
          const Divider(color: AppColors.border, height: 18),
          MoneyRow(
            label: 'Zapłacone przez ${payer?.name ?? 'nieznaną osobę'}',
            value: formatMoney(receiptCashTotal(receipt)),
            strong: true,
          ),
          MoneyRow(
            label: 'Do podziału',
            value: formatMoney(totals.includedCents),
            color: AppColors.primary,
          ),
          if (totals.unassignedCents != 0)
            MoneyRow(
              label: 'Nieprzypisane',
              value: formatMoney(totals.unassignedCents),
              color: AppColors.amber,
            ),
        ],
      ),
    );
  }
}

class _ItemsHeader extends StatelessWidget {
  const _ItemsHeader({
    required this.count,
    required this.onAssignAll,
    required this.onClearAssignments,
  });

  final int count;
  final VoidCallback onAssignAll;
  final VoidCallback onClearAssignments;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Pozycje',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          '$count pozycji',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 2),
        PopupMenuButton<_AssignmentAction>(
          tooltip: 'Przypisz wszystkie pozycje',
          color: AppColors.cardAlt,
          icon: const Icon(
            Icons.group_work_outlined,
            color: AppColors.textMuted,
            size: 19,
          ),
          onSelected: (action) {
            switch (action) {
              case _AssignmentAction.everyone:
                onAssignAll();
              case _AssignmentAction.nobody:
                onClearAssignments();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: _AssignmentAction.everyone,
              child: Row(
                children: [
                  Icon(Icons.groups_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Wszystkie dla wszystkich'),
                ],
              ),
            ),
            PopupMenuItem(
              value: _AssignmentAction.nobody,
              child: Row(
                children: [
                  Icon(Icons.block_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Wyczyść przypisania'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _ReceiptAction { delete }

enum _AssignmentAction { everyone, nobody }

class AddItemForm extends StatefulWidget {
  const AddItemForm({
    super.key,
    required this.members,
    required this.onAddItem,
  });

  final List<Person> members;
  final Future<bool> Function(
    ManualProductItemInput input,
    List<String> participantIds,
  )
  onAddItem;

  @override
  State<AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  late List<String> _participantIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _participantIds = widget.members.map((person) => person.id).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amountCents = parseMoneyInput(_amountController.text);
    final canSave =
        _nameController.text.trim().isNotEmpty &&
        amountCents != null &&
        amountCents > 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Dodaj pozycję',
            meta: _participantIds.isEmpty
                ? 'bez osób'
                : '${_participantIds.length} osób',
            icon: Icons.add_rounded,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            autocorrect: false,
            decoration: const InputDecoration(hintText: 'Produkt'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(hintText: 'Kwota'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(hintText: 'Ilość'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: widget.members.map((person) {
              return PersonChip(
                person: person,
                selected: _participantIds.contains(person.id),
                onPressed: () => _toggleParticipant(person.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SecondaryActionButton(
                  label: 'Wszyscy',
                  icon: Icons.group_rounded,
                  onPressed: () => setState(
                    () => _participantIds = widget.members
                        .map((person) => person.id)
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SecondaryActionButton(
                  label: 'Nikt',
                  icon: Icons.block_rounded,
                  onPressed: () => setState(() => _participantIds = []),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryActionButton(
                  label: 'Dodaj',
                  icon: Icons.add_rounded,
                  enabled: canSave && !_saving,
                  onPressed: () => _submit(amountCents),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleParticipant(String personId) {
    setState(() {
      if (_participantIds.contains(personId)) {
        _participantIds = _participantIds
            .where((id) => id != personId)
            .toList();
      } else {
        _participantIds = [..._participantIds, personId];
      }
    });
  }

  Future<void> _submit(int? amountCents) async {
    if (_saving || amountCents == null || amountCents <= 0) {
      return;
    }

    setState(() => _saving = true);
    final saved = await widget.onAddItem(
      ManualProductItemInput(
        name: _nameController.text,
        quantity: _quantityController.text,
        totalCents: amountCents,
      ),
      _participantIds,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!saved) return;
    _nameController.clear();
    _amountController.clear();
    _quantityController.text = '1';
    setState(() {});
  }
}

class ItemCard extends StatefulWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.assignment,
    required this.members,
    required this.onAll,
    required this.onNobody,
    required this.onTogglePerson,
    required this.onToggleSkipped,
    required this.onUpdate,
    required this.onDelete,
  });

  final ReceiptItem item;
  final ItemAssignment assignment;
  final List<Person> members;
  final VoidCallback onAll;
  final VoidCallback onNobody;
  final ValueChanged<String> onTogglePerson;
  final VoidCallback onToggleSkipped;
  final Future<bool> Function(ProductItemUpdate) onUpdate;
  final VoidCallback onDelete;

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final selectedCount = widget.assignment.skipped
        ? 0
        : widget.assignment.participantIds.length;
    final noneChosen = !widget.assignment.skipped && selectedCount == 0;
    final sharePreview = getItemSharePreview(widget.item, widget.assignment);
    final editable = widget.item.kind == ReceiptItemKind.product;

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.kind == ReceiptItemKind.depositReturn
                          ? 'odejmuje rachunek'
                          : widget.item.quantity,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatMoney(widget.item.totalCents),
                        style: TextStyle(
                          color: widget.item.totalCents < 0
                              ? AppColors.primary
                              : AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (editable) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () => setState(() => _editing = !_editing),
                          style: IconButton.styleFrom(
                            backgroundColor: _editing
                                ? AppColors.primary
                                : AppColors.cardAlt,
                            foregroundColor: _editing
                                ? AppColors.primaryForeground
                                : AppColors.textMuted,
                            side: BorderSide(
                              color: _editing
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                            fixedSize: const Size(28, 28),
                            minimumSize: const Size(28, 28),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 14),
                        ),
                      ],
                    ],
                  ),
                  if (noneChosen) ...[
                    const SizedBox(height: 4),
                    const StatusPill(
                      label: 'Do przypisania',
                      tone: PillTone.amber,
                    ),
                  ],
                  if (widget.assignment.skipped) ...[
                    const SizedBox(height: 4),
                    const StatusPill(label: 'Pominięto', tone: PillTone.muted),
                  ],
                  if (sharePreview != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${formatMoney(sharePreview)} / os.',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (_editing && editable)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ItemEditForm(
                item: widget.item,
                onCancel: () => setState(() => _editing = false),
                onSave: (update) async {
                  final saved = await widget.onUpdate(update);
                  if (saved && mounted) setState(() => _editing = false);
                  return saved;
                },
              ),
            ),
          if (!widget.assignment.skipped) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: widget.members.map((person) {
                return PersonChip(
                  person: person,
                  selected: widget.assignment.participantIds.contains(
                    person.id,
                  ),
                  onPressed: () => widget.onTogglePerson(person.id),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  label: 'Wszyscy',
                  icon: Icons.group_rounded,
                  active:
                      !widget.assignment.skipped &&
                      selectedCount == widget.members.length,
                  onPressed: widget.onAll,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _QuickAction(
                  label: 'Nikt',
                  icon: Icons.block_rounded,
                  onPressed: widget.onNobody,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _QuickAction(
                  label: widget.assignment.skipped ? 'Wróć' : 'Pomiń',
                  icon: Icons.skip_next_rounded,
                  active: widget.assignment.skipped,
                  onPressed: widget.onToggleSkipped,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _QuickAction(
                  label: 'Usuń',
                  icon: Icons.delete_rounded,
                  danger: true,
                  onPressed: widget.onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ItemEditForm extends StatefulWidget {
  const ItemEditForm({
    super.key,
    required this.item,
    required this.onSave,
    required this.onCancel,
  });

  final ReceiptItem item;
  final Future<bool> Function(ProductItemUpdate) onSave;
  final VoidCallback onCancel;

  @override
  State<ItemEditForm> createState() => _ItemEditFormState();
}

class _ItemEditFormState extends State<ItemEditForm> {
  bool _saving = false;
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _amountController = TextEditingController(
      text: formatMoneyInput(widget.item.totalCents),
    );
    _quantityController = TextEditingController(text: widget.item.quantity);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amountCents = parseMoneyInput(_amountController.text);
    final canSave =
        _nameController.text.trim().isNotEmpty &&
        amountCents != null &&
        amountCents > 0;

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Produkt'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(hintText: 'Kwota'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(hintText: 'Ilość'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SecondaryActionButton(
                    label: 'Anuluj',
                    icon: Icons.close_rounded,
                    onPressed: widget.onCancel,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PrimaryActionButton(
                    label: 'Zapisz',
                    icon: Icons.save_rounded,
                    enabled: canSave && !_saving,
                    onPressed: () async {
                      if (amountCents == null || amountCents <= 0) {
                        return;
                      }

                      setState(() => _saving = true);
                      await widget.onSave(
                        ProductItemUpdate(
                          name: _nameController.text,
                          quantity: _quantityController.text,
                          totalCents: amountCents,
                        ),
                      );
                      if (mounted) setState(() => _saving = false);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.active = false,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool active;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final foreground = danger
        ? AppColors.danger
        : active
        ? AppColors.primaryForeground
        : AppColors.textMuted;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: danger
            ? AppColors.danger.withValues(alpha: 0.14)
            : active
            ? AppColors.primary
            : AppColors.card,
        foregroundColor: foreground,
        side: BorderSide(
          color: danger
              ? AppColors.danger.withValues(alpha: 0.35)
              : active
              ? AppColors.primary
              : AppColors.border,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
