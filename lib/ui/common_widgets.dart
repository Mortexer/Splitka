import 'package:flutter/material.dart';

import '../domain/money.dart';
import '../domain/models.dart';
import '../domain/settlements.dart';
import '../state/household_controller.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFF0C0E0D);
  static const backgroundSoft = Color(0xFF161816);
  static const card = Color(0xFF161816);
  static const cardAlt = Color(0xFF222523);
  static const muted = Color(0xFF1D1F1D);
  static const border = Color(0xFF2F3530);
  static const borderSoft = Color(0xFF2F3530);
  static const text = Color(0xFFE7E8E5);
  static const textMuted = Color(0xFF91938F);
  static const primary = Color(0xFF45B164);
  static const primaryForeground = Color(0xFF061308);
  static const blue = Color(0xFF499FE3);
  static const amber = Color(0xFFF2AF48);
  static const danger = Color(0xFFE24947);
  static const danus = Color(0xFF45B164);
  static const kubus = Color(0xFF499FE3);
  static const damian = Color(0xFFF59740);
}

ThemeData buildAppTheme() {
  final theme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.background,
      primary: AppColors.primary,
      error: AppColors.danger,
    ),
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.border,
    splashFactory: InkRipple.splashFactory,
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.card,
      indicatorColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundSoft,
      hintStyle: const TextStyle(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    ),
  );

  return theme.copyWith(
    textTheme: _withoutLetterSpacing(theme.textTheme),
    primaryTextTheme: _withoutLetterSpacing(theme.primaryTextTheme),
  );
}

TextTheme _withoutLetterSpacing(TextTheme theme) {
  TextStyle? zero(TextStyle? style) => style?.copyWith(letterSpacing: 0);

  return theme.copyWith(
    displayLarge: zero(theme.displayLarge),
    displayMedium: zero(theme.displayMedium),
    displaySmall: zero(theme.displaySmall),
    headlineLarge: zero(theme.headlineLarge),
    headlineMedium: zero(theme.headlineMedium),
    headlineSmall: zero(theme.headlineSmall),
    titleLarge: zero(theme.titleLarge),
    titleMedium: zero(theme.titleMedium),
    titleSmall: zero(theme.titleSmall),
    bodyLarge: zero(theme.bodyLarge),
    bodyMedium: zero(theme.bodyMedium),
    bodySmall: zero(theme.bodySmall),
    labelLarge: zero(theme.labelLarge),
    labelMedium: zero(theme.labelMedium),
    labelSmall: zero(theme.labelSmall),
  );
}

class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: child,
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.meta, this.icon});

  final String title;
  final String? meta;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.primary, size: 17),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (meta != null)
          Text(
            meta!,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
        disabledForegroundColor: AppColors.primaryForeground.withValues(
          alpha: 0.6,
        ),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class SecondaryActionButton extends StatelessWidget {
  const SecondaryActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.text;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
      style: OutlinedButton.styleFrom(
        backgroundColor: danger
            ? AppColors.danger.withValues(alpha: 0.14)
            : AppColors.card,
        foregroundColor: color,
        side: BorderSide(
          color: danger
              ? AppColors.danger.withValues(alpha: 0.42)
              : AppColors.border,
        ),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.person, this.size = 28});

  final Person person;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: personDisplayColor(person),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 2),
      ),
      child: Text(
        personInitials(person),
        style: TextStyle(
          color: Colors.white,
          fontSize: (size * 0.38).clamp(10.0, 14.0),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class PersonChoice extends StatelessWidget {
  const PersonChoice({
    super.key,
    required this.person,
    required this.selected,
    required this.onPressed,
  });

  final Person person;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? AppColors.primary.withValues(alpha: 0.14)
            : AppColors.card,
        foregroundColor: selected ? AppColors.text : AppColors.textMuted,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          PersonAvatar(person: person, size: 24),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              person.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class PersonSelector extends StatelessWidget {
  const PersonSelector({
    super.key,
    required this.members,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Person> members;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (members.length <= 3) {
      return Row(
        children: [
          for (var index = 0; index < members.length; index++) ...[
            if (index > 0) const SizedBox(width: 7),
            Expanded(child: _choice(members[index])),
          ],
        ],
      );
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (_, index) =>
            SizedBox(width: 112, child: _choice(members[index])),
      ),
    );
  }

  Widget _choice(Person person) {
    return PersonChoice(
      person: person,
      selected: selectedId == person.id,
      onPressed: () => onSelected(person.id),
    );
  }
}

class MemberAvatarStack extends StatelessWidget {
  const MemberAvatarStack({
    super.key,
    required this.members,
    this.maxVisible = 3,
  });

  final List<Person> members;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final visible = members.take(maxVisible).toList();
    final hiddenCount = members.length - visible.length;
    final stackWidth = visible.isEmpty
        ? 0.0
        : 28.0 + (visible.length - 1) * 17.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: stackWidth,
          height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < visible.length; index++)
                Positioned(
                  left: index * 17,
                  child: PersonAvatar(person: visible[index], size: 28),
                ),
            ],
          ),
        ),
        if (hiddenCount > 0) ...[
          const SizedBox(width: 6),
          Text(
            '+$hiddenCount',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class PersonChip extends StatelessWidget {
  const PersonChip({
    super.key,
    required this.person,
    required this.selected,
    required this.onPressed,
  });

  final Person person;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onPressed(),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: selected ? Colors.white : personDisplayColor(person),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(person.name),
        ],
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
      backgroundColor: AppColors.cardAlt,
      selectedColor: personDisplayColor(person),
      side: BorderSide(color: selected ? Colors.transparent : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class SyncBadge extends StatelessWidget {
  const SyncBadge({
    super.key,
    required this.syncState,
    required this.error,
    this.compact = false,
  });

  final SyncState syncState;
  final String? error;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final failed = syncState == SyncState.error || error != null;
    final online = syncState == SyncState.online;
    final saving = syncState == SyncState.saving;
    final connecting =
        syncState == SyncState.loading || syncState == SyncState.connecting;
    final label = failed
        ? 'Błąd'
        : switch (syncState) {
            SyncState.loading => 'Ładowanie',
            SyncState.connecting => 'Łączenie',
            SyncState.saving => 'Zapis',
            SyncState.online => 'Chmura',
            SyncState.offline => 'Offline',
            SyncState.local => 'Lokalnie',
            SyncState.error => 'Błąd',
          };
    final icon = online
        ? Icons.cloud_done_rounded
        : connecting || saving
        ? Icons.sync_rounded
        : Icons.cloud_off_rounded;
    final color = failed
        ? AppColors.danger
        : online
        ? AppColors.primary
        : saving
        ? AppColors.amber
        : AppColors.blue;

    final badge = Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10),
      decoration: BoxDecoration(
        color: failed
            ? AppColors.danger.withValues(alpha: 0.14)
            : AppColors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: failed
              ? AppColors.danger.withValues(alpha: 0.42)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          if (!compact) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: failed ? AppColors.danger : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );

    return compact ? Tooltip(message: label, child: badge) : badge;
  }
}

class MoneyRow extends StatelessWidget {
  const MoneyRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color = AppColors.text,
    this.strong = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 7),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: strong ? 16 : 13,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      PillTone.green => AppColors.primary,
      PillTone.amber => AppColors.amber,
      PillTone.muted => AppColors.textMuted,
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

enum PillTone { green, amber, muted }

class SettlementCard extends StatelessWidget {
  const SettlementCard({
    super.key,
    required this.settlement,
    required this.members,
  });

  final Settlement settlement;
  final List<Person> members;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Rozliczenie',
            icon: Icons.account_balance_wallet_rounded,
          ),
          const SizedBox(height: 12),
          _BalanceStrip(settlement: settlement, members: members),
          const SizedBox(height: 12),
          if (settlement.transfers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_rounded, color: AppColors.primary, size: 17),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Wszystko rozliczone',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: settlement.transfers.map((transfer) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      PersonAvatar(
                        person: _personFor(
                          members,
                          transfer.fromPersonId,
                          transfer.fromName,
                        ),
                        size: 24,
                      ),
                      const SizedBox(width: 7),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.textMuted,
                        size: 15,
                      ),
                      const SizedBox(width: 7),
                      PersonAvatar(
                        person: _personFor(
                          members,
                          transfer.toPersonId,
                          transfer.toName,
                        ),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${transfer.fromName} → ${transfer.toName}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        formatMoney(transfer.amountCents),
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          if (settlement.unassignedCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Nieprzypisane pozycje: ${settlement.unassignedCount}',
                style: const TextStyle(
                  color: AppColors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BalanceStrip extends StatelessWidget {
  const _BalanceStrip({required this.settlement, required this.members});

  final Settlement settlement;
  final List<Person> members;

  @override
  Widget build(BuildContext context) {
    if (settlement.balances.length <= 3) {
      return Row(
        children: [
          for (var index = 0; index < settlement.balances.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(
              child: _BalanceTile(
                balance: settlement.balances[index],
                person: _personFor(
                  members,
                  settlement.balances[index].personId,
                  settlement.balances[index].name,
                ),
              ),
            ),
          ],
        ],
      );
    }

    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: settlement.balances.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final balance = settlement.balances[index];
          return SizedBox(
            width: 92,
            child: _BalanceTile(
              balance: balance,
              person: _personFor(members, balance.personId, balance.name),
            ),
          );
        },
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.balance, required this.person});

  final PersonBalance balance;
  final Person person;

  @override
  Widget build(BuildContext context) {
    final positive = balance.balanceCents > 0;
    final negative = balance.balanceCents < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          PersonAvatar(person: person, size: 28),
          const SizedBox(height: 4),
          Text(
            balance.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            balance.balanceCents == 0
                ? '—'
                : '${positive ? '+' : '−'}${formatMoney(balance.balanceCents.abs())}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: positive
                  ? AppColors.primary
                  : negative
                  ? AppColors.danger
                  : AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

Person _personFor(List<Person> members, String id, String name) {
  for (final person in members) {
    if (person.id == id) return person;
  }
  return Person(id: id, name: name, color: AppColors.primary.toARGB32());
}

String initials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  final first = words.isEmpty ? '' : words.first[0];
  final second = words.length > 1
      ? words[1][0]
      : (words.isEmpty || words.first.length < 2 ? '' : words.first[1]);
  return '$first$second'.toUpperCase();
}

Color personDisplayColor(Person person) => Color(person.color);

String personInitials(Person person) {
  final name = person.name.trim();
  if (name.isEmpty) return '?';
  final words = name.split(RegExp(r'\s+'));
  if (words.length > 1) {
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
  final end = name.length < 2 ? 1 : 2;
  final short = name.substring(0, end).toLowerCase();
  return '${short[0].toUpperCase()}${short.substring(1)}';
}

String formatReceiptDate(String? value) {
  if (value == null) {
    return 'bez daty';
  }

  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) {
    return 'bez daty';
  }

  return '${_two(date.day)}.${_two(date.month)}.${date.year} ${_two(date.hour)}:${_two(date.minute)}';
}

String formatShortReceiptDate(String? value) {
  if (value == null) {
    return '';
  }

  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) {
    return '';
  }

  return '${_two(date.day)}.${_two(date.month)}';
}

int receiptCashTotal(Receipt receipt) {
  return receipt.grossCents - receipt.depositReturnCents;
}

String _two(int value) {
  return value.toString().padLeft(2, '0');
}
