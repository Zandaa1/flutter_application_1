import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

class NotificationTestService {
  static const String _channelId = 'trip_assignment_important_v1';
  static const String _channelName = 'Trip Assignment Alerts';
  static const String _channelDescription =
      'Important notifications when a new trip is assigned.';

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);

    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> sendTripAssignedNotification({
    required DateTime tripDate,
    required String destination,
  }) async {
    await initialize();

    if (kIsWeb) {
      return;
    }

    final dateLabel = DateFormat('MMM dd, yyyy').format(tripDate);
    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.message,
    );

    await _notificationsPlugin.show(
      notificationId,
      'New Trip Assignment',
      'You have received a trip.\nDate: $dateLabel\nDestination: $destination',
      const NotificationDetails(android: androidDetails),
    );
  }
}