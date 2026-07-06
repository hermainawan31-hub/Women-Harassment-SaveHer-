import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

class LiveLocation extends StatefulWidget {
  const LiveLocation({super.key});

  @override
  State<LiveLocation> createState() => _LiveLocationState();
}

class _LiveLocationState extends State<LiveLocation> {
  bool locationEnabled = false;
  bool trackingStarted = false;

  String statusText = "Location is OFF";

  double? latitude;
  double? longitude;
  String? address;

  // ---------------- ENABLE LOCATION ----------------
  Future<void> enableLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    setState(() {
      locationEnabled = true;
      statusText = "Location is ON";
    });
  }

  // ---------------- START LOCATION ----------------
  Future<void> startLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    latitude = position.latitude;
    longitude = position.longitude;

    // 👉 convert coordinates to address
    List<Placemark> placemarks =
        await placemarkFromCoordinates(latitude!, longitude!);

    address =
        "${placemarks.first.street}, ${placemarks.first.locality}, ${placemarks.first.country}";

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set({
      "locationActive": true,
      "latitude": latitude,
      "longitude": longitude,
      "liveLocation": address,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      trackingStarted = true;
      statusText = "Live Location ON";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Live Location Started")),
    );
  }

  // ---------------- STOP LOCATION ----------------
  Future<void> stopLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set({
      "locationActive": false,
    }, SetOptions(merge: true));

    setState(() {
      trackingStarted = false;
      statusText = "Live Location OFF";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Live Location Stopped")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Location"),
        backgroundColor: const Color.fromARGB(255, 158, 11, 87),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(
              locationEnabled
                  ? Icons.location_on
                  : Icons.location_off,
              size: 100,
              color: locationEnabled ? Colors.green : Colors.red,
            ),

            const SizedBox(height: 20),

            Text(
              statusText,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (address != null)
              Text(
                address!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: enableLocation,
                child: const Text("Turn ON Location"),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: locationEnabled ? startLocation : null,
                child: const Text("Start Location"),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: trackingStarted ? stopLocation : null,
                child: const Text("Stop Location"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}