import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../providers/user_provider.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  static const String channelId = 'water_reminders';
  static const String channelName = 'Water Intake Reminders';
  static const String channelDescription = 'Reminders to stay hydrated based on your daily goal.';

  static UserProvider? _userProvider;

  static Future<void> initialize(UserProvider userProvider) async {
    _userProvider = userProvider;
    
    if (kIsWeb) return;

    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Could not initialize timezone for notifications: $e');
    }

    final dynamic initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    final dynamic initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _createChannel();
  }

  static Future<void> _createChannel() async {
    if (kIsWeb) return;
    
    final dynamic channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _onNotificationResponse(NotificationResponse response) async {
    final String? payload = response.payload;
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
    
    await _notificationsPlugin.cancelAll();

    final now = DateTime.now();
    const activeRangeStart = 8; // 8 AM
    const activeRangeEnd = 22;   // 10 PM
    
    for (int hour = activeRangeStart; hour < activeRangeEnd; hour += 3) {
      final scheduledTime = DateTime(now.year, now.month, now.day, hour);
      
      if (scheduledTime.isBefore(now)) continue;

      double progressWindow = (hour - activeRangeStart) / (activeRangeEnd - activeRangeStart);
      int expectedIntake = (goal * progressWindow).toInt();

      final String promptTime = hour > 12 ? '${hour - 12} PM' : '$hour AM';

      // Use a dynamic type here to avoid compilation error on Web
      final dynamic androidDetails = AndroidNotificationDetails(
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

      final dynamic iosDetails = DarwinNotificationDetails(
        categoryIdentifier: 'water_actions',
      );

      await _notificationsPlugin.zonedSchedule(
        hour,
        '💧 Stay Hydrated!',
        'Did you drink water since $promptTime? You\'re a bit behind your goal.',
        tz.TZDateTime.from(scheduledTime, tz.local),
        NotificationDetails(
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

    final dynamic androidPlatformChannelSpecifics = AndroidNotificationDetails(
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
    
    final platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _notificationsPlugin.show(
      0,
      '💧 Quick Hydration Check',
      'Did you drink water in the last hour? Log it quickly below!',
      platformChannelSpecifics,
      payload: 'test',
    );
  }
}
