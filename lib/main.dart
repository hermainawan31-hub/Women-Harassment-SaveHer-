import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'LoginPage.dart';
import 'home_screen.dart';
import 'sos_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SosNotificationService.init();

  runApp(const SafeHerApp());
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

/// Decides the very first screen shown, every time the app is opened —
/// whether that's tapping the app icon, tapping the persistent SOS
/// notification, or resuming from the task switcher.
///
/// If a signed-in session already exists, it goes straight to HomeScreen
/// instead of forcing the user through LoginPage again.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still checking Firebase's cached session — show a brief loader
        // instead of flashing the login screen first.
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
