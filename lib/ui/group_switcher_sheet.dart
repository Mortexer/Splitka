import 'package:flutter/material.dart';

import '../state/household_controller.dart';
import '../storage/local_store.dart';
import 'common_widgets.dart';
import 'room_dialog.dart';

class GroupSwitcherSheet extends StatelessWidget {
  const GroupSwitcherSheet({super.key, required this.controller});

  final HouseholdController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final height = (MediaQuery.sizeOf(context).height * 0.78).clamp(
          400.0,
          680.0,
        );
        return SizedBox(
          height: height,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Twoje grupy',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      controller.groups.length.toString(),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Zamknij',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  key: const ValueKey('group-list'),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: controller.groups.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final group = controller.groups[index];
                    return _GroupRow(
                      group: group,
                      selected: group.id == controller.roomCode,
                      enabled: !controller.busy,
                      canRemove:
                          controller.groups.length > 1 &&
                          group.id != controller.roomCode,
                      onSelected: () => _switchTo(context, group.id),
                      onRemove: () => _remove(context, group),
                    );
                  },
                ),
              ),
              if (controller.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Text(
                    controller.error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: SecondaryActionButton(
                        label: 'Dołącz kodem',
                        icon: Icons.login_rounded,
                        onPressed: controller.busy
                            ? () {}
                            : () => showDialog<void>(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) =>
                                    RoomDialog(controller: controller),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PrimaryActionButton(
                        label: 'Nowa grupa',
                        icon: Icons.add_rounded,
                        enabled: !controller.busy,
                        onPressed: () => _createGroup(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _switchTo(BuildContext context, String groupId) async {
    final switched = await controller.switchGroup(groupId);
    if (switched && context.mounted) Navigator.of(context).pop();
  }

  Future<void> _createGroup(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewGroupDialog(),
    );
    if (name == null || !context.mounted) return;
    final created = await controller.createLocalGroup(name);
    if (!context.mounted) return;
    if (created) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? 'Nie udało się utworzyć grupy.'),
        ),
      );
    }
  }

  Future<void> _remove(BuildContext context, StoredGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Usunąć ${group.name}?'),
        content: Text(
          group.isCloud
              ? 'Grupa zniknie z tego telefonu. Ponowne dołączenie będzie wymagało kodu.'
              : 'Lokalna grupa i jej rachunki zostaną usunięte z tego telefonu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final removed = await controller.removeGroup(group.id);
    if (!removed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? 'Nie udało się usunąć grupy.'),
        ),
      );
    }
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.selected,
    required this.enabled,
    required this.canRemove,
    required this.onSelected,
    required this.onRemove,
  });

  final StoredGroup group;
  final bool selected;
  final bool enabled;
  final bool canRemove;
  final VoidCallback onSelected;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('group-${group.id}'),
      enabled: enabled,
      onTap: selected ? null : onSelected,
      leading: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.16)
              : AppColors.cardAlt,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          group.isCloud ? Icons.cloud_outlined : Icons.phone_android_outlined,
          color: selected ? AppColors.primary : AppColors.textMuted,
          size: 19,
        ),
      ),
      title: Text(
        group.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(group.isCloud ? 'W chmurze' : 'Na tym telefonie'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          if (canRemove)
            IconButton(
              tooltip: 'Usuń grupę z telefonu',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
            ),
        ],
      ),
    );
  }
}

class _NewGroupDialog extends StatefulWidget {
  const _NewGroupDialog();

  @override
  State<_NewGroupDialog> createState() => _NewGroupDialogState();
}

class _NewGroupDialogState extends State<_NewGroupDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: const Text('Nowa grupa'),
      content: TextField(
        key: const ValueKey('new-group-name'),
        controller: _name,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Nazwa grupy'),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: _name.text.trim().isEmpty ? null : _submit,
          child: const Text('Utwórz'),
        ),
      ],
    );
  }

  void _submit() {
    final value = _name.text.trim();
    if (value.isNotEmpty) Navigator.of(context).pop(value);
  }
}
