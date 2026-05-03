import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_interest_x/data/providers/loan_provider.dart';
import 'package:smart_interest_x/models/loan.dart';
import 'package:smart_interest_x/models/payment.dart';

class AddPaymentScreen extends StatefulWidget {
  final Loan loan;

  const AddPaymentScreen({super.key, required this.loan});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController amountController = TextEditingController();
  String _selectedMethod = 'Cash';
  final List<String> _paymentModes = ['UPI', 'Bank transfer', 'Cash', 'Other'];
  String? _proofImagePath;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _proofImagePath = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final remainingBalance = loanProvider.remainingBalance(widget.loan);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Payment'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Remaining balance: €${remainingBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Payment amount (€)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an amount';
                  }
                  final amount = double.tryParse(value.replaceAll(',', '.'));
                  if (amount == null || amount <= 0) {
                    return 'Invalid amount';
                  }
                  if (amount > remainingBalance) {
                    return 'Amount exceeds remaining balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Payment method'),
                value: _selectedMethod,
                items: _paymentModes
                    .map(
                      (method) => DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value ?? 'Cash';
                  });
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Attach a proof'),
              ),
              if (_proofImagePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.file(
                    File(_proofImagePath!),
                    height: 100,
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() != true) return;

                  final amount = double.parse(
                    amountController.text.replaceAll(',', '.'),
                  );
                  final newPayment = Payment(
                    id: DateTime.now().toIso8601String(),
                    loanId: widget.loan.id,
                    amount: amount,
                    date: DateTime.now(),
                    paymentMode: _selectedMethod,
                    proofImagePath: _proofImagePath,
                  );
                  loanProvider.addPayment(newPayment);
                  Navigator.pop(context);
                },
                child: const Text('Save Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
