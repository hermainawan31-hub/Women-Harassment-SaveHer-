import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sos_recording_service.dart';

import 'firebase_options.dart';

const String kSosChannelId = 'safeher_sos_channel';
const String kSosChannelName = 'SafeHer SOS';
const int kSosNotificationId = 9001;
const String kSosActionId = 'send_sos_action';

final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ---------------------------------------------------------------------------
// This MUST be a top-level (or static) function marked as an entry point.
// Android can invoke this in a fresh, headless Dart isolate even if the app
// process was fully killed — that's what makes "tap notification while app
// is closed" actually work.
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  if (response.actionId == kSosActionId) {
    sendSosFromBackground();
  }
}

class SosNotificationService {
  /// Call once, early in main(), before runApp().
  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handles the tap while the app process is still alive (foreground
        // or background-but-not-killed).
        if (response.actionId == kSosActionId) {
          sendSosFromBackground();
        }
      },
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackgroundHandler,
    );

    const channel = AndroidNotificationChannel(
      kSosChannelId,
      kSosChannelName,
      description: 'Persistent SOS quick-action notification',
      importance: Importance.max,
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(channel);

    // Android 13+ requires runtime permission to post notifications at all.
    await androidPlugin?.requestNotificationsPermission();
  }

  /// Shows the persistent, non-dismissible, lock-screen-visible notification
  /// with a "Send SOS" action button. Call this once the user is logged in
  /// (e.g. HomeScreen.initState).
  static Future<void> showPersistentSosNotification() async {
    const androidDetails = AndroidNotificationDetails(
      kSosChannelId,
      kSosChannelName,
      channelDescription: 'Persistent SOS quick-action notification',
      importance: Importance.max,
      priority: Priority.max,
      ongoing: true, // user can't swipe it away
      autoCancel: false,
      visibility: NotificationVisibility
          .public, // shows full content on the lock screen
      category: AndroidNotificationCategory.alarm,
      color: Color(0xFFFF4D6D),
      actions: [
        AndroidNotificationAction(
          kSosActionId,
          'Send SOS',
          showsUserInterface:
              false, // fires the action without opening the app UI
          cancelNotification: false, // stays up so it can be used again
        ),
      ],
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      kSosNotificationId,
      'SafeHer is protecting you',
      'Tap "Send SOS" any time to alert your emergency contacts.',
      details,
    );
  }

  /// Call on logout so a signed-out device doesn't keep showing an active
  /// SOS action tied to no one.
  static Future<void> cancel() async {
    await _notificationsPlugin.cancel(kSosNotificationId);
  }
}

// ---------------------------------------------------------------------------
// Runs completely independently of any app UI — re-initializes Firebase and
// re-fetches everything it needs from scratch, since the app process may
// have been fully killed when this fires.
// ---------------------------------------------------------------------------
Future<void> sendSosFromBackground() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // no signed-in session to act on

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data == null) return;

    final fullName = data['fullName'] as String?;
    final numbers =
        [data['contact1Phone'], data['contact2Phone'], data['contact3Phone']]
            .where((n) => n != null && n.toString().trim().isNotEmpty)
            .map((n) => n.toString().trim())
            .toList();

    if (numbers.isEmpty) return; // nothing to send to

    String address = "Location unavailable";
    double? lat, lng;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          lat = position.latitude;
          lng = position.longitude;
          final placemarks = await placemarkFromCoordinates(lat, lng);
          address =
              "${placemarks.first.street}, ${placemarks.first.locality}, ${placemarks.first.country}";
        }
      }
    } catch (_) {
      // fall back to "Location unavailable"
    }

    final sosEventRef = await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .collection('sos_events')
    .add({
      'timestamp': FieldValue.serverTimestamp(),
      'address': address,
      'status': 'Sent (background)',
    });

// Start recording immediately (fire-and-forget).
SosRecordingService.start(sosEventRef.id);

    final mapsLink = (lat != null && lng != null)
        ? "https://maps.google.com/?q=$lat,$lng"
        : null;
    final message =
        "🚨 SOS Alert from ${fullName ?? 'me'}! I need help right now.\n"
        "My location: $address"
        "${mapsLink != null ? '\nMap: $mapsLink' : ''}";

    final smsUri = Uri(
      scheme: 'sms',
      path: numbers.join(','),
      queryParameters: {'body': message},
    );

    await launchUrl(smsUri);
  } catch (_) {
    // Best-effort — there's no UI available from a headless callback to
    // show an error to, so we just fail silently rather than crash.
  }
}
