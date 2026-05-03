import 'package:hive/hive.dart';
import 'enums.dart';

class Loan {
  final String id;
  final String contactId;
  final double amount;
  final double interestRate;
  final LoanType type;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? dueDate;
  final String? notes;
  final bool isSettled;

  Loan({
    required this.id,
    required this.contactId,
    required this.amount,
    required this.interestRate,
    required this.type,
    required this.startDate,
    this.endDate,
    this.dueDate,
    this.notes,
    this.isSettled = false,
  });

  // Nombre de jours écoulés depuis le début
  int get daysPassed {
    final now = DateTime.now();
    return now.difference(startDate).inDays;
  }

  // Intérêt simple (annuel, basé sur les jours) : (P × R × D) / (100 × 365)
  double get accumulatedInterest {
    return (amount * interestRate * daysPassed) / (100 * 365);
  }

  // Montant total (capital + intérêts accumulés)
  double get totalBalance {
    return amount + accumulatedInterest;
  }

  // Intérêt projeté jusqu'à la date d'échéance
  double get interestTillDueDate {
    if (dueDate == null) return 0.0;
    final int days = dueDate!.difference(startDate).inDays;
    return (amount * interestRate * days) / (100 * 365);
  }

  // Montant total à l'échéance
  double get totalAtDueDate {
    return amount + interestTillDueDate;
  }

  // Le prêt est-il en retard ?
  bool get isOverdue {
    if (dueDate == null || isSettled) return false;
    return dueDate!.isBefore(DateTime.now());
  }
}

class LoanAdapter extends TypeAdapter<Loan> {
  @override
  final int typeId = 1;

  @override
  Loan read(BinaryReader reader) {
    final id = reader.readString();
    final contactId = reader.readString();
    final amount = reader.readDouble();
    final interestRate = reader.readDouble();
    final typeIndex = reader.readInt();
    final startDate = reader.read() as DateTime;

    final hasEndDate = reader.readBool();
    final endDate = hasEndDate ? reader.read() as DateTime : null;

    final hasNotes = reader.readBool();
    final notes = hasNotes ? reader.readString() : null;

    // Rétrocompatibilité : dueDate ajouté après la v1
    DateTime? dueDate;
    bool isSettled = false;
    try {
      if (reader.availableBytes > 0) {
        final hasDueDate = reader.readBool();
        dueDate = hasDueDate ? reader.read() as DateTime : null;
      }
      // Rétrocompatibilité : isSettled ajouté après dueDate
      if (reader.availableBytes > 0) {
        isSettled = reader.readBool();
      }
    } catch (_) {
      // Anciens enregistrements sans ces champs
    }

    return Loan(
      id: id,
      contactId: contactId,
      amount: amount,
      interestRate: interestRate,
      type: LoanType.values[typeIndex],
      startDate: startDate,
      endDate: endDate,
      dueDate: dueDate,
      notes: notes,
      isSettled: isSettled,
    );
  }

  @override
  void write(BinaryWriter writer, Loan obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.contactId);
    writer.writeDouble(obj.amount);
    writer.writeDouble(obj.interestRate);
    writer.writeInt(obj.type.index);
    writer.write(obj.startDate);

    if (obj.endDate != null) {
      writer.writeBool(true);
      writer.write(obj.endDate!);
    } else {
      writer.writeBool(false);
    }

    if (obj.notes != null) {
      writer.writeBool(true);
      writer.writeString(obj.notes!);
    } else {
      writer.writeBool(false);
    }

    if (obj.dueDate != null) {
      writer.writeBool(true);
      writer.write(obj.dueDate!);
    } else {
      writer.writeBool(false);
    }

    writer.writeBool(obj.isSettled);
  }
}
