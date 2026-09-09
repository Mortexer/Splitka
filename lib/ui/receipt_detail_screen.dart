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
  final void Function(ManualProductItemInput input, List<String> participantIds)
  onAddItem;
  final void Function(String itemId, ProductItemUpdate update) onUpdateItem;
  final ValueChanged<String> onDeleteItem;
  final VoidCallback onDeleteReceipt;

  @override
  Widget build(BuildContext context) {
    final totals = getReceiptTotals(receipt);
    final settlement = calculateSettlement(household);

    return Scaffold(
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
                    _TotalsSection(receipt: receipt, totals: totals),
                    const SizedBox(height: 14),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Szybki wybór',
                            meta: 'produkty',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SecondaryActionButton(
                                  label: 'Wszyscy',
                                  icon: Icons.group_rounded,
                                  onPressed: onAssignAllProducts,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SecondaryActionButton(
                                  label: 'Nikt',
                                  icon: Icons.block_rounded,
                                  onPressed: onClearProductAssignments,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AddItemForm(
                      members: household.members,
                      onAddItem: onAddItem,
                    ),
                    const SizedBox(height: 14),
                    SectionHeader(
                      title: 'Pozycje',
                      meta: '${receipt.items.length} pozycji',
                    ),
                    const SizedBox(height: 10),
                    ...receipt.items.map(
                      (item) => Padding(
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
                    const SizedBox(height: 4),
                    SettlementCard(settlement: settlement, compact: true),
                  ],
                ),
              ),
            ],
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
                    receipt.storeName,
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
            StatusPill(
              label: pendingCount > 0
                  ? '$pendingCount do podziału'
                  : 'Podzielony',
              tone: pendingCount > 0 ? PillTone.amber : PillTone.green,
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDeleteReceipt,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.danger.withValues(alpha: 0.14),
                foregroundColor: AppColors.danger,
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.42),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                fixedSize: const Size(38, 38),
              ),
              icon: const Icon(Icons.delete_rounded, size: 17),
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
  const _TotalsSection({required this.receipt, required this.totals});

  final Receipt receipt;
  final ReceiptTotals totals;

  @override
  Widget build(BuildContext context) {
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
            label: 'Do podziału',
            value: formatMoney(totals.includedCents),
            strong: true,
          ),
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

class AddItemForm extends StatefulWidget {
  const AddItemForm({
    super.key,
    required this.members,
    required this.onAddItem,
  });

  final List<Person> members;
  final void Function(ManualProductItemInput input, List<String> participantIds)
  onAddItem;

  @override
  State<AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  late List<String> _participantIds;

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
                  enabled: canSave,
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

  void _submit(int? amountCents) {
    if (amountCents == null || amountCents <= 0) {
      return;
    }

    widget.onAddItem(
      ManualProductItemInput(
        name: _nameController.text,
        quantity: _quantityController.text,
        totalCents: amountCents,
      ),
      _participantIds,
    );
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
  final ValueChanged<ProductItemUpdate> onUpdate;
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
                          : 'ilość: ${widget.item.quantity}',
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
                onSave: (update) {
                  widget.onUpdate(update);
                  setState(() => _editing = false);
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
  final ValueChanged<ProductItemUpdate> onSave;
  final VoidCallback onCancel;

  @override
  State<ItemEditForm> createState() => _ItemEditFormState();
}

class _ItemEditFormState extends State<ItemEditForm> {
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
                    enabled: canSave,
                    onPressed: () {
                      if (amountCents == null || amountCents <= 0) {
                        return;
                      }

                      widget.onSave(
                        ProductItemUpdate(
                          name: _nameController.text,
                          quantity: _quantityController.text,
                          totalCents: amountCents,
                        ),
                      );
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
