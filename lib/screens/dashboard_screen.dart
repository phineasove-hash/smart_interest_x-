import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/providers/loan_provider.dart';
import '../data/providers/contact_provider.dart';
import '../services/export_service.dart';
import '../models/enums.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _filterMonth;
  int? _filterYear;
  String? _filterContactId;

  List<Loan> _filtered(List<Loan> all) => all.where((l) {
        if (_filterMonth != null && l.startDate.month != _filterMonth) return false;
        if (_filterYear != null && l.startDate.year != _filterYear) return false;
        if (_filterContactId != null && l.contactId != _filterContactId) return false;
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        leading: Builder(builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Exporter CSV',
            onPressed: () {
              final loans = Provider.of<LoanProvider>(context, listen: false).loans;
              ExportService().exportToCSV(_filtered(loans.toList()));
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Consumer2<LoanProvider, ContactProvider>(
        builder: (context, lp, cp, _) {
          final all = lp.loans.toList();
          final loans = _filtered(all)..sort((a, b) => b.startDate.compareTo(a.startDate));
          final given = loans.where((l) => l.type == LoanType.given).toList();
          final taken = loans.where((l) => l.type == LoanType.taken).toList();
          final earned = given.fold(0.0, (s, l) => s + l.accumulatedInterest);
          final paid = taken.fold(0.0, (s, l) => s + l.accumulatedInterest);
          final overdue = lp.overdueLoans;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                const Text('Hello, Manager 👋',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Overview of your finances.',
                    style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 16),

                // Filtres
                _FiltersRow(
                  filterMonth: _filterMonth,
                  filterYear: _filterYear,
                  filterContactId: _filterContactId,
                  contacts: cp.contacts,
                  onMonthChanged: (v) => setState(() => _filterMonth = v),
                  onYearChanged: (v) => setState(() => _filterYear = v),
                  onContactChanged: (v) => setState(() => _filterContactId = v),
                ),
                const SizedBox(height: 16),

                // Alerte overdue
                if (overdue.isNotEmpty)
                  _OverdueAlert(count: overdue.length),

                // Carte snapshot
                _SnapshotCard(
                  total: loans.length,
                  givenCount: given.length,
                  takenCount: taken.length,
                  balance: earned - paid,
                ),
                const SizedBox(height: 16),

                // Stat cards
                _StatsGrid(earned: earned, paid: paid,
                    givenCount: given.length, takenCount: taken.length),
                const SizedBox(height: 20),

                // Bar chart fl_chart
                const Text('Loan Trends',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _BarChartCard(loans: loans.take(6).toList()),
                const SizedBox(height: 20),

                // Pie chart Given vs Taken
                const Text('Distribution',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _PieChartCard(givenCount: given.length, takenCount: taken.length),
                const SizedBox(height: 20),

                // Activité récente
                const Text('Recent Activity',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (loans.isEmpty)
                  _EmptyState()
                else
                  ...loans.take(3).map((l) => _RecentLoanTile(loan: l)),

                const SizedBox(height: 16),
                // Boutons navigation
                Row(children: [
                  Expanded(child: _NavButton(
                    icon: Icons.attach_money,
                    label: 'Loans',
                    onTap: () => Navigator.pushNamed(context, '/loans'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _NavButton(
                    icon: Icons.contacts_outlined,
                    label: 'Contacts',
                    onTap: () => Navigator.pushNamed(context, '/contacts'),
                  )),
                ]),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(padding: EdgeInsets.zero, children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: AppTheme.primaryBlue),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 28, backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white, size: 32)),
            SizedBox(height: 12),
            Text('SmartInterestX', style: TextStyle(color: Colors.white,
                fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Loan manager',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        ListTile(leading: const Icon(Icons.dashboard), title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context)),
        ListTile(leading: const Icon(Icons.attach_money), title: const Text('Loans'),
            onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/loans'); }),
        ListTile(leading: const Icon(Icons.contacts), title: const Text('Contacts'),
            onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/contacts'); }),
        const Divider(),
        ListTile(leading: const Icon(Icons.add_circle_outline, color: AppTheme.primaryBlue),
            title: const Text('New loan', style: TextStyle(color: AppTheme.primaryBlue)),
            onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/add_loan'); }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets internes
// ─────────────────────────────────────────────────────────────────────────────

class _FiltersRow extends StatelessWidget {
  final int? filterMonth;
  final int? filterYear;
  final String? filterContactId;
  final List contacts;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<String?> onContactChanged;

  const _FiltersRow({
    required this.filterMonth, required this.filterYear,
    required this.filterContactId, required this.contacts,
    required this.onMonthChanged, required this.onYearChanged,
    required this.onContactChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(flex: 2, child: _Dropdown<int?>(
        value: filterMonth, hint: 'Months',
        items: [const DropdownMenuItem(value: null, child: Text('Months')),
          ...List.generate(12, (i) => DropdownMenuItem(value: i + 1,
              child: Text('${i + 1}')))],
        onChanged: onMonthChanged,
      )),
      const SizedBox(width: 8),
      Expanded(flex: 2, child: _Dropdown<int?>(
        value: filterYear, hint: 'Year',
        items: [const DropdownMenuItem(value: null, child: Text('All')),
          DropdownMenuItem(value: DateTime.now().year,
              child: Text('${DateTime.now().year}')),
          DropdownMenuItem(value: DateTime.now().year - 1,
              child: Text('${DateTime.now().year - 1}')),
        ],
        onChanged: onYearChanged,
      )),
      const SizedBox(width: 8),
      Expanded(flex: 3, child: _Dropdown<String?>(
        value: filterContactId, hint: 'Contact',
        items: [const DropdownMenuItem(value: null, child: Text('All')),
          ...contacts.map((c) => DropdownMenuItem(value: c.id,
              child: Text(c.name, overflow: TextOverflow.ellipsis)))],
        onChanged: onContactChanged,
      )),
    ]);
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  const _Dropdown({required this.value, required this.hint,
      required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          border: OutlineInputBorder()),
        child: DropdownButtonHideUnderline(child: DropdownButton<T>(  
        isExpanded: true, value: value,
        hint: Text(hint, style: const TextStyle(fontSize: 13)),
        items: items, onChanged: onChanged,
      )),
    );
  }
}

class _OverdueAlert extends StatelessWidget {
  final int count;
  const _OverdueAlert({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.negativeRed.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.negativeRed.withOpacity(0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: AppTheme.negativeRed),
        const SizedBox(width: 10),
        Text('$count loan${count > 1 ? 's' : ''} in arrears !',
            style: const TextStyle(color: AppTheme.negativeRed,
                fontWeight: FontWeight.bold)),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/loans'),
          child: const Text('View →',
              style: TextStyle(color: AppTheme.negativeRed,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  final int total, givenCount, takenCount;
  final double balance;
  const _SnapshotCard({required this.total, required this.givenCount,
      required this.takenCount, required this.balance});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Overview', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 4),
        Text('${total} loan${total > 1 ? 's' : ''} in total',
            style: const TextStyle(color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(children: [
          _SnapMetric('Interest Balance',
              '${balance >= 0 ? '+' : ''}${balance.toStringAsFixed(2)} €'),
          const SizedBox(width: 24),
          _SnapMetric('Given', '$givenCount'),
          const SizedBox(width: 16),
          _SnapMetric('Taken', '$takenCount'),
        ]),
      ]),
    );
  }
}

class _SnapMetric extends StatelessWidget {
  final String label, value;
  const _SnapMetric(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      Text(value, style: const TextStyle(color: Colors.white,
          fontWeight: FontWeight.bold, fontSize: 16)),
    ],
  );
}

class _StatsGrid extends StatelessWidget {
  final double earned, paid;
  final int givenCount, takenCount;
  const _StatsGrid({required this.earned, required this.paid,
      required this.givenCount, required this.takenCount});
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, crossAxisSpacing: 12,
      mainAxisSpacing: 12, childAspectRatio: 1.8,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard('Given', '$givenCount', Icons.trending_up, AppTheme.positiveGreen),
        _StatCard('Taken', '$takenCount', Icons.trending_down, AppTheme.negativeRed),
        _StatCard('Interests Earned', '${earned.toStringAsFixed(2)} €',
            Icons.arrow_upward, AppTheme.primaryBlue),
        _StatCard('Interests Paid', '${paid.toStringAsFixed(2)} €',
            Icons.arrow_downward, AppTheme.warningOrange),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.title, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(title,
              style: TextStyle(color: color, fontSize: 12),
              overflow: TextOverflow.ellipsis)),
        ]),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 18,
            fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final List<Loan> loans;
  const _BarChartCard({required this.loans});
  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return Container(
        height: 180, alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16)),
        child: const Text('No loans to display',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    final maxY = loans.map((l) => l.amount).reduce(math.max) * 1.2;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4))]),
      child: SizedBox(
        height: 180,
        child: BarChart(BarChartData(
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 28,
              getTitlesWidget: (v, m) {
                final i = v.toInt();
                if (i >= loans.length) return const SizedBox.shrink();
                return Text(loans[i].type == LoanType.given ? 'D' : 'P',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold,
                      color: loans[i].type == LoanType.given
                          ? AppTheme.positiveGreen : AppTheme.negativeRed,
                    ));
              },
            )),
          ),
          barGroups: loans.asMap().entries.map((e) {
            final color = e.value.type == LoanType.given
                ? AppTheme.positiveGreen : AppTheme.negativeRed;
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: e.value.amount, color: color,
                width: 22, borderRadius: BorderRadius.circular(6),
                backDrawRodData: BackgroundBarChartRodData(
                    show: true, toY: maxY,
                    color: Colors.grey.shade100),
              ),
            ]);
          }).toList(),
        )),
      ),
    );
  }
}

class _PieChartCard extends StatelessWidget {
  final int givenCount, takenCount;
  const _PieChartCard({required this.givenCount, required this.takenCount});
  @override
  Widget build(BuildContext context) {
    final total = givenCount + takenCount;
    if (total == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4))]),
      child: Row(children: [
        SizedBox(
          height: 120, width: 120,
          child: PieChart(PieChartData(
            sectionsSpace: 3, centerSpaceRadius: 30,
            sections: [
              PieChartSectionData(
                value: givenCount.toDouble(), color: AppTheme.positiveGreen,
                title: '$givenCount', radius: 40,
                titleStyle: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
              PieChartSectionData(
                value: takenCount.toDouble(), color: AppTheme.negativeRed,
                title: '$takenCount', radius: 40,
                titleStyle: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          )),
        ),
        const SizedBox(width: 20),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Legend(AppTheme.positiveGreen, 'Given (G)',
              '${(givenCount / total * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: 10),
          _Legend(AppTheme.negativeRed, 'Taken (T)',
              '${(takenCount / total * 100).toStringAsFixed(0)}%'),
        ]),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label, pct;
  const _Legend(this.color, this.label, this.pct);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 12, height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 8),
    Text('$label  ', style: const TextStyle(fontSize: 13)),
    Text(pct, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
  ]);
}

class _RecentLoanTile extends StatelessWidget {
  final Loan loan;
  const _RecentLoanTile({required this.loan});
  @override
  Widget build(BuildContext context) {
    final isGiven = loan.type == LoanType.given;
    final color = isGiven ? AppTheme.positiveGreen : AppTheme.negativeRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 8, offset: const Offset(0, 4))]),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(isGiven ? Icons.trending_up : Icons.trending_down,
              color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(isGiven ? 'Given' : 'Taken',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('€${loan.amount.toStringAsFixed(2)} · '
              '${loan.interestRate.toStringAsFixed(1)}%/an',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ])),
        if (loan.isSettled)
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.positiveGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('Settled', style: TextStyle(color: AppTheme.positiveGreen,
                  fontSize: 11, fontWeight: FontWeight.bold)))
        else if (loan.isOverdue)
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.negativeRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('Overdue', style: TextStyle(color: AppTheme.negativeRed,
                  fontSize: 11, fontWeight: FontWeight.bold)))
        else
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(isGiven ? 'Given' : 'Taken', style: TextStyle(color: color,
                  fontSize: 11, fontWeight: FontWeight.bold))),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(14)),
    child: const Column(children: [
      Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textSecondary),
      SizedBox(height: 8),
      Text('No loans recorded.',
          style: TextStyle(color: AppTheme.textSecondary)),
    ]),
  );
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    icon: Icon(icon),
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    onPressed: onTap,
  );
}
