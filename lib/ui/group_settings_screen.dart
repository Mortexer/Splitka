import 'package:flutter/material.dart';

import '../domain/groups.dart';
import '../domain/models.dart';
import '../state/household_controller.dart';
import 'common_widgets.dart';
import 'room_dialog.dart';

class GroupSettingsScreen extends StatelessWidget {
  const GroupSettingsScreen({super.key, required this.controller});

  final HouseholdController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final household = controller.household;
        return Scaffold(
          body: SafeArea(
            child: PageFrame(
              child: Column(
                children: [
                  _GroupHeader(controller: controller),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
                      children: [
                        _GroupNameCard(
                          household: household,
                          enabled: !controller.busy,
                          onEdit: () => _renameGroup(context),
                        ),
                        const SizedBox(height: 18),
                        SectionHeader(
                          title: 'Osoby',
                          meta:
                              '${household.activeMembers.length} aktywne · ${household.members.length}/$maxHouseholdMembers',
                          icon: Icons.group_outlined,
                        ),
                        const SizedBox(height: 10),
                        for (final person in household.members) ...[
                          _MemberCard(
                            person: person,
                            canChange: !controller.busy,
                            canDeactivate:
                                !person.active ||
                                household.activeMembers.length > 1,
                            canRemove:
                                household.members.length > 1 &&
                                !memberHasData(household, person.id),
                            onEdit: () => _editMember(context, person),
                            onToggleActive: (active) =>
                                _toggleMember(context, person, active),
                            onRemove: () => _removeMember(context, person),
                          ),
                          const SizedBox(height: 8),
                        ],
                        PrimaryActionButton(
                          label: household.members.length >= maxHouseholdMembers
                              ? 'Limit 20 osób'
                              : 'Dodaj osobę',
                          icon: Icons.person_add_alt_1_rounded,
                          enabled:
                              !controller.busy &&
                              household.members.length < maxHouseholdMembers,
                          onPressed: () => _addMember(context),
                        ),
                        const SizedBox(height: 18),
                        _SharingCard(
                          controller: controller,
                          onPressed: () => showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => RoomDialog(controller: controller),
                          ),
                        ),
                        if (controller.error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            controller.error!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _renameGroup(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(
        title: 'Nazwa grupy',
        initialValue: controller.household.name,
        maxLength: 40,
      ),
    );
    if (name == null || !context.mounted) return;
    await _showSaveResult(
      context,
      controller.renameCurrentGroup(name),
      'Nazwa grupy zmieniona.',
    );
  }

  Future<void> _addMember(BuildContext context) async {
    final draft = await showDialog<_MemberDraft>(
      context: context,
      builder: (_) => _MemberEditorDialog(
        title: 'Nowa osoba',
        initialColor:
            memberColorPalette[controller.household.members.length %
                memberColorPalette.length],
      ),
    );
    if (draft == null || !context.mounted) return;
    await _showSaveResult(
      context,
      controller.addMember(draft.name, draft.color),
      '${draft.name.trim()} dodany(a) do grupy.',
    );
  }

  Future<void> _editMember(BuildContext context, Person person) async {
    final draft = await showDialog<_MemberDraft>(
      context: context,
      builder: (_) => _MemberEditorDialog(
        title: 'Edytuj osobę',
        initialName: person.name,
        initialColor: person.color,
      ),
    );
    if (draft == null || !context.mounted) return;
    await _showSaveResult(
      context,
      controller.updateMember(person.id, draft.name, draft.color),
      'Dane osoby zaktualizowane.',
    );
  }

  Future<void> _toggleMember(
    BuildContext context,
    Person person,
    bool active,
  ) async {
    if (!active) {
      final confirmed = await _confirm(
        context,
        title: 'Dezaktywować ${person.name}?',
        message:
            'Osoba zniknie z nowych rachunków i pustych list. Dotychczasowe rozliczenia zostaną bez zmian.',
        confirmLabel: 'Dezaktywuj',
      );
      if (!confirmed || !context.mounted) return;
    }
    await _showSaveResult(
      context,
      controller.setMemberActive(person.id, active),
      active
          ? '${person.name} jest aktywny(a).'
          : '${person.name} dezaktywowany(a).',
    );
  }

  Future<void> _removeMember(BuildContext context, Person person) async {
    final confirmed = await _confirm(
      context,
      title: 'Usunąć ${person.name}?',
      message: 'Osoba zostanie trwale usunięta z grupy.',
      confirmLabel: 'Usuń',
    );
    if (!confirmed || !context.mounted) return;
    await _showSaveResult(
      context,
      controller.removeMember(person.id),
      '${person.name} usunięty(a) z grupy.',
    );
  }

  Future<void> _showSaveResult(
    BuildContext context,
    Future<bool> operation,
    String successMessage,
  ) async {
    final saved = await operation;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? successMessage
              : controller.error ?? 'Nie udało się zapisać zmiany.',
        ),
      ),
    );
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.controller});

  final HouseholdController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Wróć',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 2),
          const Expanded(
            child: Text(
              'Grupa',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SyncBadge(
            syncState: controller.syncState,
            error: controller.error,
            compact: MediaQuery.sizeOf(context).width <= 360,
          ),
        ],
      ),
    );
  }
}

class _GroupNameCard extends StatelessWidget {
  const _GroupNameCard({
    required this.household,
    required this.enabled,
    required this.onEdit,
  });

  final Household household;
  final bool enabled;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.groups_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NAZWA GRUPY',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  household.name,
                  key: const ValueKey('group-name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('edit-group-name'),
            tooltip: 'Zmień nazwę grupy',
            onPressed: enabled ? onEdit : null,
            icon: const Icon(Icons.edit_outlined, size: 19),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.person,
    required this.canChange,
    required this.canDeactivate,
    required this.canRemove,
    required this.onEdit,
    required this.onToggleActive,
    required this.onRemove,
  });

  final Person person;
  final bool canChange;
  final bool canDeactivate;
  final bool canRemove;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
      child: Row(
        children: [
          PersonAvatar(person: person, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                StatusPill(
                  label: person.active ? 'AKTYWNA' : 'NIEAKTYWNA',
                  tone: person.active ? PillTone.green : PillTone.muted,
                ),
              ],
            ),
          ),
          PopupMenuButton<_MemberAction>(
            key: ValueKey('member-actions-${person.id}'),
            tooltip: 'Opcje osoby',
            enabled: canChange,
            icon: const Icon(Icons.more_vert_rounded, size: 19),
            onSelected: (action) {
              switch (action) {
                case _MemberAction.edit:
                  onEdit();
                case _MemberAction.remove:
                  onRemove();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _MemberAction.edit,
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edytuj'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _MemberAction.remove,
                enabled: canRemove,
                child: ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: Text(
                    canRemove ? 'Usuń' : 'Nie można usunąć: osoba ma dane',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          Switch(
            key: ValueKey('active-member-${person.id}'),
            value: person.active,
            onChanged: canChange && (canDeactivate || !person.active)
                ? onToggleActive
                : null,
          ),
        ],
      ),
    );
  }
}

class _SharingCard extends StatelessWidget {
  const _SharingCard({required this.controller, required this.onPressed});

  final HouseholdController controller;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Udostępnianie',
            meta: controller.isCloudRoom ? 'CHMURA' : 'LOKALNIE',
            icon: controller.isCloudRoom
                ? Icons.cloud_done_outlined
                : Icons.phone_android_outlined,
          ),
          const SizedBox(height: 12),
          SecondaryActionButton(
            label: controller.isCloudRoom
                ? 'Kod i ustawienia chmury'
                : 'Połącz grupę z chmurą',
            icon: Icons.ios_share_rounded,
            onPressed: controller.busy ? () {} : onPressed,
          ),
        ],
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.initialValue,
    required this.maxLength,
  });

  final String title;
  final String initialValue;
  final int maxLength;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue)
      ..selection = TextSelection.collapsed(offset: widget.initialValue.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(widget.title),
      content: TextField(
        key: const ValueKey('group-name-input'),
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Nazwa'),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty ? null : _submit,
          child: const Text('Zapisz'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }
}

class _MemberEditorDialog extends StatefulWidget {
  const _MemberEditorDialog({
    required this.title,
    required this.initialColor,
    this.initialName = '',
  });

  final String title;
  final String initialName;
  final int initialColor;

  @override
  State<_MemberEditorDialog> createState() => _MemberEditorDialogState();
}

class _MemberEditorDialogState extends State<_MemberEditorDialog> {
  late final TextEditingController _nameController;
  late int _color;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _color = widget.initialColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('member-name-input'),
              controller: _nameController,
              autofocus: true,
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Imię'),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kolor',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in memberColorPalette)
                  Semantics(
                    button: true,
                    selected: _color == color,
                    label: 'Wybierz kolor',
                    child: InkWell(
                      key: ValueKey('member-color-$color'),
                      onTap: () => setState(() => _color = color),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _color == color
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: _color == color
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 19,
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty ? null : _submit,
          child: const Text('Zapisz'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(_MemberDraft(name, _color));
  }
}

class _MemberDraft {
  const _MemberDraft(this.name, this.color);

  final String name;
  final int color;
}

enum _MemberAction { edit, remove }
