import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/loan.dart';
import '../models/enums.dart';
import '../models/contact.dart';

class ExportService {
  Future<void> exportToCSV(List<Loan> loans,
      {List<Contact> contacts = const []}) async {
    final contactMap = {for (final c in contacts) c.id: c.name};

    List<List<dynamic>> rows = [];
    rows.add([
      'ID', 'Contact', 'Amount (€)', 'Rate (%)', 'Type',
      'Start Date', 'Due Date', 'Accumulated Interest (€)',
      'Total Due (€)', 'Status', 'Notes',
    ]);

    for (final loan in loans) {
      rows.add([
        loan.id,
        contactMap[loan.contactId] ?? loan.contactId,
        loan.amount.toStringAsFixed(2),
        loan.interestRate.toStringAsFixed(2),
        loan.type == LoanType.given ? 'Given' : 'Taken',
        loan.startDate.toIso8601String().split('T').first,
        loan.dueDate?.toIso8601String().split('T').first ?? '',
        loan.accumulatedInterest.toStringAsFixed(2),
        loan.totalBalance.toStringAsFixed(2),
        loan.isSettled ? 'Settled' : (loan.isOverdue ? 'Overdue' : 'Active'),
        loan.notes ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csv);

    // Sauvegarde dans le dossier temporaire puis partage
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/smart_interest_export.csv');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Smart Interest Export',
    );
  }
}