// main.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/student/student_home.dart';
import 'screens/admin/admin_panel.dart';
import 'screens/admin/add_student.dart';
import 'screens/admin/requested_gate_pass.dart';
import 'screens/admin/student_list_page.dart';
import 'screens/auth/universal_signin.dart';
import 'screens/security/qr_scanner_page.dart';
import 'screens/resolve_role.dart';
import 'screens/settings/settings_screen.dart';

/// ------------------ LOCAL NOTIFICATIONS SETUP ------------------ ///
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
    debugPrint('Local notification tapped. Payload: ${response.payload}');
  });

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);

  runApp(const HostelApp());
}

class HostelApp extends StatelessWidget {
  const HostelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hostel Gate Pass',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: _router,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// ------------------ GoRouter Definition ------------------ ///
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/signin', builder: (context, state) => const UniversalSignIn()),
    GoRoute(path: '/resolve', builder: (context, state) => const ResolveRolePage()),
    GoRoute(path: '/admin', builder: (context, state) => const AdminPanel()),
    GoRoute(path: '/add-student', builder: (context, state) => AddStudentPage()),
    GoRoute(path: '/requested-gate-pass', builder: (context, state) => const RequestedGatePass()),
    GoRoute(path: '/qr-scanner', builder: (context, state) => const QRScannerPage()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(
      path: '/student-home',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return StudentHomeScreen(
          studentName: extra['studentName'] ?? 'Student',
          profileImageUrl: extra['profileImageUrl'] ?? '',
        );
      },
    ),
    GoRoute(path: '/student-list', builder: (context, state) => const StudentListPage()),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Page Not Found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The page you are looking for doesn\'t exist.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Go to Home'),
          ),
        ],
      ),
    ),
  ),
);
