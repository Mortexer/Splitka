String formatMoney(int cents) {
  final sign = cents < 0 ? '-' : '';
  final absolute = cents.abs();
  final zloty = absolute ~/ 100;
  final grosze = (absolute % 100).toString().padLeft(2, '0');

  return '$sign$zloty,$grosze zł';
}

String formatMoneyInput(int cents) {
  final sign = cents < 0 ? '-' : '';
  final absolute = cents.abs();
  final zloty = absolute ~/ 100;
  final grosze = (absolute % 100).toString().padLeft(2, '0');

  return '$sign$zloty,$grosze';
}

int? parseMoneyInput(String value) {
  final normalized = value
      .trim()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(',', '.');

  if (!RegExp(r'^-?\d+(\.\d{1,2})?$').hasMatch(normalized)) {
    return null;
  }

  final parsed = double.tryParse(normalized);
  if (parsed == null || !parsed.isFinite) {
    return null;
  }

  return (parsed * 100).round();
}

Map<String, int> splitCents(int totalCents, List<String> participantIds) {
  if (participantIds.isEmpty) {
    return {};
  }

  final sign = totalCents < 0 ? -1 : 1;
  final absolute = totalCents.abs();
  final base = absolute ~/ participantIds.length;
  final remainder = absolute % participantIds.length;
  final shares = <String, int>{};

  for (var index = 0; index < participantIds.length; index += 1) {
    shares[participantIds[index]] = sign * (base + (index < remainder ? 1 : 0));
  }

  return shares;
}
