import '../models/loan.dart';
import 'interest_service.dart';

class LoanService {
  /// Calcul total à rembourser
  static double calculateTotalRepayment(Loan loan, int days) {
    final interest = InterestService.calculateSimpleInterest(
      principal: loan.amount,
      rate: loan.interestRate,
      days: days,
    );
    return loan.amount + interest;
  }
}