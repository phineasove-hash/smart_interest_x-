import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/loan.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse response) async {},
    );
  }

  /// Planifie un rappel avant l'échéance d'un prêt.
  /// [daysBeforeDue] : 1, 3 (défaut) ou 7 jours avant la due date.
  Future<void> scheduleReminder(Loan loan, {int daysBeforeDue = 3}) async {
    if (loan.dueDate == null) return;

    final reminderDate = loan.dueDate!.subtract(Duration(days: daysBeforeDue));

    if (reminderDate.isBefore(DateTime.now())) return;

    final String dayLabel = daysBeforeDue == 1
        ? '1 day'
        : '$daysBeforeDue days';

    // Notification J-N
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: loan.id.hashCode ^ daysBeforeDue, // ID unique par prêt + délai
      title: '⏰ Loan reminder',
      body:
          'The loan of ${loan.amount.toStringAsFixed(0)}€ is due in $dayLabel.',
      scheduledDate: tz.TZDateTime.from(reminderDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'loan_reminders_channel',
          'Loan reminders',
          channelDescription: 'Reminders for loan due dates',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // PAS de matchDateTimeComponents → se déclenche une seule fois
    );
  }

  /// Annule toutes les notifications d'un prêt donné.
  Future<void> cancelReminders(Loan loan) async {
    for (final days in [1, 3, 7]) {
      final notifId = loan.id.hashCode ^ days;
      await flutterLocalNotificationsPlugin.cancel(id: notifId);
    }
  }

  /// Planifie les 3 rappels standards (7j, 3j, 1j) pour un prêt.
  Future<void> scheduleAllReminders(Loan loan) async {
    for (final days in [7, 3, 1]) {
      await scheduleReminder(loan, daysBeforeDue: days);
    }
  }
}