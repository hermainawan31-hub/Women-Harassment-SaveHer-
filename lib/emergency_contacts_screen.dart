import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends State<EmergencyContactsScreen> {

  final TextEditingController contact1NameController =
      TextEditingController();
  final TextEditingController contact1PhoneController =
      TextEditingController();
  final TextEditingController contact1RelationController =
      TextEditingController();

  final TextEditingController contact2NameController =
      TextEditingController();
  final TextEditingController contact2PhoneController =
      TextEditingController();
  final TextEditingController contact2RelationController =
      TextEditingController();

  final TextEditingController contact3NameController =
      TextEditingController();
  final TextEditingController contact3PhoneController =
      TextEditingController();
  final TextEditingController contact3RelationController =
      TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool isContactsCompleted = false;

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  Future<void> saveContacts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection("users").doc(user.uid).set({
        "contact1Name": contact1NameController.text.trim(),
        "contact1Phone": contact1PhoneController.text.trim(),
        "contact1Relation": contact1RelationController.text.trim(),

        "contact2Name": contact2NameController.text.trim(),
        "contact2Phone": contact2PhoneController.text.trim(),
        "contact2Relation": contact2RelationController.text.trim(),

        "contact3Name": contact3NameController.text.trim(),
        "contact3Phone": contact3PhoneController.text.trim(),
        "contact3Relation": contact3RelationController.text.trim(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Emergency Contacts Saved"),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> loadContacts() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore
        .collection("users")
        .doc(user.uid)
        .get();

    final data = doc.data();

    if (data != null) {
      contact1NameController.text = data["contact1Name"] ?? "";
      contact1PhoneController.text = data["contact1Phone"] ?? "";
      contact1RelationController.text = data["contact1Relation"] ?? "";

      contact2NameController.text = data["contact2Name"] ?? "";
      contact2PhoneController.text = data["contact2Phone"] ?? "";
      contact2RelationController.text = data["contact2Relation"] ?? "";

      contact3NameController.text = data["contact3Name"] ?? "";
      contact3PhoneController.text = data["contact3Phone"] ?? "";
      contact3RelationController.text = data["contact3Relation"] ?? "";

      setState(() {
        isContactsCompleted =
            (data["contact1Name"] ?? "").toString().isNotEmpty &&
            (data["contact1Phone"] ?? "").toString().isNotEmpty &&
            (data["contact1Relation"] ?? "").toString().isNotEmpty &&
            (data["contact2Name"] ?? "").toString().isNotEmpty &&
            (data["contact2Phone"] ?? "").toString().isNotEmpty &&
            (data["contact2Relation"] ?? "").toString().isNotEmpty &&
            (data["contact3Name"] ?? "").toString().isNotEmpty &&
            (data["contact3Phone"] ?? "").toString().isNotEmpty &&
            (data["contact3Relation"] ?? "").toString().isNotEmpty;
      });
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 158, 11, 87),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              const SizedBox(height: 10),
              const Text("Contact 1",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              buildTextField(
                controller: contact1NameController,
                label: "Name",
                icon: Icons.person,
              ),
              buildTextField(
                controller: contact1PhoneController,
                label: "Phone Number",
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              buildTextField(
                controller: contact1RelationController,
                label: "Relationship",
                icon: Icons.people,
              ),

              const SizedBox(height: 20),
              const Divider(),

              const Text("Contact 2",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              buildTextField(
                controller: contact2NameController,
                label: "Name",
                icon: Icons.person,
              ),
              buildTextField(
                controller: contact2PhoneController,
                label: "Phone Number",
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              buildTextField(
                controller: contact2RelationController,
                label: "Relationship",
                icon: Icons.people,
              ),

              const SizedBox(height: 20),
              const Divider(),

              const Text("Contact 3",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              buildTextField(
                controller: contact3NameController,
                label: "Name",
                icon: Icons.person,
              ),
              buildTextField(
                controller: contact3PhoneController,
                label: "Phone Number",
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              buildTextField(
                controller: contact3RelationController,
                label: "Relationship",
                icon: Icons.people,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: saveContacts,
                  child: Text(
                    isContactsCompleted
                        ? "Update Contacts"
                        : "Save Contacts",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    contact1NameController.dispose();
    contact1PhoneController.dispose();
    contact1RelationController.dispose();

    contact2NameController.dispose();
    contact2PhoneController.dispose();
    contact2RelationController.dispose();

    contact3NameController.dispose();
    contact3PhoneController.dispose();
    contact3RelationController.dispose();

    super.dispose();
  }
}
