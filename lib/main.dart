import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pre_ride_screen.dart';
import 'screens/active_ride_screen.dart';
import 'screens/post_ride_screen.dart';
import 'screens/fuel_receipt_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/admin_tools_screen.dart';
import 'screens/add_toll_screen.dart';
import 'screens/post_trip_photos_screen.dart';
import 'services/background_service.dart';
import 'services/notification_test_service.dart';
import 'services/mock_backend_service.dart';
import 'utils/app_theme.dart';
import 'utils/agent_debug_log.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // #region agent log
    unawaited(AgentDebugLog.log(
      location: 'main.dart:main',
      message: 'App starting',
      runId: 'pre-fix',
      hypothesisId: 'GLOBAL',
    ));
    // #endregion

    // Capture framework errors.
    FlutterError.onError = (details) {
      // #region agent log
      unawaited(AgentDebugLog.log(
        location: 'main.dart:FlutterError.onError',
        message: 'Flutter framework error',
        runId: 'pre-fix',
        hypothesisId: 'GLOBAL',
        data: {
          'exception': details.exceptionAsString(),
          'library': details.library,
        },
      ));
      // #endregion
      FlutterError.presentError(details);
    };

    // Capture uncaught async errors. test
    PlatformDispatcher.instance.onError = (error, stack) {
      // #region agent log
      unawaited(AgentDebugLog.log(
        location: 'main.dart:PlatformDispatcher.onError',
        message: 'Uncaught platform dispatcher error',
        runId: 'pre-fix',
        hypothesisId: 'GLOBAL',
        data: {'error': error.toString()},
      ));
      // #endregion
      return false;
    };

    // Initialize local notification channels first.
    await NotificationTestService.initialize();

    // Initialize background service
    await BackgroundService.initializeService();

    // Initialize mock backend (offline testing)
    await MockBackendService.initialize();

    runApp(const FleetDriverApp());
  }, (error, stack) {
    // #region agent log
    unawaited(AgentDebugLog.log(
      location: 'main.dart:runZonedGuarded',
      message: 'Uncaught zone error',
      runId: 'pre-fix',
      hypothesisId: 'GLOBAL',
      data: {'error': error.toString()},
    ));
    // #endregion
  });
}

/// Global theme-mode notifier — readable/writable from any screen.
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

class FleetDriverApp extends StatelessWidget {
  const FleetDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Fleet Driver App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,

          // Routes
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/pre-ride': (context) => const PreRideScreen(),
            '/active-ride': (context) => const ActiveRideScreen(),
            '/post-ride': (context) => const PostRideScreen(),
            '/fuel-receipt': (context) => const FuelReceiptScreen(),
            '/chat': (context) => const ChatScreen(),
            '/admin-tools': (context) => const AdminToolsScreen(),
            '/add-toll': (context) => const AddTollScreen(),
            '/post-trip-photos': (context) => const PostTripPhotosScreen(),
          },
        );
      },
    );
  }
}
