import 'package:hive/hive.dart';

part 'payment.g.dart';

@HiveType(typeId: 2)
class Payment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String loanId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String paymentMode;

  @HiveField(5)
  final String? proofImagePath;

  Payment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.date,
    required this.paymentMode,
    this.proofImagePath,
  });
}
