import 'package:flutter/material.dart';

import '../domain/money.dart';
import '../domain/models.dart';
import '../domain/receipts.dart';
import '../domain/settlements.dart';
import '../state/household_controller.dart';
import 'common_widgets.dart';
import 'room_dialog.dart';
import 'shopping_lists_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    required this.importing,
    required this.onImport,
    required this.onAddManualReceipt,
    required this.onClearAll,
    required this.onOpenReceipt,
    required this.onAddShoppingItem,
    required this.onToggleShoppingItem,
    required this.onDeleteShoppingItem,
    required this.onClearCompletedShoppingItems,
  });

  final HouseholdController controller;
  final bool importing;
  final VoidCallback onImport;
  final Future<bool> Function(ManualReceiptInput) onAddManualReceipt;
  final VoidCallback onClearAll;
  final ValueChanged<String> onOpenReceipt;
  final Future<bool> Function(String listId, String name) onAddShoppingItem;
  final Future<bool> Function(String listId, String itemId)
  onToggleShoppingItem;
  final Future<bool> Function(String listId, String itemId)
  onDeleteShoppingItem;
  final Future<bool> Function(String listId) onClearCompletedShoppingItems;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _manualFormOpen = false;
  int _selectedTab = 0;

  HouseholdController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final household = controller.household;
    final settlement = calculateSettlement(household);

    return Scaffold(
      body: SafeArea(
        child: PageFrame(
          child: Column(
            children: [
              _Header(
                controller: controller,
                onRoomPressed: () => showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => RoomDialog(controller: controller),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryActionButton(
                                label: widget.importing
                                    ? 'Importowanie...'
                                    : 'Importuj JSON',
                                icon: Icons.upload_file_rounded,
                                onPressed: widget.onImport,
                                enabled: !widget.importing,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SecondaryActionButton(
                                label: _manualFormOpen
                                    ? 'Zamknij'
                                    : 'Dodaj ręcznie',
                                icon: _manualFormOpen
                                    ? Icons.close_rounded
                                    : Icons.add_rounded,
                                onPressed: () => setState(
                                  () => _manualFormOpen = !_manualFormOpen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_manualFormOpen) ...[
                          const SizedBox(height: 14),
                          ManualReceiptCard(
                            members: household.members,
                            onCancel: () =>
                                setState(() => _manualFormOpen = false),
                            onSubmit: (input) async {
                              final saved = await widget.onAddManualReceipt(
                                input,
                              );
                              if (saved && mounted) {
                                setState(() => _manualFormOpen = false);
                              }
                              return saved;
                            },
                          ),
                        ],
                        const SizedBox(height: 14),
                        if (household.receipts.isEmpty)
                          EmptyState(
                            importing: widget.importing,
                            onImport: widget.onImport,
                          )
                        else ...[
                          SectionHeader(
                            title: 'Paragony',
                            meta: household.receipts.length.toString(),
                          ),
                          const SizedBox(height: 10),
                          ...household.receipts.map(
                            (receipt) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ReceiptListItem(
                                receipt: receipt,
                                members: household.members,
                                onPressed: () =>
                                    widget.onOpenReceipt(receipt.id),
                              ),
                            ),
                          ),
                          SecondaryActionButton(
                            label: 'Wyczyść rachunki',
                            icon: Icons.refresh_rounded,
                            onPressed: widget.onClearAll,
                          ),
                          const SizedBox(height: 14),
                          SettlementCard(settlement: settlement),
                        ],
                      ],
                    ),
                    ShoppingListsScreen(
                      household: household,
                      onAddItem: widget.onAddShoppingItem,
                      onToggleItem: widget.onToggleShoppingItem,
                      onDeleteItem: widget.onDeleteShoppingItem,
                      onClearCompleted: widget.onClearCompletedShoppingItems,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: NavigationBar(
              height: 66,
              selectedIndex: _selectedTab,
              onDestinationSelected: (index) =>
                  setState(() => _selectedTab = index),
              backgroundColor: AppColors.card,
              indicatorColor: AppColors.primary,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Rachunki',
                ),
                NavigationDestination(
                  icon: Icon(Icons.checklist_rounded),
                  selectedIcon: Icon(Icons.shopping_cart_rounded),
                  label: 'Listy zakupów',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.onRoomPressed});

  final HouseholdController controller;
  final VoidCallback onRoomPressed;

  @override
  Widget build(BuildContext context) {
    final household = controller.household;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/branding/splitka-foreground.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Splitka',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        controller.isCloudRoom
                            ? 'Wspólne mieszkanie'
                            : 'Na tym telefonie',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                SyncBadge(
                  syncState: controller.syncState,
                  error: controller.error,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.busy ? null : onRoomPressed,
                    icon: const Icon(Icons.home_outlined, size: 18),
                    label: Text(
                      controller.isCloudRoom
                          ? 'Mieszkanie'
                          : 'Połącz mieszkanie',
                    ),
                  ),
                ),
                if (controller.isCloudRoom) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Połącz ponownie',
                    onPressed: controller.busy
                        ? null
                        : controller.retryConnection,
                    icon: const Icon(Icons.sync_rounded, size: 20),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (controller.error != null) ...[
              Text(
                controller.error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                SizedBox(
                  width: 54,
                  height: 30,
                  child: Stack(
                    children: [
                      for (
                        var index = 0;
                        index < household.members.length;
                        index += 1
                      )
                        Positioned(
                          left: index * 17,
                          child: PersonAvatar(
                            person: household.members[index],
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    household.members.map((person) => person.name).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

class ManualReceiptCard extends StatefulWidget {
  const ManualReceiptCard({
    super.key,
    required this.members,
    required this.onSubmit,
    required this.onCancel,
  });

  final List<Person> members;
  final Future<bool> Function(ManualReceiptInput) onSubmit;
  final VoidCallback onCancel;

  @override
  State<ManualReceiptCard> createState() => _ManualReceiptCardState();
}

class _ManualReceiptCardState extends State<ManualReceiptCard> {
  late final TextEditingController _titleController;
  late String _payerId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'Rachunek ręczny');
    _payerId = widget.members.isNotEmpty ? widget.members.first.id : 'danus';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _titleController.text.trim().isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Nowy rachunek',
            meta: 'ręcznie',
            icon: Icons.add_rounded,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(hintText: 'Nazwa rachunku'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          const Text(
            'Zapłacił(a)',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: widget.members.map((person) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: PersonChoice(
                    person: person,
                    selected: person.id == _payerId,
                    onPressed: () => setState(() => _payerId = person.id),
                  ),
                ),
              );
            }).toList(),
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
                  label: 'Utwórz',
                  icon: Icons.add_rounded,
                  enabled: canSave && !_saving,
                  onPressed: () async {
                    setState(() => _saving = true);
                    await widget.onSubmit(
                      ManualReceiptInput(
                        title: _titleController.text,
                        payerId: _payerId,
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
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.importing,
    required this.onImport,
  });

  final bool importing;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Brak paragonów',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Zaimportuj JSON z Biedronki albo dodaj rachunek ręcznie.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: PrimaryActionButton(
                label: importing ? 'Importowanie...' : 'Importuj paragon',
                icon: Icons.upload_file_rounded,
                onPressed: onImport,
                enabled: !importing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReceiptListItem extends StatelessWidget {
  const ReceiptListItem({
    super.key,
    required this.receipt,
    required this.members,
    required this.onPressed,
  });

  final Receipt receipt;
  final List<Person> members;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final totals = getReceiptTotals(receipt);
    final payer =
        members.where((person) => person.id == receipt.payerId).firstOrNull ??
        (members.isEmpty ? defaultMembers.first : members.first);

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 74),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: receipt.title.isEmpty
                            ? receipt.storeName
                            : receipt.title,
                        children: [
                          TextSpan(
                            text:
                                ' ${formatShortReceiptDate(receipt.boughtAt)}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        PersonAvatar(person: payer, size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'zapłacił(a) ${payer.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(receiptCashTotal(receipt)),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 5),
                  StatusPill(
                    label: totals.unassignedCount > 0
                        ? '${totals.unassignedCount} do podziału'
                        : 'Podzielony',
                    tone: totals.unassignedCount > 0
                        ? PillTone.amber
                        : PillTone.green,
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
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
