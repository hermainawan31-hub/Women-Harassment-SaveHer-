import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'sos_recording_service.dart';

class SafeHerSOSService {
  static const Duration _recordingTimeout = Duration(seconds: 60);

  static Future<void> startSOS() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // ---- Get user data ----
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();
    final data = userDoc.data() ?? {};
    final fullName = data["fullName"] as String? ?? "SafeHer User";

    // Extract contacts with explicit null handling
    final contacts = [
      data["contact1Phone"] as String?,
      data["contact2Phone"] as String?,
      data["contact3Phone"] as String?,
    ].where((e) => e != null && e.isNotEmpty).map((e) => e!).toList();

    // ---- Get location ----
    String address = "Location unavailable";
    Position? position;
    bool hasLocation = false;

    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      hasLocation = true;
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      address =
          "${placemarks.first.street}, ${placemarks.first.locality}, ${placemarks.first.country}";
        } catch (e) {
      // fallback to "Location unavailable"
    }

    // ---- Save SOS history ----
    final sosEvent = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("sos_events")
        .add({
      "timestamp": FieldValue.serverTimestamp(),
      "address": address,
      "status": "Sent",
    });

    // ---- Start recording ----
    await SosRecordingService.start(sosEvent.id);

    // ---- Auto‑stop recording after timeout (for widget/background triggers) ----
    Timer(_recordingTimeout, () async {
      if (SosRecordingService.isRecording) {
        await SosRecordingService.stopAndSave(
          contactNumbers: contacts,
          callerName: fullName,
        );
      }
    });

    // ---- Build message ----
    final mapLink = hasLocation && position != null
        ? "https://maps.google.com/?q=${position.latitude},${position.longitude}"
        : "";
    final message =
        "🚨 SOS Alert from $fullName\n"
        "I need help.\n"
        "Location: $address\n"
        "$mapLink";

    // ---- Open SMS app ----
    if (contacts.isNotEmpty) {
      final smsUri = Uri(
        scheme: "sms",
        path: contacts.join(","),
        queryParameters: {"body": message},
      );
      final opened = await launchUrl(smsUri);
      if (!opened) {
        await Share.share(message);
      }
    }
  }
}