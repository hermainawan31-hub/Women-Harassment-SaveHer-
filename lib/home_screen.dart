import 'package:flutter/material.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        isLocationActive =
            (data?["locationActive"] ?? false) == true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("SafeHer"),
        backgroundColor: const Color.fromARGB(255, 158, 11, 87),
        foregroundColor: Colors.white,
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
                    colors: [
                      Color.fromARGB(255, 133, 15, 64),
                      Color.fromARGB(255, 107, 1, 61),
                    ],
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl!) : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                accountName: Text(fullName ?? "Welcome"),
                accountEmail: Text(user?.email ?? ""),
              ),

              ListTile(
                leading: const Icon(Icons.home),
                title: const Text("Home"),
                onTap: () => Navigator.pop(context),
              ),

              ListTile(
                leading: const Icon(Icons.contact_emergency),
                title: const Text("Emergency Contacts"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmergencyContactsScreen(),
                    ),
                  ).then((_) => loadUserData());
                },
              ),

              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text("Location"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LiveLocation(),
                    ),
                  ).then((_) => loadUserData());
                },
              ),

              ListTile(
                leading: const Icon(Icons.history),
                title: const Text("SOS history"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SosHistoryScreen(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.safety_check),
                title: const Text("Safety Tips"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SafetyTipsScreen(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text("About"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AboutScreen(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Settings"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Logout",
                    style: TextStyle(color: Colors.red)),
                onTap: () => logout(context),
              ),
            ],
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // PROFILE CARD
            Card(
              child: ListTile(
                title: const Text("Complete Your Profile"),
                subtitle: const Text("Add your personal info"),
                trailing: isProfileComplete
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  ).then((_) => loadUserData());
                },
              ),
            ),

            const SizedBox(height: 15),

            // EMERGENCY CONTACTS
            Card(
              child: ListTile(
                title: const Text("Emergency Contacts"),
                subtitle: const Text("Add trusted contacts"),
                trailing: isEmergencyContactsComplete
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.arrow_forward_ios),
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
            ),

            const SizedBox(height: 15),

            // ✅ NEW: LIVE LOCATION CARD
            Card(
              child: ListTile(
                title: const Text("Live Location"),
                subtitle: const Text("Enable & share your location"),
                trailing: isLocationActive
                    ? const Icon(Icons.check_circle,
                        color: Colors.green)
                    : const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LiveLocation(),
                    ),
                  ).then((_) => loadUserData());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}