import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import '../providers/user_provider.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  static const String channelId = 'water_reminders';
  static const String channelName = 'Water Intake Reminders';
  static const String channelDescription = 'Reminders to stay hydrated based on your daily goal.';

  static const String fastingChannelId = 'fasting_reminders';
  static const String fastingChannelName = 'Fasting Reminders';
  static const String fastingChannelDescription = 'Reminders for intermittent fasting windows.';

  static UserProvider? _userProvider;

  static Future<void> initialize(UserProvider userProvider) async {
    _userProvider = userProvider;
    
    if (kIsWeb) return;

    debugPrint('NotificationService: Initializing timezones...');
    tz.initializeTimeZones();
    try {
      debugPrint('NotificationService: Getting local timezone...');
      // Use a timeout to prevent hanging on Linux if timezone DB is missing/corrupt
      final String timeZoneName = await FlutterTimezone.getLocalTimezone()
          .timeout(const Duration(seconds: 2), onTimeout: () => 'UTC');
      debugPrint('NotificationService: Local timezone is $timeZoneName');
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Could not initialize timezone for notifications: $e');
      // Default to UTC if it fails
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    const dynamic initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const dynamic initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const dynamic initializationSettingsLinux = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _createChannel();
  }

  static Future<void> _createChannel() async {
    if (kIsWeb) return;
    
    const dynamic channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
    );

    const dynamic fastingChannel = AndroidNotificationChannel(
      fastingChannelId,
      fastingChannelName,
      description: fastingChannelDescription,
      importance: Importance.high,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
      await androidImplementation.createNotificationChannel(fastingChannel);
    }
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb) return;

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  static void _onNotificationResponse(NotificationResponse response) async {
    final String? actionId = response.actionId;

    if (actionId == 'yes_250') {
      _userProvider?.addWater(250);
    } else if (actionId == 'yes_500') {
      _userProvider?.addWater(500);
    }
    // 'no' action doesn't require state update
  }

  static Future<void> scheduleSmartWaterReminders(int currentIntake, int goal) async {
    if (kIsWeb) return;

    final now = DateTime.now();
    const activeRangeStart = 8; // 8 AM
    const activeRangeEnd = 22;   // 10 PM
    
    // Cancel previous water reminders (IDs 1000 to 1024)
    for (int hour = activeRangeStart; hour < activeRangeEnd; hour += 3) {
      await _notificationsPlugin.cancel(1000 + hour);
    }
    
    for (int hour = activeRangeStart; hour < activeRangeEnd; hour += 3) {
      final scheduledTime = DateTime(now.year, now.month, now.day, hour);
      
      if (scheduledTime.isBefore(now)) continue;

      double progressWindow = (hour - activeRangeStart) / (activeRangeEnd - activeRangeStart);
      int expectedIntake = (goal * progressWindow).toInt();

      final String promptTime = hour > 12 ? '${hour - 12} PM' : '$hour AM';

      // Use a dynamic type here to avoid compilation error on Web
      const dynamic androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('yes_250', 'Yes, 250ml', showsUserInterface: true),
          AndroidNotificationAction('yes_500', 'Yes, 500ml', showsUserInterface: true),
          AndroidNotificationAction('no', 'No', showsUserInterface: true),
        ],
      );

      const dynamic iosDetails = DarwinNotificationDetails(
        categoryIdentifier: 'water_actions',
      );

      await _notificationsPlugin.zonedSchedule(
        1000 + hour,
        '💧 Stay Hydrated!',
        'Did you drink water since $promptTime? You\'re a bit behind your goal.',
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: expectedIntake.toString(),
      );
    }
  }

  static Future<void> scheduleFastingEndNotification(DateTime startTime, int durationHours, int reminderOffsetMinutes) async {
    if (kIsWeb) return;
    
    await cancelFastingNotifications();
    
    DateTime endTime = startTime.add(Duration(hours: durationHours));
    DateTime notificationTime = endTime.subtract(Duration(minutes: reminderOffsetMinutes));
    
    if (notificationTime.isBefore(DateTime.now())) return;
    
    const dynamic androidDetails = AndroidNotificationDetails(
      fastingChannelId,
      fastingChannelName,
      channelDescription: fastingChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const dynamic iosDetails = DarwinNotificationDetails();
    
    String title = 'Fasting Goal Reached!';
    String body = 'You have completed your $durationHours-hour fast. Time to eat!';
    
    if (reminderOffsetMinutes > 0) {
      title = 'Fasting almost over!';
      body = 'Your $durationHours-hour fast ends in $reminderOffsetMinutes minutes.';
    }

    await _notificationsPlugin.zonedSchedule(
      999, // Specific ID for fasting notifications
      title,
      body,
      tz.TZDateTime.from(notificationTime, tz.local),
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelFastingNotifications() async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancel(999);
  }

  static Future<void> showTestNotification() async {
    if (kIsWeb) {
      // Basic web notification if possible
      await _notificationsPlugin.show(
        0,
        '💧 Quick Hydration Check',
        'Daily watering reminder testing!',
        const NotificationDetails(),
      );
      return;
    }

    const dynamic androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('yes_250', 'Yes, 250ml', showsUserInterface: true),
        AndroidNotificationAction('yes_500', 'Yes, 500ml', showsUserInterface: true),
        AndroidNotificationAction('no', 'No', showsUserInterface: true),
      ],
    );
    
    final platformChannelSpecifics = const NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _notificationsPlugin.show(
      0,
      '💧 Quick Hydration Check',
      'Did you drink water in the last hour? Log it quickly below!',
      platformChannelSpecifics,
      payload: 'test',
    );
  }
}
