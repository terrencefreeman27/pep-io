import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/dose.dart';
import '../models/protocol.dart';

/// Notification service for scheduling and managing local notifications
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  /// Initialize the notification service
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  /// Handle notification tap response
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      final data = jsonDecode(payload);
      final type = data['type'] as String?;
      final actionId = response.actionId;

      // Handle different notification types and actions
      // This would typically navigate to appropriate screens
      // or update dose status through a callback
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    return false;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    
    // For iOS, we can't directly check - assume enabled if permissions were granted
    return true;
  }

  /// Schedule a dose reminder notification
  Future<void> scheduleDoseReminder({
    required Dose dose,
    required Protocol protocol,
  }) async {
    final scheduledDateTime = dose.scheduledDateTime;
    
    // Don't schedule notifications for past times
    if (scheduledDateTime.isBefore(DateTime.now())) return;

    final notificationId = dose.id.hashCode;

    await _notifications.zonedSchedule(
      notificationId,
      'Time for ${protocol.peptideName}',
      '${protocol.formattedDosage} dose scheduled for now',
      tz.TZDateTime.from(scheduledDateTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'dose_reminders',
          'Dose Reminders',
          channelDescription: 'Reminders for scheduled peptide doses',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          actions: [
            const AndroidNotificationAction(
              'mark_taken',
              'Mark as Taken',
            ),
            const AndroidNotificationAction(
              'snooze',
              'Snooze 15 min',
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'dose_reminder',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({
        'type': 'dose_reminder',
        'dose_id': dose.id,
        'protocol_id': protocol.id,
      }),
    );
  }

  /// Schedule a missed dose alert
  Future<void> scheduleMissedDoseAlert({
    required Dose dose,
    required Protocol protocol,
    int delayMinutes = 30,
  }) async {
    final scheduledDateTime = dose.scheduledDateTime.add(Duration(minutes: delayMinutes));
    
    // Don't schedule if already passed
    if (scheduledDateTime.isBefore(DateTime.now())) return;

    final notificationId = '${dose.id}_missed'.hashCode;

    await _notifications.zonedSchedule(
      notificationId,
      'Missed Dose: ${protocol.peptideName}',
      'You missed your ${protocol.formattedDosage} dose at ${dose.scheduledTime}',
      tz.TZDateTime.from(scheduledDateTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'missed_doses',
          'Missed Dose Alerts',
          channelDescription: 'Alerts for missed doses',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          actions: [
            const AndroidNotificationAction(
              'mark_taken',
              'Mark as Taken',
            ),
            const AndroidNotificationAction(
              'skip',
              'Skip This Dose',
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'missed_dose',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({
        'type': 'missed_dose',
        'dose_id': dose.id,
        'protocol_id': protocol.id,
      }),
    );
  }

  /// Schedule a daily summary notification
  Future<void> scheduleDailySummary({
    required int doseCount,
    required String time, // Format: "HH:MM"
  }) async {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      'daily_summary'.hashCode,
      'Today\'s Protocol Summary',
      'You have $doseCount doses scheduled today',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_summary',
          'Daily Summary',
          channelDescription: 'Daily protocol summary notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          actions: [
            const AndroidNotificationAction(
              'view_schedule',
              'View Schedule',
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'daily_summary',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({
        'type': 'daily_summary',
      }),
    );
  }

  /// Send a streak milestone notification
  Future<void> showStreakMilestone({
    required int streakDays,
  }) async {
    await _notifications.show(
      'streak_$streakDays'.hashCode,
      '🔥 $streakDays Day Streak!',
      'You\'ve taken all doses for $streakDays days straight. Keep it up!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'achievements',
          'Achievements',
          channelDescription: 'Achievement and milestone notifications',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.status,
          actions: [
            const AndroidNotificationAction(
              'view_progress',
              'View Progress',
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'achievement',
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      payload: jsonEncode({
        'type': 'streak_milestone',
        'streak_days': streakDays,
      }),
    );
  }

  /// Schedule a protocol ending soon notification
  Future<void> scheduleProtocolEndingSoon({
    required Protocol protocol,
    int daysBeforeEnd = 3,
  }) async {
    if (protocol.endDate == null) return;

    final notificationDate = protocol.endDate!.subtract(Duration(days: daysBeforeEnd));
    final scheduledDateTime = DateTime(
      notificationDate.year,
      notificationDate.month,
      notificationDate.day,
      9, // 9:00 AM
      0,
    );

    // Don't schedule if already passed
    if (scheduledDateTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      'protocol_ending_${protocol.id}'.hashCode,
      '${protocol.peptideName} Protocol Ending Soon',
      'Your protocol ends on ${_formatDate(protocol.endDate!)}. Extend or complete?',
      tz.TZDateTime.from(scheduledDateTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'protocol_reminders',
          'Protocol Reminders',
          channelDescription: 'Reminders about protocol status',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          actions: [
            const AndroidNotificationAction(
              'extend',
              'Extend Protocol',
            ),
            const AndroidNotificationAction(
              'complete',
              'Mark Complete',
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'protocol_ending',
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({
        'type': 'protocol_ending',
        'protocol_id': protocol.id,
      }),
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications for a dose
  Future<void> cancelDoseNotifications(String doseId) async {
    await _notifications.cancel(doseId.hashCode);
    await _notifications.cancel('${doseId}_missed'.hashCode);
  }

  /// Cancel all notifications for a protocol
  Future<void> cancelProtocolNotifications(String protocolId) async {
    await _notifications.cancel('protocol_ending_$protocolId'.hashCode);
    // Note: Individual dose notifications need to be cancelled separately
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Format date helper
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

