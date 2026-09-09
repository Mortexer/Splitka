import 'package:flutter/material.dart';

import '../domain/money.dart';
import '../domain/models.dart';
import '../domain/settlements.dart';
import '../state/household_controller.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFF101711);
  static const backgroundSoft = Color(0xFF141D17);
  static const card = Color(0xFF1A251E);
  static const cardAlt = Color(0xFF223027);
  static const muted = Color(0xFF2C3A31);
  static const border = Color(0xFF344438);
  static const borderSoft = Color(0xFF29382F);
  static const text = Color(0xFFF1F7EF);
  static const textMuted = Color(0xFFA8B7AB);
  static const primary = Color(0xFF64D487);
  static const primaryForeground = Color(0xFF0D1710);
  static const blue = Color(0xFF7DA8FF);
  static const amber = Color(0xFFF1C763);
  static const danger = Color(0xFFF36F62);
}

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.background,
      primary: AppColors.primary,
      error: AppColors.danger,
    ),
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: AppColors.background,
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
        color: Color(person.color),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 2),
      ),
      child: Text(
        initials(person.name),
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
          color: selected ? Color(person.color) : AppColors.border,
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
              color: selected ? Colors.white : Color(person.color),
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
      selectedColor: Color(person.color),
      side: BorderSide(color: selected ? Colors.transparent : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key, required this.syncState, required this.error});

  final SyncState syncState;
  final String? error;

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

    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
      ),
    );
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
    this.compact = false,
  });

  final Settlement settlement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Rozliczenie',
            meta: formatMoney(settlement.includedCents),
            icon: Icons.account_balance_wallet_rounded,
          ),
          const SizedBox(height: 12),
          Row(
            children: settlement.balances.map((balance) {
              final positive = balance.balanceCents > 0;
              final negative = balance.balanceCents < 0;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
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
                      const SizedBox(height: 6),
                      Text(
                        balance.balanceCents == 0
                            ? '0,00 zł'
                            : '${positive ? '+' : ''}${formatMoney(balance.balanceCents)}',
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
                      if (!compact) ...[
                        const SizedBox(height: 5),
                        Text(
                          'udział ${formatMoney(balance.shareCents)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
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
                  Text(
                    'Wszystko rozliczone',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
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
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                transfer.fromName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 7),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.textMuted,
                                size: 15,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                transfer.toName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
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
