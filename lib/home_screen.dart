import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'about_screen.dart';
import 'emergency_contacts_screen.dart';
import 'live_location.dart';
import 'profile_screen.dart';
import 'safety_tips_screen.dart';
import 'settings_screen.dart';
import 'sos_history_screen.dart';
import 'LoginPage.dart';
import 'app_colors.dart';
import 'sos_notification_service.dart';
import 'sos_recording_service.dart';
import 'safeher_sos_service.dart';
import 'guide_screen.dart';
import 'custom_app_bar.dart'; // new import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // ---- User data ----
  String? fullName;
  String? photoUrl;
  bool isProfileComplete = false;
  bool isEmergencyContactsComplete = false;
  bool isLocationActive = false;
  String? contact1Phone;
  String? contact2Phone;
  String? contact3Phone;

  // ---- SOS states ----
  bool isSendingSos = false;
  bool isRecordingSos = false;
  bool isArmed = false;
  int _volumePressCount = 0;
  Timer? _armTimer;
  StreamSubscription<dynamic>? _volumeEventSub;

  // ---- Channels ----
  static const MethodChannel _volumeMethodChannel =
      MethodChannel('safeher/volume_control');
  static const EventChannel _volumeEventChannel =
      EventChannel('safeher/volume_events');
  static const MethodChannel _widgetChannel =
      MethodChannel("safeher/widget");

  late final AnimationController _pulseController;

  // ---- Logout ----
  Future<void> logout(BuildContext context) async {
    await SosNotificationService.cancel();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  // ---- Load user data ----
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
        isLocationActive = (data?["locationActive"] ?? false) == true;
        contact1Phone = data?["contact1Phone"];
        contact2Phone = data?["contact2Phone"];
        contact3Phone = data?["contact3Phone"];
      });
    }
  }

  // ---- SOS: ARM ----
  Future<void> _onSosTap() async {
    if (isArmed) {
      await _disarmSos(message: "SOS cancelled.");
      return;
    }

    setState(() {
      isArmed = true;
      _volumePressCount = 0;
    });

    try {
      await _volumeMethodChannel.invokeMethod('setArmed', {'armed': true});
    } catch (_) {
      await _disarmSos();
      await _performSos();
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Press Volume Up twice within 10s to test SOS. Tap SOS again to cancel.",
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }

    _volumeEventSub?.cancel();
    _volumeEventSub = _volumeEventChannel.receiveBroadcastStream().listen((
      _,
    ) async {
      _volumePressCount++;
      if (_volumePressCount >= 2) {
        await _disarmSos();
        await _performSos();
      }
    });

    _armTimer?.cancel();
    _armTimer = Timer(const Duration(seconds: 10), () {
      _disarmSos(message: "SOS confirmation timed out.");
    });
  }

  Future<void> _disarmSos({String? message}) async {
    _armTimer?.cancel();
    _armTimer = null;
    await _volumeEventSub?.cancel();
    _volumeEventSub = null;

    try {
      await _volumeMethodChannel.invokeMethod('setArmed', {'armed': false});
    } catch (_) {}

    if (mounted) {
      setState(() {
        isArmed = false;
        _volumePressCount = 0;
      });
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _performSos() async {
    if (isSendingSos) return;
    setState(() => isSendingSos = true);
    await SafeHerSOSService.startSOS();
    setState(() {
      isRecordingSos = SosRecordingService.isRecording;
      isSendingSos = false;
    });
  }

  Future<void> _stopSosRecording() async {
    final numbers = [contact1Phone, contact2Phone, contact3Phone]
        .where((n) => n != null && n.trim().isNotEmpty)
        .map((n) => n!.trim())
        .toList();

    final saved = await SosRecordingService.stopAndSave(
      contactNumbers: numbers,
      callerName: fullName,
    );

    if (mounted) {
      setState(() => isRecordingSos = false);
      if (!saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved successfully")),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
    SosNotificationService.showPersistentSosNotification();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _widgetChannel.setMethodCallHandler((call) async {
      if (call.method == "triggerSos") {
        await _performSos();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _armTimer?.cancel();
    _volumeEventSub?.cancel();
    _volumeMethodChannel
        .invokeMethod('setArmed', {'armed': false})
        .catchError((_) {});
    super.dispose();
  }

  // ---- UI Helpers ----
  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool complete,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                borderRadius: BorderRadius.circular(12),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
          fontWeight: FontWeight.w500,
          fontSize: 14.5,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
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
      appBar: CustomAppBar(
        title: 'SafeHer',
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
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl!) : null,
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
            // ---- HEADER (flush with app bar) ----
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + kToolbarHeight,
                  20,
                  24,
                ),
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
                
                child: Column(
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
                            backgroundImage:
                                photoUrl != null
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
                                "Hello, ${fullName ?? 'there'}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
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
                    const SizedBox(height: 18),
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
                                builder: (_) => const EmergencyContactsScreen(),
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
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: completedSteps / 3,
                        minHeight: 6,
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
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ---- SOS BUTTON ----
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: GestureDetector(
                  onTap: isSendingSos ? null : _onSosTap,
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
                            width: 140 + (30 * (1 - pulse)),
                            height: 140 + (30 * (1 - pulse)),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (isArmed ? Colors.orange : AppColors.accent)
                                  .withOpacity(0.2 * pulse),
                            ),
                          ),
                          child!,
                        ],
                      );
                    },
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isArmed
                            ? const LinearGradient(
                                colors: [Colors.orange, AppColors.accent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [AppColors.accent, AppColors.primary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: (isArmed ? Colors.orange : AppColors.accent)
                                .withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: isSendingSos
                          ? const CircularProgressIndicator(color: Colors.white)
                          : isArmed
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.volume_up_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _volumePressCount == 0
                                      ? "Press Vol x2"
                                      : "1 more…",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sos_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                SizedBox(height: 4),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Text(
                isArmed
                    ? "Press Volume Up twice to confirm — tap SOS to cancel"
                    : "Tap the SOS button to test the emergency alert",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textDark.withOpacity(0.45),
                ),
              ),
            ),
            if (isRecordingSos)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _stopSosRecording,
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: const Text("Stop Recording"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
            // ---- CARDS SECTION ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // How-to card
                  _dashboardCard(
                    icon: Icons.help_outline_rounded,
                    title: "How to Use SafeHer",
                    subtitle: "Learn how the app works step by step",
                    complete: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GuideScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
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
                        MaterialPageRoute(
                          builder: (_) => const LiveLocation(),
                        ),
                      ).then((_) => loadUserData());
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}