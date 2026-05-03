import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_interest_x/data/providers/contact_provider.dart';
import 'package:smart_interest_x/data/providers/loan_provider.dart';
import 'package:smart_interest_x/models/enums.dart';
import 'package:smart_interest_x/models/loan.dart';
import 'package:smart_interest_x/services/notification_service.dart';
import 'package:smart_interest_x/theme/app_theme.dart';

class LoanAddScreen extends StatefulWidget {
  const LoanAddScreen({super.key});

  @override
  State<LoanAddScreen> createState() => _LoanAddScreenState();
}

class _LoanAddScreenState extends State<LoanAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  LoanType _selectedType = LoanType.given;
  String? _selectedContactId;
  DateTime? _dueDate;
  int _reminderDays = 3; // délai configurable : 1, 3 ou 7 jours

  @override
  void initState() {
    super.initState();
    _startDateController.text = DateTime.now().toString().split(' ')[0];
    _endDateController.text = DateTime.now()
        .add(const Duration(days: 30))
        .toString()
        .split(' ')[0];
  }

  @override
  void dispose() {
    _amountController.dispose();
    _interestRateController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: AppTheme.primaryBlue) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.negativeRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.negativeRed, width: 2),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactProvider = Provider.of<ContactProvider>(context);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final contacts = contactProvider.contacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        centerTitle: true,
      ),
      body: contacts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_alt_1,
                      size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  const Text(
                    'Please add a contact first.',
                    style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add a Contact'),
                    onPressed: () => Navigator.pushNamed(context, '/add_contact'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Type Given / Taken ──────────────────────────────
                    _sectionLabel('TRANSACTION TYPE'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TypeButton(
                              label: 'Given (Lender)',
                              icon: Icons.trending_up,
                              isSelected: _selectedType == LoanType.given,
                              color: AppTheme.positiveGreen,
                              onTap: () =>
                                  setState(() => _selectedType = LoanType.given),
                            ),
                          ),
                          Expanded(
                            child: _TypeButton(
                              label: 'Taken (Borrower)',
                              icon: Icons.trending_down,
                              isSelected: _selectedType == LoanType.taken,
                              color: AppTheme.negativeRed,
                              onTap: () =>
                                  setState(() => _selectedType = LoanType.taken),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Contact ─────────────────────────────────────────
                    _sectionLabel('CONTACT'),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Select a Contact'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView(
                                shrinkWrap: true,
                                children: contacts.map((c) {
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          AppTheme.primaryBlue.withOpacity(0.1),
                                      child: Text(
                                        c.name[0].toUpperCase(),
                                        style: const TextStyle(
                                            color: AppTheme.primaryBlue,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(c.name),
                                    subtitle: Text(c.phone),
                                    onTap: () {
                                      setState(() => _selectedContactId = c.id);
                                      Navigator.pop(ctx);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedContactId != null
                                ? AppTheme.primaryBlue
                                : Colors.grey.shade300,
                            width: _selectedContactId != null ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: _selectedContactId != null
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedContactId != null
                                    ? contacts
                                        .firstWhere(
                                            (c) => c.id == _selectedContactId,
                                            orElse: () => contacts.first)
                                        .name
                                    : 'Select a Contact',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedContactId != null
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Montant ──────────────────────────────────────────
                    _sectionLabel('AMOUNT & RATE'),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _fieldDecoration('Amount (€)',
                                icon: Icons.euro),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Requis';
                              }
                              final amount =
                                  double.tryParse(v.replaceAll(',', '.'));
                              if (amount == null || amount <= 0) {
                                return 'Invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _interestRateController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _fieldDecoration('Rate %',
                                icon: Icons.percent),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Requis';
                              }
                              final rate =
                                  double.tryParse(v.replaceAll(',', '.'));
                              if (rate == null || rate < 0) {
                                return 'Invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Dates ────────────────────────────────────────────
                    _sectionLabel('DATES'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startDateController,
                            readOnly: true,
                            decoration: _fieldDecoration('Start Date',
                                icon: Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                _startDateController.text =
                                    date.toString().split(' ')[0];
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _endDateController,
                            readOnly: true,
                            decoration: _fieldDecoration('End Date',
                                icon: Icons.event),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate:
                                    DateTime.now().add(const Duration(days: 30)),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                _endDateController.text =
                                    date.toString().split(' ')[0];
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Due Date ─────────────────────────────────────────
                    _sectionLabel('DUE DATE (REMINDER)'),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ??
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) setState(() => _dueDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: _dueDate != null
                              ? AppTheme.warningOrange.withOpacity(0.08)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _dueDate != null
                                ? AppTheme.warningOrange
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notification_important_outlined,
                              color: _dueDate != null
                                  ? AppTheme.warningOrange
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _dueDate != null
                                    ? _dueDate!.toString().split(' ')[0]
                                    : 'No due date',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _dueDate != null
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            if (_dueDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear,
                                    color: AppTheme.textSecondary, size: 20),
                                onPressed: () => setState(() => _dueDate = null),
                              )
                            else
                              const Icon(Icons.chevron_right,
                                  color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),

                    // ── Délai de rappel ──────────────────────────────────
                    if (_dueDate != null) ...[
                      const SizedBox(height: 12),
                      _sectionLabel('REMINDER BEFORE DUE DATE'),
                      Row(
                        children: [1, 3, 7].map((days) {
                          final isSelected = _reminderDays == days;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _reminderDays = days),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryBlue
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryBlue
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    '$days d',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── Notes ────────────────────────────────────────────
                    _sectionLabel('NOTES'),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: _fieldDecoration(
                          'Description, remarks...', icon: Icons.notes),
                    ),
                    const SizedBox(height: 28),

                    // ── Bouton Enregistrer ───────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: _selectedType == LoanType.given
                              ? AppTheme.positiveGreen
                              : AppTheme.negativeRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          if (_formKey.currentState?.validate() != true) return;
                          if (_selectedContactId == null &&
                              contacts.isEmpty) return;

                          final contactId =
                              _selectedContactId ?? contacts.first.id;
                          final amount = double.parse(
                              _amountController.text.replaceAll(',', '.'));
                          final rate = double.parse(
                              _interestRateController.text.replaceAll(',', '.'));
                          final startDate =
                              DateTime.parse(_startDateController.text);
                          final endDate =
                              DateTime.parse(_endDateController.text);

                          final loan = Loan(
                            id: DateTime.now().toIso8601String(),
                            contactId: contactId,
                            amount: amount,
                            interestRate: rate,
                            type: _selectedType,
                            startDate: startDate,
                            endDate: endDate,
                            dueDate: _dueDate,
                            notes: _notesController.text.trim().isEmpty
                                ? null
                                : _notesController.text.trim(),
                          );

                          loanProvider.addLoan(loan);

                          // Planifier les rappels (1j, 3j, 7j selon choix)
                          if (_dueDate != null) {
                            NotificationService()
                                .scheduleReminder(loan, daysBeforeDue: _reminderDays);
                          }

                          Navigator.pop(context);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedType == LoanType.given
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedType == LoanType.given
                                  ? 'Save Loan'
                                  : 'Save Debt',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Bouton de sélection du type (Given / Taken)
class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
