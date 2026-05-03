import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../models/loan.dart';
import '../../models/payment.dart';
import '../../models/enums.dart';
import '../../services/notification_service.dart';

class LoanProvider extends ChangeNotifier {
  final Box<Loan> _loanBox;
  final Box<Payment> _paymentBox;
  final List<Loan> _loans = [];
  final List<Payment> _payments = [];

  LoanProvider(this._loanBox, this._paymentBox) {
    _loans.addAll(_loanBox.values);
    _payments.addAll(_paymentBox.values);
  }

  List<Loan> get loans => List.unmodifiable(_loans);
  List<Payment> get payments => List.unmodifiable(_payments);

  void addLoan(Loan loan) {
    _loanBox.put(loan.id, loan);
    _loans.add(loan);
    // Planifie les rappels 7j, 3j et 1j avant l'échéance
    NotificationService().scheduleAllReminders(loan);
    notifyListeners();
  }

  void addPayment(Payment payment) {
    _paymentBox.put(payment.id, payment);
    _payments.add(payment);
    notifyListeners();
  }

  void deleteLoan(String id) {
    // Supprimer aussi les paiements associés de la box Hive (évite la fuite)
    final orphanIds = _payments
        .where((p) => p.loanId == id)
        .map((p) => p.id)
        .toList();
    for (final pid in orphanIds) {
      _paymentBox.delete(pid);
    }
    _loanBox.delete(id);
    _loans.removeWhere((loan) => loan.id == id);
    _payments.removeWhere((payment) => payment.loanId == id);
    notifyListeners();
  }

  void deletePayment(String id) {
    _paymentBox.delete(id);
    _payments.removeWhere((payment) => payment.id == id);
    notifyListeners();
  }

  List<Payment> paymentsForLoan(String loanId) {
    final payments = _payments
        .where((payment) => payment.loanId == loanId)
        .toList();
    payments.sort((a, b) => b.date.compareTo(a.date));
    return payments;
  }

  double totalPaid(String loanId) {
    return paymentsForLoan(
      loanId,
    ).fold(0.0, (sum, payment) => sum + payment.amount);
  }

  double remainingBalance(Loan loan) {
    return loan.totalBalance - totalPaid(loan.id);
  }

  // Marquer un prêt comme soldé
  void settleLoan(String id) {
    final index = _loans.indexWhere((l) => l.id == id);
    if (index == -1) return;
    final old = _loans[index];
    final settled = Loan(
      id: old.id,
      contactId: old.contactId,
      amount: old.amount,
      interestRate: old.interestRate,
      type: old.type,
      startDate: old.startDate,
      endDate: old.endDate,
      dueDate: old.dueDate,
      notes: old.notes,
      isSettled: true,
    );
    _loanBox.put(id, settled);
    _loans[index] = settled;
    notifyListeners();
  }

  // Stats calculées
  int get loansGiven =>
      _loans.where((loan) => loan.type == LoanType.given).length;
  int get loansTaken =>
      _loans.where((loan) => loan.type == LoanType.taken).length;

  List<Loan> get overdueLoans {
    final now = DateTime.now();
    return _loans.where((l) =>
      l.dueDate != null &&
      l.dueDate!.isBefore(now) &&
      !l.isSettled
    ).toList();
  }

  double get interestEarned {
    return _loans
        .where((loan) => loan.type == LoanType.given)
        .fold(0.0, (sum, loan) => sum + loan.accumulatedInterest);
  }

  double get interestPaid {
    return _loans
        .where((loan) => loan.type == LoanType.taken)
        .fold(0.0, (sum, loan) => sum + loan.accumulatedInterest);
  }
}
