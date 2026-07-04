import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';          // added for firebase aut
import 'package:cloud_firestore/cloud_firestore.dart';    // added for firebase auth
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
  // when click icon it should go to login
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  // for displaying photo and name in drawer header:
  String? fullName;
  String? photoUrl;
  bool isProfileComplete = false;

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
      (data?["fullName"] ?? "").isNotEmpty &&
      (data?["phone"] ?? "").isNotEmpty &&
      (data?["address"] ?? "").isNotEmpty &&
      (data?["bloodGroup"] ?? "").toString().isNotEmpty &&
      (data?["gender"] ?? "").toString().isNotEmpty;
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
              );
              loadUserData();
            },
          ),
        ],
      ),

      // drawer in safe area and use built‑in user account drawer header
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl!) : null,
                  child: photoUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 45,
                          color: Color(0xFF6C2BD9),
                        )
                      : null,
                ),
                accountName: Text(
                  fullName ?? "Welcome to SafeHer",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(
                  user?.email ?? "No Email",
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text("Home"),
                onTap: () {
                  Navigator.pop(context); // Just close the drawer
                },
              ),
             
              ListTile(
                leading: Icon(Icons.contact_emergency),
                title: Text("Emergency Contacts"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.location_on),
                title: Text("Location"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LiveLocation()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.history),
                title: Text("SOS history"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SosHistoryScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.safety_check),
                title: Text("Safety Tips"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SafetyTipsScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text("About"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text(" Settings"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Logout",style: TextStyle(color: Colors.red),),
                onTap: () => logout(context),
              ),
            ],
          ),
        ),
      ),

      // now we will start building body of our SafeHer:
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // we made banner here :
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 216, 107, 143),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  // for adding content:
                  child: Row(
                    children: [
                      // add icon and content in column in a row :
                      const Icon(
                        Icons.local_police,
                        color: Colors.red,
                        size: 45,
                      ),
                      const SizedBox(width: 16),
                      // all content will be vertical so we will use column here :
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Emergency Helpline",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: const Text(
                              "Police: 15\nRescue: 1122",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Stay calm. Help is just one call away.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
// so now we will do card here for completing profile card:
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      radius: 25,
                      child: Icon(Icons.person),
                    ),
                    title: const Text(
                      "Complete Your Profile",
                    ),
                    subtitle: const Text(
                      "Add your personal information",
                    ),
                    trailing: isProfileComplete
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 30,
                          )
                        : const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                ),
                // here we will do make next card for adding contact :
                // (you can add more cards here)
              ],
            ),
          ),
        ),
      ),
    );
  }
}