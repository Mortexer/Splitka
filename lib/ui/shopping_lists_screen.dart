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
                avatar: Icon(
                  listId == commonShoppingListId
                      ? Icons.groups_rounded
                      : Icons.person_rounded,
                  size: 17,
                  color: selected
                      ? AppColors.primaryForeground
                      : Color(person?.color ?? AppColors.primary.toARGB32()),
                ),
                label: Text(shoppingListName(household, listId)),
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
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 34),
            children: [
              SectionHeader(
                title: shoppingListName(household, _selectedListId),
                meta: pending.isEmpty
                    ? 'brak'
                    : '${pending.length} do kupienia',
                icon: Icons.shopping_cart_outlined,
              ),
              const SizedBox(height: 12),
              TextField(
                key: ValueKey('shopping-input-$_selectedListId'),
                controller: _itemController,
                enabled: !_adding,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addItem(),
                decoration: InputDecoration(
                  hintText: 'Dodaj produkt',
                  suffixIcon: IconButton(
                    tooltip: 'Dodaj do listy',
                    onPressed: _adding ? null : _addItem,
                    icon: _adding
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 14),
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
    return AppCard(
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
      child: Row(
        children: [
          Checkbox(
            value: item.completed,
            onChanged: (_) => onToggle(),
            activeColor: AppColors.primary,
            checkColor: AppColors.primaryForeground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                color: item.completed ? AppColors.textMuted : AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                decoration: item.completed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Usuń produkt',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _EmptyShoppingList extends StatelessWidget {
  const _EmptyShoppingList();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 52),
      child: Column(
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 38,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 10),
          Text(
            'Lista jest pusta',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
