import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pre_ride_screen.dart';
import 'screens/active_ride_screen.dart';
import 'screens/post_ride_screen.dart';
import 'screens/fuel_receipt_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/admin_tools_screen.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background service
  await BackgroundService.initializeService();
  
  runApp(const FleetDriverApp());
}

class FleetDriverApp extends StatelessWidget {
  const FleetDriverApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fleet Driver App',
      debugShowCheckedModeBanner: false,
      
      // Light Theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          secondary: const Color(0xFF10B981), // Emerald
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      
      // Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          secondary: const Color(0xFF10B981), // Emerald
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      
      // Theme Mode (system default)
      themeMode: ThemeMode.system,
      
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
      },
    );
  }
}