import 'models.dart';
import 'money.dart';

class ReceiptTotals {
  const ReceiptTotals({
    required this.includedCents,
    required this.skippedCents,
    required this.unassignedCents,
    required this.assignedCount,
    required this.skippedCount,
    required this.unassignedCount,
  });

  final int includedCents;
  final int skippedCents;
  final int unassignedCents;
  final int assignedCount;
  final int skippedCount;
  final int unassignedCount;
}

class PersonBalance {
  const PersonBalance({
    required this.personId,
    required this.name,
    required this.paidCents,
    required this.shareCents,
    required this.balanceCents,
  });

  final String personId;
  final String name;
  final int paidCents;
  final int shareCents;
  final int balanceCents;
}

class Transfer {
  const Transfer({
    required this.fromPersonId,
    required this.fromName,
    required this.toPersonId,
    required this.toName,
    required this.amountCents,
  });

  final String fromPersonId;
  final String fromName;
  final String toPersonId;
  final String toName;
  final int amountCents;
}

class Settlement {
  const Settlement({
    required this.balances,
    required this.transfers,
    required this.includedCents,
    required this.unassignedCount,
  });

  final List<PersonBalance> balances;
  final List<Transfer> transfers;
  final int includedCents;
  final int unassignedCount;
}

ItemAssignment getAssignment(Receipt receipt, String itemId) {
  return receipt.assignments[itemId] ?? createAssignment(itemId);
}

ReceiptTotals getReceiptTotals(Receipt receipt) {
  var includedCents = 0;
  var skippedCents = 0;
  var unassignedCents = 0;
  var assignedCount = 0;
  var skippedCount = 0;
  var unassignedCount = 0;

  for (final item in receipt.items) {
    final assignment = getAssignment(receipt, item.id);

    if (assignment.skipped) {
      skippedCents += item.totalCents;
      skippedCount += 1;
      continue;
    }

    if (assignment.participantIds.isEmpty) {
      unassignedCents += item.totalCents;
      unassignedCount += 1;
      continue;
    }

    includedCents += item.totalCents;
    assignedCount += 1;
  }

  return ReceiptTotals(
    includedCents: includedCents,
    skippedCents: skippedCents,
    unassignedCents: unassignedCents,
    assignedCount: assignedCount,
    skippedCount: skippedCount,
    unassignedCount: unassignedCount,
  );
}

Map<String, int> calculateReceiptShares(Receipt receipt) {
  final shares = <String, int>{};

  for (final item in receipt.items) {
    final assignment = getAssignment(receipt, item.id);

    if (assignment.skipped || assignment.participantIds.isEmpty) {
      continue;
    }

    for (final entry in splitCents(
      item.totalCents,
      assignment.participantIds,
    ).entries) {
      shares[entry.key] = (shares[entry.key] ?? 0) + entry.value;
    }
  }

  return shares;
}

Settlement calculateSettlement(Household household) {
  final memberById = {
    for (final person in household.members) person.id: person,
  };
  final paid = {for (final person in household.members) person.id: 0};
  final shares = {for (final person in household.members) person.id: 0};
  var includedCents = 0;
  var unassignedCount = 0;

  for (final receipt in household.receipts) {
    final totals = getReceiptTotals(receipt);
    final receiptShares = calculateReceiptShares(receipt);

    paid[receipt.payerId] = (paid[receipt.payerId] ?? 0) + totals.includedCents;
    includedCents += totals.includedCents;
    unassignedCount += totals.unassignedCount;

    for (final entry in receiptShares.entries) {
      shares[entry.key] = (shares[entry.key] ?? 0) + entry.value;
    }
  }

  final balances = household.members.map((person) {
    final paidCents = paid[person.id] ?? 0;
    final shareCents = shares[person.id] ?? 0;

    return PersonBalance(
      personId: person.id,
      name: person.name,
      paidCents: paidCents,
      shareCents: shareCents,
      balanceCents: paidCents - shareCents,
    );
  }).toList();

  return Settlement(
    balances: balances,
    transfers: _buildTransfers(balances, memberById),
    includedCents: includedCents,
    unassignedCount: unassignedCount,
  );
}

Receipt updateReceiptAssignment(
  Receipt receipt,
  String itemId,
  ItemAssignment Function(ItemAssignment assignment) updater,
) {
  final next = updater(getAssignment(receipt, itemId));

  return receipt.copyWith(assignments: {...receipt.assignments, itemId: next});
}

int? getItemSharePreview(ReceiptItem item, ItemAssignment assignment) {
  if (assignment.skipped || assignment.participantIds.isEmpty) {
    return null;
  }

  return item.totalCents ~/ assignment.participantIds.length;
}

List<Transfer> _buildTransfers(
  List<PersonBalance> balances,
  Map<String, Person> memberById,
) {
  final creditors =
      balances
          .where((balance) => balance.balanceCents > 0)
          .map(_MutableCreditor.fromBalance)
          .toList()
        ..sort((a, b) => b.balanceCents.compareTo(a.balanceCents));
  final debtors =
      balances
          .where((balance) => balance.balanceCents < 0)
          .map(_MutableDebtor.fromBalance)
          .toList()
        ..sort((a, b) => b.debtCents.compareTo(a.debtCents));
  final transfers = <Transfer>[];

  var creditorIndex = 0;
  var debtorIndex = 0;

  while (creditorIndex < creditors.length && debtorIndex < debtors.length) {
    final creditor = creditors[creditorIndex];
    final debtor = debtors[debtorIndex];
    final amountCents = creditor.balanceCents < debtor.debtCents
        ? creditor.balanceCents
        : debtor.debtCents;

    if (amountCents > 0) {
      transfers.add(
        Transfer(
          fromPersonId: debtor.personId,
          fromName: memberById[debtor.personId]?.name ?? debtor.name,
          toPersonId: creditor.personId,
          toName: memberById[creditor.personId]?.name ?? creditor.name,
          amountCents: amountCents,
        ),
      );
    }

    creditor.balanceCents -= amountCents;
    debtor.debtCents -= amountCents;

    if (creditor.balanceCents == 0) {
      creditorIndex += 1;
    }

    if (debtor.debtCents == 0) {
      debtorIndex += 1;
    }
  }

  return transfers;
}

class _MutableCreditor {
  _MutableCreditor({
    required this.personId,
    required this.name,
    required this.balanceCents,
  });

  factory _MutableCreditor.fromBalance(PersonBalance balance) {
    return _MutableCreditor(
      personId: balance.personId,
      name: balance.name,
      balanceCents: balance.balanceCents,
    );
  }

  final String personId;
  final String name;
  int balanceCents;
}

class _MutableDebtor {
  _MutableDebtor({
    required this.personId,
    required this.name,
    required this.debtCents,
  });

  factory _MutableDebtor.fromBalance(PersonBalance balance) {
    return _MutableDebtor(
      personId: balance.personId,
      name: balance.name,
      debtCents: balance.balanceCents.abs(),
    );
  }

  final String personId;
  final String name;
  int debtCents;
}
