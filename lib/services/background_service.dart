import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

@pragma('vm:entry-point')
class BackgroundService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  @pragma('vm:entry-point')
  static Future<void> initializeService() async {
    await _service.configure(
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
        notificationChannelId: 'fleet_driver_channel',
        initialNotificationTitle: 'Fleet Driver',
        initialNotificationContent: 'Fleet Driver is running in the background',
        foregroundServiceNotificationId: 888,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> startService() async {
    try {
      bool isRunning = await _service.isRunning();
      if (!isRunning) {
        return await _service.startService();
      }
      return true;
    } catch (e) {
      print('Error starting service: $e');
      return false;
    }
  }
@pragma('vm:entry-point')
  
  static Future<bool> stopService() async {
    bool isRunning = await _service.isRunning();
    if (isRunning) {
      _service.invoke('stop');
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
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stop').listen((event) {
      service.stopSelf();
    });

    // Background GPS tracking timer - runs every 60 seconds
    Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          try {
            // Update notification
            service.setForegroundNotificationInfo(
              title: 'Fleet Driver',
              content: 'Fleet Driver is running in the background',
            );
          } catch (e) {
            // Ignore notification errors
          }
        }
      }

      // TODO: Get current GPS location
      // TODO: Send location to server API
      
      // Example: Send data back to UI
      service.invoke('update', {
        'current_date': DateTime.now().toIso8601String(),
        'status': 'tracking',
      });
    });
  }

  @pragma('vm:entry-point')
  static void listenToService(Function(Map<String, dynamic>?) onData) {
    _service.on('update').listen((event) {
      onData(event);
    });
  }
}
