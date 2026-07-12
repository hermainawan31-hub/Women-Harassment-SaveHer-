import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'about_screen.dart';
import 'emergency_contacts_screen.dart';
import 'live_location.dart';
import 'profile_screen.dart';
import 'safety_tips_screen.dart';
import 'settings_screen.dart';
import 'sos_history_screen.dart';
import 'LoginPage.dart';
import 'app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  String? fullName;
  String? photoUrl;

  bool isProfileComplete = false;
  bool isEmergencyContactsComplete = false;
  bool isLocationActive = false; // ✅ NEW

  bool isSendingSos = false;

  late final AnimationController _pulseController;

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final document = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (document.exists) {
      final data = document.data();

      setState(() {
        fullName = data?["fullName"];
        photoUrl = data?["photoUrl"];

        isProfileComplete =
            (data?["fullName"] ?? "").toString().isNotEmpty &&
            (data?["phone"] ?? "").toString().isNotEmpty &&
            (data?["address"] ?? "").toString().isNotEmpty &&
            (data?["bloodGroup"] ?? "").toString().isNotEmpty &&
            (data?["gender"] ?? "").toString().isNotEmpty;

        isEmergencyContactsComplete =
            (data?["contact1Name"] ?? "").toString().isNotEmpty &&
            (data?["contact1Phone"] ?? "").toString().isNotEmpty &&
            (data?["contact1Relation"] ?? "").toString().isNotEmpty &&
            (data?["contact2Name"] ?? "").toString().isNotEmpty &&
            (data?["contact2Phone"] ?? "").toString().isNotEmpty &&
            (data?["contact2Relation"] ?? "").toString().isNotEmpty &&
            (data?["contact3Name"] ?? "").toString().isNotEmpty &&
            (data?["contact3Phone"] ?? "").toString().isNotEmpty &&
            (data?["contact3Relation"] ?? "").toString().isNotEmpty;

        // ✅ LOCATION CHECK ADDED
        isLocationActive = (data?["locationActive"] ?? false) == true;
      });
    }
  }

  // ---------------- SOS ----------------
  Future<void> _triggerSos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Send SOS Alert?"),
        content: const Text(
          "This will notify your emergency contacts and log this alert in your SOS history.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Send SOS",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isSendingSos = true);

    String address = "Location unavailable";
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
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          address =
              "${placemarks.first.street}, ${placemarks.first.locality}, ${placemarks.first.country}";
        }
      }
    } catch (_) {
      // fall back to "Location unavailable"
    }

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("sos_events")
          .add({
            "timestamp": FieldValue.serverTimestamp(),
            "address": address,
            "status": "Sent",
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("SOS alert sent. Stay safe.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Couldn't send SOS: $e")));
      }
    } finally {
      if (mounted) setState(() => isSendingSos = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ---------------- REUSABLE DASHBOARD CARD ----------------
  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool complete,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textDark.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            if (complete)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFE7F8ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF2CB25A),
                  size: 16,
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textDark.withOpacity(0.35),
              ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppColors.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
        ),
      ),
      onTap: onTap,
    );
  }

  // ---------------- QUICK ACTION CHIP ----------------
  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final int completedSteps =
        (isProfileComplete ? 1 : 0) +
        (isEmergencyContactsComplete ? 1 : 0) +
        (isLocationActive ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "SafeHer",
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
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ).then((_) => loadUserData());
            },
          ),
        ],
      ),

      drawer: SafeArea(
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                      AppColors.accent,
                    ],
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl!)
                      : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : null,
                ),
                accountName: Text(
                  fullName ?? "Welcome",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(user?.email ?? ""),
              ),

              _drawerTile(
                icon: Icons.home_rounded,
                title: "Home",
                onTap: () => Navigator.pop(context),
              ),
              _drawerTile(
                icon: Icons.contact_emergency_rounded,
                title: "Emergency Contacts",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmergencyContactsScreen(),
                    ),
                  ).then((_) => loadUserData());
                },
              ),
              _drawerTile(
                icon: Icons.location_on_rounded,
                title: "Location",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LiveLocation()),
                  ).then((_) => loadUserData());
                },
              ),
              _drawerTile(
                icon: Icons.history_rounded,
                title: "SOS history",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SosHistoryScreen()),
                  );
                },
              ),
              _drawerTile(
                icon: Icons.health_and_safety_rounded,
                title: "Safety Tips",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SafetyTipsScreen()),
                  );
                },
              ),
              _drawerTile(
                icon: Icons.info_outline_rounded,
                title: "About",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
              _drawerTile(
                icon: Icons.settings_rounded,
                title: "Settings",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),

              const Divider(height: 24),

              _drawerTile(
                icon: Icons.logout_rounded,
                title: "Logout",
                color: Colors.redAccent,
                onTap: () => logout(context),
              ),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Gradient header with avatar, greeting, quick actions, progress ----
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                      AppColors.accent,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // decorative soft circles
                    Positioned(
                      top: -40,
                      right: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      left: -20,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.6),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white,
                                backgroundImage: photoUrl != null
                                    ? NetworkImage(photoUrl!)
                                    : null,
                                child: photoUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        color: AppColors.primary,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Hello, ${fullName ?? 'there'} 👋",
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "Let's make sure you're fully protected.",
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ---- Quick action row ----
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _quickAction(
                              icon: Icons.location_on_rounded,
                              label: "Location",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LiveLocation(),
                                  ),
                                ).then((_) => loadUserData());
                              },
                            ),
                            _quickAction(
                              icon: Icons.contact_emergency_rounded,
                              label: "Contacts",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const EmergencyContactsScreen(),
                                  ),
                                ).then((_) => loadUserData());
                              },
                            ),
                            _quickAction(
                              icon: Icons.history_rounded,
                              label: "History",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SosHistoryScreen(),
                                  ),
                                );
                              },
                            ),
                            _quickAction(
                              icon: Icons.health_and_safety_rounded,
                              label: "Safety",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SafetyTipsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: completedSteps / 3,
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$completedSteps of 3 safety steps complete",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ---- Big pulsing SOS button ----
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _dashboardCard(
                    icon: Icons.person_outline_rounded,
                    title: "Complete Your Profile",
                    subtitle: "Add your personal info",
                    complete: isProfileComplete,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ).then((_) => loadUserData());
                    },
                  ),
                  const SizedBox(height: 14),

                  _dashboardCard(
                    icon: Icons.contact_emergency_outlined,
                    title: "Emergency Contacts",
                    subtitle: "Add trusted contacts",
                    complete: isEmergencyContactsComplete,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmergencyContactsScreen(),
                        ),
                      ).then((_) => loadUserData());
                    },
                  ),
                  const SizedBox(height: 14),

                  _dashboardCard(
                    icon: Icons.location_on_outlined,
                    title: "Live Location",
                    subtitle: "Enable & share your location",
                    complete: isLocationActive,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LiveLocation()),
                      ).then((_) => loadUserData());
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 26),
                    child: Center(
                      child: GestureDetector(
                        onTap: isSendingSos ? null : _triggerSos,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final pulse = (1 - (_pulseController.value)).clamp(
                              0.0,
                              1.0,
                            );
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 130 + (30 * (1 - pulse)),
                                  height: 130 + (30 * (1 - pulse)),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accent.withOpacity(
                                      0.25 * pulse,
                                    ),
                                  ),
                                ),
                                child!,
                              ],
                            );
                          },
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppColors.accent, AppColors.primary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.45),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: isSendingSos
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.sos_rounded,
                                        color: Colors.white,
                                        size: 34,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "SOS",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      "Tap in an emergency to alert your contacts",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textDark.withOpacity(0.45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
