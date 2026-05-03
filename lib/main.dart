import 'package:flutter/material.dart';
import 'package:smart_interest_x/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:smart_interest_x/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:smart_interest_x/data/providers/contact_provider.dart';
import 'package:smart_interest_x/data/providers/loan_provider.dart';
import 'package:smart_interest_x/models/contact.dart';
import 'package:smart_interest_x/models/loan.dart';
import 'package:smart_interest_x/models/payment.dart';
import 'package:smart_interest_x/models/enums.dart';
import 'package:smart_interest_x/screens/add_contact_screen.dart';
import 'package:smart_interest_x/screens/add_loan_screen.dart';
import 'package:smart_interest_x/screens/contacts_screen.dart';
import 'package:smart_interest_x/screens/dashboard_screen.dart';
import 'package:smart_interest_x/screens/loans_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService().init();
  await Hive.initFlutter();
  Hive.registerAdapter(ContactAdapter());
  Hive.registerAdapter(LoanAdapter());
  Hive.registerAdapter(PaymentAdapter());

  final contactBox = await Hive.openBox<Contact>('contacts');
  final loanBox = await Hive.openBox<Loan>('loans');
  final paymentBox = await Hive.openBox<Payment>('payments');

  if (contactBox.isEmpty && loanBox.isEmpty) {
    final contact = Contact(
      id: '1',
      name: 'John Doe',
      phone: '123456789',
      email: 'john@example.com',
    );
    contactBox.put(contact.id, contact);

    final loan1 = Loan(
      id: '1',
      contactId: '1',
      amount: 1000.0,
      interestRate: 5.0,
      type: LoanType.given,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
    );
    final loan2 = Loan(
      id: '2',
      contactId: '1',
      amount: 500.0,
      interestRate: 3.0,
      type: LoanType.taken,
      startDate: DateTime.now().subtract(const Duration(days: 15)),
    );
    loanBox.put(loan1.id, loan1);
    loanBox.put(loan2.id, loan2);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContactProvider(contactBox)),
        ChangeNotifierProvider(
          create: (_) => LoanProvider(loanBox, paymentBox),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/contacts': (context) => const ContactsScreen(),
        '/add_contact': (context) => const AddContactScreen(),
        '/loans': (context) => const LoansScreen(),
        '/add_loan': (context) => const LoanAddScreen(),
      },
    );
  }
}
