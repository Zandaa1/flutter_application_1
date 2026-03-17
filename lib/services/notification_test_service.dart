import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'background_service.dart';

class NotificationTestService {
  static const String _channelId = 'trip_assignment_important_v2';
  static const String _channelName = 'Trip Assignment Alerts';
  static const String _channelDescription =
      'Important notifications when a new trip is assigned.';
  static const String _trackingChannelName = 'Ride Tracking Alerts';
  static const String _trackingChannelDescription =
      'Foreground ride tracking notifications and service status.';
  static const String _liveChannelId = 'live_update_channel';
  static const String _liveChannelName = 'Live Updates';
  static const String _liveChannelDescription =
      'Continuous updates for distance or status.';

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: false,
        enableVibration: true,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        BackgroundService.trackingNotificationChannelId,
        _trackingChannelName,
        description: _trackingChannelDescription,
        importance: Importance
            .low, // Lower importance so it doesn't pop up or make noise
        playSound: false,
        enableVibration: false,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _liveChannelId,
        _liveChannelName,
        description: _liveChannelDescription,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
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
      playSound: false,
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

  /// The initial distance captured at ride start, used to calculate progress.
  static double? _initialDistance;

  /// Fires the ride notification as a live update with a progress bar.
  /// Called once when the ride starts, and then on each GPS update.
  static Future<void> sendRideStartedNotification({
    required String destination,
    required String truckNumber,
  }) async {
    await initialize();
    if (kIsWeb) return;

    // Initial notification — indeterminate progress while waiting for GPS
    final androidDetails = AndroidNotificationDetails(
      BackgroundService.trackingNotificationChannelId,
      _trackingChannelName,
      channelDescription: _trackingChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.service,
      showWhen: false,
      subText: 'Arriving to $destination',
      showProgress: true,
      maxProgress: 1000,
      progress: 0,
      indeterminate: true,
    );

    _initialDistance = null; // Reset progress for new ride

    await _notificationsPlugin.show(
      BackgroundService.trackingNotificationId,
      'Active Job — Truck $truckNumber',
      'Calculating route...',
      NotificationDetails(android: androidDetails),
    );
  }

  /// Updates the live notification with the current distance progress.
  static Future<void> sendLiveUpdateNotification({
    required double distanceMeters,
    required String destination,
  }) async {
    await initialize();
    if (kIsWeb) return;

    _initialDistance ??= distanceMeters;
    if (_initialDistance! < 1) {
      _initialDistance = distanceMeters > 0 ? distanceMeters : 1;
    }

    final distanceStr = distanceMeters >= 1000
        ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
        : '${distanceMeters.toStringAsFixed(0)} m';

    double progress = (_initialDistance! - distanceMeters) / _initialDistance!;
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;

    bool isArrived = distanceMeters <= 250;

    final androidDetails = AndroidNotificationDetails(
      BackgroundService.trackingNotificationChannelId,
      _trackingChannelName,
      channelDescription: _trackingChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.service,
      showWhen: false,
      subText: isArrived
          ? 'Arrived at $destination'
          : 'Arriving to $destination',
      showProgress: true,
      maxProgress: 1000,
      progress: (progress * 1000).toInt(),
      indeterminate: false,
    );

    await _notificationsPlugin.show(
      BackgroundService.trackingNotificationId,
      isArrived ? "You're here!" : 'Active Job',
      isArrived ? 'You can now complete the job.' : '$distanceStr remaining',
      NotificationDetails(android: androidDetails),
    );
  }

  /// Updates the live notification when GPS is waiting or distance is unknown.
  static Future<void> sendIndeterminateLiveUpdateNotification({
    required String content,
    required String destination,
  }) async {
    await initialize();
    if (kIsWeb) return;

    final androidDetails = AndroidNotificationDetails(
      BackgroundService.trackingNotificationChannelId,
      _trackingChannelName,
      channelDescription: _trackingChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.service,
      showWhen: false,
      subText: 'Arriving to $destination',
      showProgress: true,
      maxProgress: 1000,
      progress: 0,
      indeterminate: true,
    );

    await _notificationsPlugin.show(
      BackgroundService.trackingNotificationId,
      'Active Job',
      content,
      NotificationDetails(android: androidDetails),
    );
  }

  /// Cancels the ride notification (call when ride ends).
  static Future<void> cancelRideNotification() async {
    if (kIsWeb) return;
    _initialDistance = null;
    await _notificationsPlugin.cancel(BackgroundService.trackingNotificationId);
  }

  /// Cancels the live update notification (alias, same ID).
  static Future<void> cancelLiveUpdateNotification() async {
    await cancelRideNotification();
  }
}
