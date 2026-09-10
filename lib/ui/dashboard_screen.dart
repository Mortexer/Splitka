import 'package:flutter/material.dart';

import '../domain/money.dart';
import '../domain/models.dart';
import '../domain/receipts.dart';
import '../domain/settlements.dart';
import '../domain/shopping_lists.dart';
import '../state/household_controller.dart';
import 'common_widgets.dart';
import 'group_settings_screen.dart';
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
    final shoppingBadge = shoppingListIds(household).fold<int>(
      0,
      (sum, listId) =>
          sum +
          shoppingItems(
            household,
            listId,
          ).where((item) => !item.completed).length,
    );

    return Scaffold(
      body: SafeArea(
        child: PageFrame(
          child: Column(
            children: [
              _Header(
                controller: controller,
                selectedTab: _selectedTab,
                onRoomPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => GroupSettingsScreen(controller: controller),
                  ),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
                      children: [
                        PrimaryActionButton(
                          label: widget.importing
                              ? 'Importowanie...'
                              : 'Importuj paragon (JSON)',
                          icon: Icons.file_upload_outlined,
                          onPressed: widget.onImport,
                          enabled: !widget.importing,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryActionButton(
                                label: _manualFormOpen
                                    ? 'Zamknij formularz'
                                    : 'Dodaj ręcznie',
                                icon: _manualFormOpen
                                    ? Icons.close_rounded
                                    : Icons.add_rounded,
                                onPressed: () => setState(
                                  () => _manualFormOpen = !_manualFormOpen,
                                ),
                              ),
                            ),
                            if (household.receipts.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              IconButton.outlined(
                                tooltip: 'Wyczyść rachunki',
                                onPressed: widget.onClearAll,
                                icon: const Icon(Icons.delete_sweep_outlined),
                              ),
                            ],
                          ],
                        ),
                        if (_manualFormOpen) ...[
                          const SizedBox(height: 14),
                          ManualReceiptCard(
                            members: household.activeMembers,
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
                          const EmptyState()
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
                          SettlementCard(
                            settlement: settlement,
                            members: household.members,
                          ),
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
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: 'Rozliczenia',
                ),
                NavigationDestination(
                  icon: Badge.count(
                    count: shoppingBadge,
                    isLabelVisible: shoppingBadge > 0,
                    backgroundColor: AppColors.primary,
                    textColor: AppColors.primaryForeground,
                    child: const Icon(Icons.playlist_add_check_rounded),
                  ),
                  selectedIcon: Badge.count(
                    count: shoppingBadge,
                    isLabelVisible: shoppingBadge > 0,
                    backgroundColor: AppColors.primary,
                    textColor: AppColors.primaryForeground,
                    child: const Icon(Icons.playlist_add_check_rounded),
                  ),
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
  const _Header({
    required this.controller,
    required this.selectedTab,
    required this.onRoomPressed,
  });

  final HouseholdController controller;
  final int selectedTab;
  final VoidCallback onRoomPressed;

  @override
  Widget build(BuildContext context) {
    final household = controller.household;
    final showingLists = selectedTab == 1;

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
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.cardAlt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    showingLists
                        ? Icons.shopping_basket_outlined
                        : Icons.receipt_long_outlined,
                    color: AppColors.text,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showingLists ? 'Listy zakupów' : 'Splitka',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        household.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                SyncBadge(
                  syncState: controller.syncState,
                  error: controller.error,
                  compact: MediaQuery.sizeOf(context).width <= 360,
                ),
                const SizedBox(width: 4),
                IconButton(
                  key: const ValueKey('open-group-settings'),
                  tooltip: 'Zarządzaj grupą',
                  onPressed: controller.busy ? null : onRoomPressed,
                  icon: const Icon(Icons.home_outlined, size: 19),
                  style: IconButton.styleFrom(
                    fixedSize: const Size(34, 34),
                    minimumSize: const Size(34, 34),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            if (controller.error != null) ...[
              const SizedBox(height: 8),
              Text(
                controller.error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
            if (!showingLists) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  MemberAvatarStack(members: household.activeMembers),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      household.activeMembers
                          .map((person) => person.name)
                          .join(', '),
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
    _payerId = widget.members.isNotEmpty
        ? widget.members.first.id
        : defaultMembers.first.id;
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
          PersonSelector(
            members: widget.members,
            selectedId: _payerId,
            onSelected: (personId) => setState(() => _payerId = personId),
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
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.muted,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 56,
              child: Icon(
                Icons.receipt_long_rounded,
                color: AppColors.textMuted,
                size: 28,
              ),
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Brak paragonów',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Zaimportuj plik JSON z paragonem z Biedronki, aby zacząć dzielić zakupy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
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
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.textMuted,
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
                        fontWeight: FontWeight.w600,
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
                              fontWeight: FontWeight.w500,
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
                      fontWeight: FontWeight.w600,
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
