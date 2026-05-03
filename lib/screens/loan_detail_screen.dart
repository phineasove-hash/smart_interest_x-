import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_interest_x/data/providers/loan_provider.dart';
import 'package:smart_interest_x/models/contact.dart';
import 'package:smart_interest_x/models/enums.dart';
import 'package:smart_interest_x/models/loan.dart';
import 'package:smart_interest_x/screens/add_payment_screen.dart';
import 'package:smart_interest_x/theme/app_theme.dart';

class LoanDetailScreen extends StatelessWidget {
  final Loan loan;
  final Contact contact;

  const LoanDetailScreen({
    super.key,
    required this.loan,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    final isGiven = loan.type == LoanType.given;
    final typeColor = isGiven ? AppTheme.positiveGreen : AppTheme.negativeRed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Detail'),
        centerTitle: true,
        actions: [
          if (!loan.isSettled)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add Payment',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPaymentScreen(loan: loan),
                  ),
                );
              },
            ),
        ],
      ),
      body: Consumer<LoanProvider>(
        builder: (context, loanProvider, child) {
          // Récupérer la version à jour du prêt depuis le provider
          final currentLoan = loanProvider.loans.firstWhere(
            (l) => l.id == loan.id,
            orElse: () => loan,
          );
          final payments = loanProvider.paymentsForLoan(currentLoan.id);
          final totalPaid = loanProvider.totalPaid(currentLoan.id);
          final remaining = loanProvider.remainingBalance(currentLoan);
          final progressPercent = currentLoan.totalBalance > 0
              ? (totalPaid / currentLoan.totalBalance).clamp(0.0, 1.0)
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Bannière statut ─────────────────────────────────────
                if (currentLoan.isSettled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.positiveGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.positiveGreen.withOpacity(0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppTheme.positiveGreen),
                        SizedBox(width: 8),
                        Text(
                          'Loan fully paid',
                          style: TextStyle(
                            color: AppTheme.positiveGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (currentLoan.isOverdue && !currentLoan.isSettled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.negativeRed.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.negativeRed.withOpacity(0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppTheme.negativeRed),
                        SizedBox(width: 8),
                        Text(
                          'Overdue loan !',
                          style: TextStyle(
                            color: AppTheme.negativeRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Carte principale ────────────────────────────────────
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isGiven
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: typeColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isGiven ? 'Given' : 'Taken',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  contact.name,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        _InfoRow('Contact', contact.name),
                        if (contact.phone.isNotEmpty)
                          _InfoRow('Phone', contact.phone),
                        if (contact.email != null)
                          _InfoRow('Email', contact.email!),
                        const SizedBox(height: 8),
                        _InfoRow('Capital',
                            '€${currentLoan.amount.toStringAsFixed(2)}'),
                        _InfoRow('Annual Rate',
                            '${currentLoan.interestRate.toStringAsFixed(2)}%'),
                        _InfoRow('Start Date',
                            currentLoan.startDate.toString().split(' ')[0]),
                        if (currentLoan.dueDate != null)
                          _InfoRow(
                            'Due Date',
                            currentLoan.dueDate!.toString().split(' ')[0],
                            valueColor: currentLoan.isOverdue
                                ? AppTheme.negativeRed
                                : null,
                          ),
                        const Divider(height: 20),
                        _InfoRow(
                          'Accumulated Interest',
                          '€${currentLoan.accumulatedInterest.toStringAsFixed(2)}',
                          valueColor: typeColor,
                        ),
                        if (currentLoan.dueDate != null)
                          _InfoRow(
                            'Interest till due',
                            '€${currentLoan.interestTillDueDate.toStringAsFixed(2)}',
                          ),
                        _InfoRow(
                          'Total Due',
                          '€${currentLoan.totalBalance.toStringAsFixed(2)}',
                          isBold: true,
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          'Total Paid',
                          '€${totalPaid.toStringAsFixed(2)}',
                          valueColor: AppTheme.positiveGreen,
                        ),
                        _InfoRow(
                          'Remaining',
                          '€${remaining.toStringAsFixed(2)}',
                          valueColor: remaining > 0
                              ? AppTheme.negativeRed
                              : AppTheme.positiveGreen,
                          isBold: true,
                        ),
                        if (currentLoan.notes != null) ...[
                          const Divider(height: 20),
                          _InfoRow('Notes', currentLoan.notes!),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Barre de progression ────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Loan Progress',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${(progressPercent * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: typeColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressPercent >= 1.0
                              ? AppTheme.positiveGreen
                              : typeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Bouton Settle ───────────────────────────────────────
                if (!currentLoan.isSettled)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.check_circle_outline,
                          color: AppTheme.positiveGreen),
                      label: const Text(
                        'Settle Loan',
                        style: TextStyle(
                            color: AppTheme.positiveGreen,
                            fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.positiveGreen),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirm'),
                            content: const Text(
                                'Mark this loan as fully settled?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.positiveGreen),
                                onPressed: () {
                                  loanProvider.settleLoan(currentLoan.id);
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Confirm',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),

                // ── Historique paiements ────────────────────────────────
                const Text(
                  'Payment History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                payments.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'No payments recorded.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    : Column(
                        children: payments.map((payment) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.positiveGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.payment,
                                    color: AppTheme.positiveGreen),
                              ),
                              title: Text(
                                '€${payment.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.positiveGreen),
                              ),
                              subtitle: Text(
                                '${payment.paymentMode} · ${payment.date.toLocal().toString().split(' ').first}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (payment.proofImagePath != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.file(
                                        File(payment.proofImagePath!),
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.broken_image,
                                                size: 40),
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: AppTheme.negativeRed),
                                    onPressed: () => loanProvider
                                        .deletePayment(payment.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<LoanProvider>(
        builder: (context, provider, _) {
          final current = provider.loans.firstWhere(
            (l) => l.id == loan.id,
            orElse: () => loan,
          );
          if (current.isSettled) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPaymentScreen(loan: current),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Payment'),
            backgroundColor: AppTheme.primaryBlue,
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _InfoRow(this.label, this.value,
      {this.valueColor, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
