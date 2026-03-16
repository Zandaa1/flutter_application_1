import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

@pragma('vm:entry-point')
class BackgroundService {
  static const String trackingNotificationChannelId =
      'fleet_driver_tracking_alerts_v1';

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
        initialNotificationTitle: 'GPS Tracking is Active',
        initialNotificationContent: 'Your trip has started. GPS tracking is active.',
        foregroundServiceNotificationId: 888,
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
    // Avoid auto-registering all plugins in Android background isolate.
    // Registering flutter_background_service_android again here triggers
    // "only be used in the main isolate" warnings.

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

    service.on('stop').listen((event) {
      service.stopSelf();
    });

    // Background GPS tracking timer - runs every 5 minutes (per project requirements)
    Timer.periodic(const Duration(seconds: 300), (timer) async {
      if (service.runtimeType.toString().contains('Android')) {
        final androidService = service as dynamic;
        try {
          // Check if still foreground
          bool isForeground = await androidService.isForegroundService();
          if (!isForeground) {
            await androidService.setAsForegroundService();
            print('Restored foreground service status');
          }
          
          // DO NOT call setForegroundNotificationInfo() here  
          // as it might recreate the notification without the ongoing flag
          // The initial notification from AndroidConfiguration is already ongoing
        } catch (e) {
          print('Error in service loop: $e');
        }
      }

      // TODO: Get current GPS location
      // TODO: Send location to server API (every 5 minutes as per requirements)
      
      // Send data back to UI
      service.invoke('update', {
        'current_date': DateTime.now().toIso8601String(),
        'status': 'tracking',
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
