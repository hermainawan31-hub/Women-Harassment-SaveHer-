import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import 'app_colors.dart';

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

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  static const latlng.LatLng _defaultCenter = latlng.LatLng(
    24.8607,
    67.0011,
  ); // fallback: Karachi

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

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

    // Show the user's current spot on the map immediately,
    // even before "Start Location" tracking begins.
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _updateMapPosition(position);
  }

  // ---------------- START LOCATION ----------------
  Future<void> startLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get an immediate fix first.
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    await _handleNewPosition(position, user.uid);

    setState(() {
      trackingStarted = true;
      statusText = "Live Location ON";
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Live Location Started")));

    // Then keep listening so the map/marker/address/Firestore
    // update in real time as the device moves.
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // meters moved before an update fires
    );

    _positionStream?.cancel();
    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position pos) {
            _handleNewPosition(pos, user.uid);
          },
        );
  }

  // ---------------- STOP LOCATION ----------------
  Future<void> stopLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _positionStream?.cancel();
    _positionStream = null;

    await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
      "locationActive": false,
    }, SetOptions(merge: true));

    setState(() {
      trackingStarted = false;
      statusText = "Live Location OFF";
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Live Location Stopped")));
  }

  // ---------------- SHARED: handle a new fix ----------------
  Future<void> _handleNewPosition(Position position, String uid) async {
    latitude = position.latitude;
    longitude = position.longitude;

    // convert coordinates to address
    List<Placemark> placemarks = await placemarkFromCoordinates(
      latitude!,
      longitude!,
    );

    final newAddress =
        "${placemarks.first.street}, ${placemarks.first.locality}, ${placemarks.first.country}";

    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "locationActive": true,
      "latitude": latitude,
      "longitude": longitude,
      "liveLocation": newAddress,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      address = newAddress;
    });

    _updateMapPosition(position);
  }

  // ---------------- MAP: move camera + marker to the latest fix ----------------
  void _updateMapPosition(Position position) {
    final point = latlng.LatLng(position.latitude, position.longitude);

    setState(
      () {},
    ); // refresh marker position (built from latitude/longitude below)

    _mapController.move(point, 16);
  }

  // ---------------- THEMED ACTION BUTTON ----------------
  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    if (filled) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: onPressed == null
                ? null
                : const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: onPressed == null ? const Color(0xFFE3E0EE) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: onPressed == null
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: onPressed == null
                  ? AppColors.textDark.withOpacity(0.35)
                  : Colors.white,
            ),
            label: Text(
              label,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: onPressed == null
                    ? AppColors.textDark.withOpacity(0.35)
                    : Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed == null
              ? AppColors.textDark.withOpacity(0.35)
              : AppColors.primary,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: onPressed == null
                ? AppColors.textDark.withOpacity(0.35)
                : AppColors.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: onPressed == null
                ? const Color(0xFFE3E0EE)
                : AppColors.primary,
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPoint = (latitude != null && longitude != null)
        ? latlng.LatLng(latitude!, longitude!)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Live Location",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ---------------- MAP ----------------
          SizedBox(
            height: MediaQuery.of(context).padding.top + 320,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: currentPoint ?? _defaultCenter,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.example.women_harassment_saveher',
                    ),
                    if (currentPoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: currentPoint,
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.location_on,
                              color: locationEnabled
                                  ? const Color(0xFF2CB25A)
                                  : AppColors.accent,
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
                // gentle top gradient so the AppBar text stays legible over map tiles
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).padding.top + 60,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryDark.withOpacity(0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------------- STATUS + CONTROLS ----------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 22,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color:
                                (locationEnabled
                                        ? const Color(0xFF2CB25A)
                                        : AppColors.accent)
                                    .withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            locationEnabled
                                ? Icons.location_on
                                : Icons.location_off,
                            size: 34,
                            color: locationEnabled
                                ? const Color(0xFF2CB25A)
                                : AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (address != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            address!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textDark.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _actionButton(
                    label: "Turn ON Location",
                    icon: Icons.my_location_rounded,
                    onPressed: enableLocation,
                    filled: true,
                  ),
                  const SizedBox(height: 12),

                  _actionButton(
                    label: "Start Location",
                    icon: Icons.play_arrow_rounded,
                    onPressed: locationEnabled ? startLocation : null,
                  ),
                  const SizedBox(height: 12),

                  _actionButton(
                    label: "Stop Location",
                    icon: Icons.stop_rounded,
                    onPressed: trackingStarted ? stopLocation : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
