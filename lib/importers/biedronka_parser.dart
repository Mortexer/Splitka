import 'dart:convert';

import '../domain/models.dart';

class ImportResult {
  const ImportResult({
    required this.receipt,
    required this.warnings,
  });

  final Receipt receipt;
  final List<String> warnings;
}

ImportResult parseBiedronkaReceipt(String rawJson, List<Person> members) {
  final root = _parseJsonObject(rawJson);
  final signedParagon = _readSignedParagon(root);

  if (signedParagon != null) {
    return _buildReceiptFromSignedParagon(signedParagon, members);
  }

  return _buildReceiptFromPrintedBody(root, members);
}

ImportResult _buildReceiptFromSignedParagon(Map<String, dynamic> paragon, List<Person> members) {
  final positions = _ensureList(paragon['pozycja'], 'Brak pozycji paragonu w payloadzie.');
  final receiptNumber = _optionalString(paragon['nrParag']);
  final boughtAt = _optionalString(paragon['zakSprzed']);
  final memberIds = members.map((person) => person.id).toList();
  final warnings = <String>[];
  final items = <ReceiptItem>[];

  for (var index = 0; index < positions.length; index += 1) {
    final position = _asMap(positions[index]);
    final goods = _asMap(position?['towar']);

    if (goods == null) {
      warnings.add('Pominięto pozycję ${index + 1}: brak danych towaru.');
      continue;
    }

    final totalCents = _optionalInt(goods['brutto']);
    if (totalCents == null) {
      warnings.add('Pominięto pozycję ${index + 1}: brak kwoty brutto.');
      continue;
    }

    items.add(
      ReceiptItem(
        id: 'item-${index + 1}',
        name: _cleanProductName(_optionalString(goods['nazwa']) ?? 'Pozycja ${index + 1}'),
        quantity: _optionalString(goods['ilosc']) ?? '1',
        totalCents: totalCents,
        unitPriceCents: _optionalInt(goods['cena']),
        vatId: _optionalString(goods['idStPTU']),
        kind: ReceiptItemKind.product,
      ),
    );
  }

  final depositCents = _optionalInt(_asMap(paragon['opak'])?['wart']) ?? 0;
  final depositReturnCents = _readDepositReturnCents(paragon);

  if (depositReturnCents > 0) {
    items.add(
      const ReceiptItem(
        id: 'deposit-return',
        name: 'Zwrot opakowań',
        quantity: '1',
        totalCents: 0,
        kind: ReceiptItemKind.depositReturn,
      ).copyWith(totalCents: -depositReturnCents),
    );
  }

  final assignments = {
    for (final item in items)
      item.id: createAssignment(
        item.id,
        item.kind == ReceiptItemKind.depositReturn ? memberIds : const [],
      ),
  };
  final productGross = items
      .where((item) => item.kind == ReceiptItemKind.product)
      .fold(0, (sum, item) => sum + item.totalCents);
  final summary = _asMap(paragon['podsum']);

  return ImportResult(
    receipt: Receipt(
      id: _makeReceiptId(receiptNumber),
      title: _buildReceiptTitle(receiptNumber, boughtAt),
      storeName: 'Biedronka',
      receiptNumber: receiptNumber,
      boughtAt: boughtAt,
      importedAt: DateTime.now().toIso8601String(),
      payerId: members.isNotEmpty ? members.first.id : 'danus',
      items: items,
      assignments: assignments,
      grossCents: _optionalInt(summary?['sumaBrutto']) ?? productGross,
      depositCents: depositCents,
      depositReturnCents: depositReturnCents,
      discountCents: (_optionalInt(summary?['sumaOpust']) ?? 0).abs(),
    ),
    warnings: warnings,
  );
}

ImportResult _buildReceiptFromPrintedBody(Map<String, dynamic> root, List<Person> members) {
  final body = _ensureList(root['body'], 'Ten JSON nie wygląda jak paragon Biedronki.');
  final memberIds = members.map((person) => person.id).toList();
  final warnings = ['Użyto awaryjnego importu z widoku paragonu.'];
  final items = <ReceiptItem>[];
  int? pendingItemIndex;
  var depositCents = 0;
  var depositReturnCents = 0;

  for (final line in body) {
    final record = _asMap(line);
    final sellLine = _asMap(record?['sellLine']);
    final discountLine = _asMap(record?['discountLine']);
    final pack = _asMap(record?['pack']);
    final payment = _asMap(record?['payment']);

    if (sellLine != null) {
      final totalCents = _optionalInt(sellLine['total']);

      if (totalCents == null) {
        warnings.add('Pominięto pozycję ${items.length + 1}: brak kwoty.');
      } else {
        pendingItemIndex = items.length;
        items.add(
          ReceiptItem(
            id: 'item-${items.length + 1}',
            name: _cleanProductName(_optionalString(sellLine['name']) ?? 'Pozycja ${items.length + 1}'),
            quantity: _optionalString(sellLine['quantity']) ?? '1',
            totalCents: totalCents,
            unitPriceCents: _optionalInt(sellLine['price']),
            vatId: _optionalString(sellLine['vatId']),
            kind: ReceiptItemKind.product,
          ),
        );
      }
    }

    if (discountLine != null && pendingItemIndex != null) {
      final discountValue = (_optionalInt(discountLine['value']) ?? 0).abs();
      final item = items[pendingItemIndex];
      items[pendingItemIndex] = item.copyWith(totalCents: item.totalCents - discountValue);
    }

    if (pack != null) {
      depositCents += _optionalInt(pack['total']) ?? 0;
    }

    if (payment != null && _lower(_optionalString(payment['name'])).contains('zwrot opak')) {
      depositReturnCents += _optionalInt(payment['amount']) ?? 0;
    }
  }

  if (depositReturnCents > 0) {
    items.add(
      ReceiptItem(
        id: 'deposit-return',
        name: 'Zwrot opakowań',
        quantity: '1',
        totalCents: -depositReturnCents,
        kind: ReceiptItemKind.depositReturn,
      ),
    );
  }

  final assignments = {
    for (final item in items)
      item.id: createAssignment(
        item.id,
        item.kind == ReceiptItemKind.depositReturn ? memberIds : const [],
      ),
  };
  final footer = body
      .map(_asMap)
      .map((line) => _asMap(line?['fiscalFooter']))
      .whereType<Map<String, dynamic>>()
      .firstOrNull;
  final receiptNumber = _optionalString(footer?['billNumber']);
  final boughtAt = _optionalString(footer?['date']);
  final productGross = items
      .where((item) => item.kind == ReceiptItemKind.product)
      .fold(0, (sum, item) => sum + item.totalCents);

  return ImportResult(
    receipt: Receipt(
      id: _makeReceiptId(receiptNumber),
      title: _buildReceiptTitle(receiptNumber, boughtAt),
      storeName: 'Biedronka',
      receiptNumber: receiptNumber,
      boughtAt: boughtAt,
      importedAt: DateTime.now().toIso8601String(),
      payerId: members.isNotEmpty ? members.first.id : 'danus',
      items: items,
      assignments: assignments,
      grossCents: productGross,
      depositCents: depositCents,
      depositReturnCents: depositReturnCents,
      discountCents: 0,
    ),
    warnings: warnings,
  );
}

Map<String, dynamic>? _readSignedParagon(Map<String, dynamic> root) {
  final token = _optionalString(root['data']);
  if (token == null) {
    return null;
  }

  final parts = token.split('.');
  if (parts.length < 2) {
    return null;
  }

  final decoded = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
  final payload = _parseJsonObject(decoded);
  return _asMap(_asMap(payload['dokument'])?['paragon']);
}

int _readDepositReturnCents(Map<String, dynamic> paragon) {
  return _ensureList(paragon['platnosc'], '').fold(0, (sum, payment) {
    final record = _asMap(payment);
    final name = _lower(_optionalString(record?['nazwa']));

    if (!name.contains('zwrot opak')) {
      return sum;
    }

    return sum + (_optionalInt(record?['wart']) ?? 0);
  });
}

Map<String, dynamic> _parseJsonObject(String json) {
  final parsed = jsonDecode(json);
  final record = _asMap(parsed);

  if (record == null) {
    throw FormatException('JSON musi zawierać obiekt.');
  }

  return record;
}

List<dynamic> _ensureList(Object? value, String message) {
  if (value is List) {
    return value;
  }

  if (message.isNotEmpty) {
    throw FormatException(message);
  }

  return [];
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return null;
}

String? _optionalString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }

  if (value is num && value.isFinite) {
    return value.toString();
  }

  return null;
}

int? _optionalInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num && value.isFinite) {
    return value.round();
  }

  if (value is String) {
    final trimmed = value.trim();
    final parsedInt = int.tryParse(trimmed);
    if (parsedInt != null) {
      return parsedInt;
    }

    final parsedMoney = double.tryParse(trimmed.replaceAll(',', '.'));
    if (parsedMoney != null && parsedMoney.isFinite) {
      return (parsedMoney * 100).round();
    }
  }

  return null;
}

String _cleanProductName(String name) {
  return name.replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'\s+[A-G]$'), '').trim();
}

String _makeReceiptId(String? receiptNumber) {
  final base = receiptNumber == null ? 'biedronka' : 'biedronka-$receiptNumber';
  return '$base-${DateTime.now().millisecondsSinceEpoch}';
}

String _buildReceiptTitle(String? receiptNumber, String? boughtAt) {
  final date = boughtAt == null ? null : DateTime.tryParse(boughtAt);
  final formattedDate = date == null
      ? 'import'
      : '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';

  return receiptNumber == null ? 'Biedronka · $formattedDate' : 'Biedronka #$receiptNumber · $formattedDate';
}

String _lower(String? value) {
  return value?.toLowerCase() ?? '';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
