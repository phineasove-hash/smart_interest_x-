import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_interest_x/data/providers/contact_provider.dart';
import 'package:smart_interest_x/data/providers/loan_provider.dart';
import 'package:smart_interest_x/models/contact.dart';
import 'package:smart_interest_x/models/enums.dart';
import 'package:smart_interest_x/screens/add_loan_screen.dart';
import 'package:smart_interest_x/screens/loan_detail_screen.dart';
import 'package:smart_interest_x/theme/app_theme.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  bool _showSettled = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.trending_up), text: 'Given'),
            Tab(icon: Icon(Icons.trending_down), text: 'Taken'),
          ],
        ),
      ),
      body: Consumer2<LoanProvider, ContactProvider>(
        builder: (context, loanProvider, contactProvider, child) {
          return Column(
            children: [
              // ── Barre de recherche ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.trim()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilterChip(
                      label: const Text('Settled'),
                      selected: _showSettled,
                      onSelected: (v) => setState(() => _showSettled = v),
                      selectedColor: AppTheme.positiveGreen.withOpacity(0.2),
                      checkmarkColor: AppTheme.positiveGreen,
                    ),
                  ],
                ),
              ),

              // ── Tabs content ──────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _LoanList(
                      filterType: LoanType.given,
                      searchQuery: _searchQuery,
                      showSettled: _showSettled,
                      loanProvider: loanProvider,
                      contactProvider: contactProvider,
                    ),
                    _LoanList(
                      filterType: LoanType.taken,
                      searchQuery: _searchQuery,
                      showSettled: _showSettled,
                      loanProvider: loanProvider,
                      contactProvider: contactProvider,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoanAddScreen()),
        ),
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LoanList extends StatelessWidget {
  final LoanType filterType;
  final String searchQuery;
  final bool showSettled;
  final LoanProvider loanProvider;
  final ContactProvider contactProvider;

  const _LoanList({
    required this.filterType,
    required this.searchQuery,
    required this.showSettled,
    required this.loanProvider,
    required this.contactProvider,
  });

  @override
  Widget build(BuildContext context) {
    final color = filterType == LoanType.given
        ? AppTheme.positiveGreen
        : AppTheme.negativeRed;

    final loans = loanProvider.loans.where((loan) {
      if (loan.type != filterType) return false;
      if (!showSettled && loan.isSettled) return false;

      final contact = contactProvider.contacts.firstWhere(
        (c) => c.id == loan.contactId,
        orElse: () =>
            Contact(id: loan.contactId, name: 'Unknown', phone: ''),
      );
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        if (!loan.amount.toString().contains(q) &&
            !contact.name.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList()
      ..sort((a, b) {
        // Active loans first, then settled ones
        if (a.isSettled != b.isSettled) {
          return a.isSettled ? 1 : -1;
        }
        // Overdue loans first among active loans
        if (a.isOverdue != b.isOverdue) {
          return a.isOverdue ? -1 : 1;
        }
        return b.startDate.compareTo(a.startDate);
      });

    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filterType == LoanType.given
                  ? Icons.call_made_outlined
                  : Icons.call_received_outlined,
              size: 64,
              color: color.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              searchQuery.isEmpty
                  ? 'No ${filterType == LoanType.given ? 'loans given' : 'loans taken'}.'
                  : 'No results.',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final loan = loans[index];
        final contact = contactProvider.contacts.firstWhere(
          (c) => c.id == loan.contactId,
          orElse: () =>
              Contact(id: loan.contactId, name: 'Unknown Contact', phone: ''),
        );
        final remaining = loanProvider.remainingBalance(loan);

        return _LoanCard(
          loan: loan,
          contact: contact,
          remaining: remaining,
          color: color,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  LoanDetailScreen(loan: loan, contact: contact),
            ),
          ),
          onDelete: () => _confirmDelete(context, loan.id, loanProvider),
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, String loanId, LoanProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this loan ?'),
        content:
            const Text('This action will also delete all associated payments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.negativeRed),
            onPressed: () {
              provider.deleteLoan(loanId);
              Navigator.pop(ctx);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final dynamic loan;
  final Contact contact;
  final double remaining;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _LoanCard({
    required this.loan,
    required this.contact,
    required this.remaining,
    required this.color,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  loan.type == LoanType.given
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '€${loan.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${loan.interestRate.toStringAsFixed(1)}%/year',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.name,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Status badge
                        if (loan.isSettled)
                          _Badge('Settled', AppTheme.positiveGreen)
                        else if (loan.isOverdue)
                          _Badge('Overdue', AppTheme.negativeRed)
                        else ...[
                          _Badge('Remaining €${remaining.toStringAsFixed(0)}',
                              color),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppTheme.textSecondary),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}