import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/household_controller.dart';
import 'common_widgets.dart';

class RoomDialog extends StatefulWidget {
  const RoomDialog({super.key, required this.controller});

  final HouseholdController controller;

  @override
  State<RoomDialog> createState() => _RoomDialogState();
}

class _RoomDialogState extends State<RoomDialog> {
  final _code = TextEditingController();
  bool _working = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<bool> Function() operation) async {
    if (_working) return;
    setState(() => _working = true);
    final success = await operation();
    if (!mounted) return;
    setState(() => _working = false);
    if (success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return PopScope(
      canPop: !_working,
      child: AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Mieszkanie'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (controller.isCloudRoom && controller.inviteCode != null) ...[
                const Text('Kod zaproszenia'),
                const SizedBox(height: 8),
                SelectableText(
                  controller.inviteCode!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Kopiuj kod zaproszenia',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: controller.inviteCode!),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kod skopiowany.')),
                      );
                    },
                  ),
                ),
                const Divider(),
              ],
              if (!controller.isCloudRoom) ...[
                FilledButton.icon(
                  onPressed: _working || !controller.canUseCloud
                      ? null
                      : () => _run(controller.createCloudRoom),
                  icon: const Icon(Icons.add_home_outlined),
                  label: const Text('Utwórz mieszkanie'),
                ),
                if (controller.household.receipts.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Bieżące rachunki zostaną dodane do mieszkania.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                const Divider(height: 24),
              ],
              TextField(
                controller: _code,
                enabled: !_working && controller.canUseCloud,
                autocorrect: false,
                enableSuggestions: false,
                maxLength: 64,
                decoration: const InputDecoration(
                  labelText: 'Kod zaproszenia',
                  counterText: '',
                ),
                onSubmitted: (_) =>
                    _run(() => controller.joinCloudRoom(_code.text)),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _working || !controller.canUseCloud
                    ? null
                    : () => _run(() => controller.joinCloudRoom(_code.text)),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Dołącz do mieszkania'),
              ),
              if (_working) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (controller.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  controller.error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (controller.isCloudRoom)
            TextButton(
              onPressed: _working ? null : () => _run(controller.useLocalMode),
              child: const Text('Rachunki lokalne'),
            ),
          TextButton(
            onPressed: _working ? null : () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }
}
