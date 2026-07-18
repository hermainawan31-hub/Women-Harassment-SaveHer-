import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart'; // ✅ ADD THIS

import 'firebase_options.dart';
import 'LoginPage.dart';
import 'home_screen.dart';
import 'sos_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SosNotificationService.init();

  // ✅ Request all required permissions ONCE at startup
  await _requestPermissions();

  runApp(const SafeHerApp());
}

/// Request microphone, location, and notification permissions once.
/// This avoids repeated dialogs and ensures they are granted before any SOS.
Future<void> _requestPermissions() async {
  // List of permissions needed
  final permissions = [
    Permission.microphone,
    Permission.location,
    Permission.locationAlways,
    Permission.notification,
  ];

  // Request them all at once
  final statuses = await permissions.request();

  // Log the results for debugging
  for (final entry in statuses.entries) {
    print('${entry.key}: ${entry.value}');
  }

  // If any permission is permanently denied, open app settings
  if (statuses.values.any((s) => s.isPermanentlyDenied)) {
    await openAppSettings();
  }
}

class SafeHerApp extends StatelessWidget {
  const SafeHerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeHer',
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.pink),
      home: const AuthGate(),
    );
  }
}

/// Decides the very first screen shown, every time the app is opened.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginPage();
      },
    );
  }
}