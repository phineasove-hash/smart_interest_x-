class InterestService {
  /// Calcule l'intérêt simple.
  /// Formule : (principal × taux × jours) / (100 × 365)
  static double calculateSimpleInterest({
    required double principal,
    required double rate,
    required int days,
  }) {
    return (principal * rate * days) / (100 * 365);
  }
}