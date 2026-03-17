import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import 'mock_backend_service.dart';
import 'notification_test_service.dart';

@pragma('vm:entry-point')
class BackgroundService {
  static const String trackingNotificationChannelId =
      'fleet_driver_tracking_alerts_v1';
  static const int trackingNotificationId = 888;

  @pragma('vm:entry-point')
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: false,
        autoStartOnBoot: false,
        notificationChannelId: trackingNotificationChannelId,
        initialNotificationTitle: 'Active Job — GPS Tracking',
        initialNotificationContent: 'Tracking is running. Cannot be dismissed while job is active.',
        foregroundServiceNotificationId: trackingNotificationId,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> startService() async {
    try {
      final service = FlutterBackgroundService();
      bool isRunning = await service.isRunning();
      if (!isRunning) {
        return await service.startService();
      }
      return true;
    } catch (e) {
      print('Error starting service: $e');
      return false;
    }
  }

  /// Send destination coordinates and name to the running background service.
  static void sendDestination(double destLat, double destLng, String destName) {
    final service = FlutterBackgroundService();
    service.invoke('setDestination', {
      'destLat': destLat,
      'destLng': destLng,
      'destName': destName,
    });
  }

@pragma('vm:entry-point')
  
  static Future<bool> stopService() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke('stop');
      return true;
    }
    return false;
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    // Destination coords and name — updated via 'setDestination' invoke from UI.
    double? destLat;
    double? destLng;
    String destName = 'destination';

    // Only android-specific setup
    if (service.runtimeType.toString().contains('Android')) {
      final androidService = service as dynamic;
      
      // Immediately set as foreground - this creates the initial ongoing notification
      try {
        await androidService.setAsForegroundService();
        print('Service set as foreground successfully');
      } catch (e) {
        print('Error setting foreground: $e');
      }
      
      service.on('setAsForeground').listen((event) async {
        await androidService.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        // Prevent setting as background - keep it foreground always
        androidService.setAsForegroundService();
      });
    }

    // Accept destination coords sent from the UI when the ride starts.
    service.on('setDestination').listen((event) {
      if (event != null) {
        destLat = (event['destLat'] as num?)?.toDouble();
        destLng = (event['destLng'] as num?)?.toDouble();
        destName = (event['destName'] as String?) ?? 'destination';
        print('Destination set: $destLat, $destLng ($destName)');
      }
    });

    service.on('stop').listen((event) {
      service.stopSelf();
    });

    // Background GPS tracking timer — updates every 60 seconds.
    Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (service.runtimeType.toString().contains('Android')) {
        final androidService = service as dynamic;
        try {
          bool isForeground = await androidService.isForegroundService();
          if (!isForeground) {
            await androidService.setAsForegroundService();
            print('Restored foreground service status');
          }
        } catch (e) {
          print('Error in service loop: $e');
        }
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      } catch (e) {
        // ignore - permission/service issues will be handled in UI gate
      }

      if (pos != null) {
        await MockBackendService.initialize();
        await MockBackendService.addLocationPing(
          LocationPing(
            lat: pos.latitude,
            lng: pos.longitude,
            accuracyMeters: pos.accuracy,
            at: DateTime.now(),
          ),
        );
      }

      // Compute distance to destination if we have both positions.
      double? distMeters;
      if (pos != null && destLat != null && destLng != null) {
        distMeters = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          destLat!,
          destLng!,
        );
      }

      // Build the notification content line.
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      String notifContent;
      if (pos == null) {
        notifContent = 'Waiting for GPS signal…  •  $timeStr';
      } else {
        final coordStr =
            'Lat ${pos.latitude.toStringAsFixed(4)}, Lng ${pos.longitude.toStringAsFixed(4)}';
        if (distMeters != null) {
          final distStr = distMeters >= 1000
              ? '${(distMeters / 1000).toStringAsFixed(1)} km remaining'
              : '${distMeters.toStringAsFixed(0)} m remaining';
          notifContent = '$distStr  •  $coordStr  •  $timeStr';
        } else {
          notifContent = '$coordStr  •  Updated $timeStr';
        }
      }

      // Update the persistent notification using the live update format.
      if (service.runtimeType.toString().contains('Android')) {
        final androidService = service as dynamic;
        if (distMeters != null) {
          // Use the NotificationTestService to show a progress-bar notification
          try {
            await NotificationTestService.sendLiveUpdateNotification(
              distanceMeters: distMeters,
              destination: destName,
            );
          } catch (e) {
            // Fallback to plain text if NotificationTestService fails in isolate
            try {
              await androidService.setForegroundNotificationInfo(
                title: 'Active Job — GPS Tracking',
                content: notifContent,
              );
            } catch (_) {}
          }
        } else {
          try {
            await NotificationTestService.sendIndeterminateLiveUpdateNotification(
              content: notifContent,
              destination: destName,
            );
          } catch (e) {
            try {
              await androidService.setForegroundNotificationInfo(
                title: 'Active Job — GPS Tracking',
                content: notifContent,
              );
            } catch (_) {}
          }
        }
      }

      // Send data back to UI (distance included so the screen can display it).
      service.invoke('update', {
        'current_date': DateTime.now().toIso8601String(),
        'status': 'tracking',
        if (pos != null) 'lat': pos.latitude,
        if (pos != null) 'lng': pos.longitude,
        if (pos != null) 'accuracy': pos.accuracy,
        if (distMeters != null) 'distanceMeters': distMeters,
      });
    });
  }

  @pragma('vm:entry-point')
  static void listenToService(Function(Map<String, dynamic>?) onData) {
    final service = FlutterBackgroundService();
    service.on('update').listen((event) {
      onData(event);
    });
  }
}
