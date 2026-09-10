import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/shopping_lists.dart';
import 'common_widgets.dart';

class ShoppingListsScreen extends StatefulWidget {
  const ShoppingListsScreen({
    super.key,
    required this.household,
    required this.onAddItem,
    required this.onToggleItem,
    required this.onDeleteItem,
    required this.onClearCompleted,
  });

  final Household household;
  final Future<bool> Function(String listId, String name) onAddItem;
  final Future<bool> Function(String listId, String itemId) onToggleItem;
  final Future<bool> Function(String listId, String itemId) onDeleteItem;
  final Future<bool> Function(String listId) onClearCompleted;

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  final _itemController = TextEditingController();
  final _drafts = <String, String>{};
  String _selectedListId = commonShoppingListId;
  bool _adding = false;

  @override
  void didUpdateWidget(covariant ShoppingListsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!shoppingListIds(widget.household).contains(_selectedListId)) {
      _selectedListId = commonShoppingListId;
      _itemController.text = _drafts[_selectedListId] ?? '';
    }
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    if (_adding || _itemController.text.trim().isEmpty) return;
    setState(() => _adding = true);
    final saved = await widget.onAddItem(_selectedListId, _itemController.text);
    if (!mounted) return;
    if (saved) {
      _itemController.clear();
      _drafts.remove(_selectedListId);
    }
    setState(() => _adding = false);
  }

  @override
  Widget build(BuildContext context) {
    final household = widget.household;
    final items = shoppingItems(household, _selectedListId);
    final pending = items.where((item) => !item.completed).toList();
    final completed = items.where((item) => item.completed).toList();
    final visibleItems = [...pending, ...completed];

    return Column(
      children: [
        SizedBox(
          height: 54,
          child: ListView.separated(
            key: const ValueKey('shopping-list-selector'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            scrollDirection: Axis.horizontal,
            itemCount: shoppingListIds(household).length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final listId = shoppingListIds(household)[index];
              final selected = listId == _selectedListId;
              final person = listId == commonShoppingListId
                  ? null
                  : household.members.firstWhere(
                      (member) => member.id == listId,
                    );
              return ChoiceChip(
                selected: selected,
                showCheckmark: false,
                avatar: listId == commonShoppingListId
                    ? Icon(
                        Icons.groups_rounded,
                        size: 17,
                        color: selected
                            ? AppColors.primaryForeground
                            : AppColors.textMuted,
                      )
                    : PersonAvatar(person: person!, size: 18),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(shoppingListName(household, listId)),
                    const SizedBox(width: 6),
                    Container(
                      constraints: const BoxConstraints(minWidth: 17),
                      height: 17,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryForeground.withValues(
                                alpha: 0.18,
                              )
                            : AppColors.muted,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        shoppingItems(
                          household,
                          listId,
                        ).where((item) => !item.completed).length.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                onSelected: (_) {
                  _drafts[_selectedListId] = _itemController.text;
                  setState(() => _selectedListId = listId);
                  _itemController.text = _drafts[listId] ?? '';
                },
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.card,
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
                labelStyle: TextStyle(
                  color: selected
                      ? AppColors.primaryForeground
                      : AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 34),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: ValueKey('shopping-input-$_selectedListId'),
                      controller: _itemController,
                      enabled: !_adding,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addItem(),
                      decoration: InputDecoration(
                        hintText:
                            'Dodaj do listy „${shoppingListName(household, _selectedListId)}”',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Dodaj do listy',
                    onPressed: _adding ? null : _addItem,
                    style: IconButton.styleFrom(
                      fixedSize: const Size(44, 44),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryForeground,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.35,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: _adding
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ListMeta(
                household: household,
                listId: _selectedListId,
                pendingCount: pending.length,
              ),
              const SizedBox(height: 10),
              if (visibleItems.isEmpty)
                const _EmptyShoppingList()
              else
                ...visibleItems.map(
                  (item) => Padding(
                    key: ValueKey(item.id),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ShoppingItemRow(
                      item: item,
                      onToggle: () => unawaited(
                        widget.onToggleItem(_selectedListId, item.id),
                      ),
                      onDelete: () => unawaited(
                        widget.onDeleteItem(_selectedListId, item.id),
                      ),
                    ),
                  ),
                ),
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 6),
                SecondaryActionButton(
                  label: 'Usuń kupione (${completed.length})',
                  icon: Icons.delete_sweep_outlined,
                  onPressed: () =>
                      unawaited(widget.onClearCompleted(_selectedListId)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ShoppingItemRow extends StatelessWidget {
  const _ShoppingItemRow({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  final ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.completed ? 0.6 : 1,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(11, 9, 6, 9),
        child: Row(
          children: [
            IconButton(
              tooltip: item.completed
                  ? 'Oznacz jako do kupienia'
                  : 'Oznacz jako kupione',
              onPressed: onToggle,
              style: IconButton.styleFrom(
                fixedSize: const Size(28, 28),
                minimumSize: const Size(28, 28),
                padding: EdgeInsets.zero,
                backgroundColor: item.completed
                    ? AppColors.primary
                    : AppColors.background,
                foregroundColor: item.completed
                    ? AppColors.primaryForeground
                    : Colors.transparent,
                side: BorderSide(
                  color: item.completed ? AppColors.primary : AppColors.border,
                ),
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.check_rounded, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: item.completed ? AppColors.textMuted : AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: item.completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Usuń produkt',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyShoppingList extends StatelessWidget {
  const _EmptyShoppingList();

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
          Text(
            'Pusta lista',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Dodaj pierwszą rzecz w polu powyżej.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ListMeta extends StatelessWidget {
  const _ListMeta({
    required this.household,
    required this.listId,
    required this.pendingCount,
  });

  final Household household;
  final String listId;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final shared = listId == commonShoppingListId;
    final person = shared
        ? null
        : household.members.firstWhere((member) => member.id == listId);
    return Row(
      children: [
        if (shared)
          const Icon(Icons.groups_rounded, size: 17, color: AppColors.textMuted)
        else
          PersonAvatar(person: person!, size: 20),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            shared ? 'Lista wspólna' : 'Lista: ${person!.name}',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$pendingCount do kupienia',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}
