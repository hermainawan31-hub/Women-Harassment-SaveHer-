import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_colors.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final TextEditingController contact1NameController = TextEditingController();
  final TextEditingController contact1PhoneController = TextEditingController();
  final TextEditingController contact1RelationController =
      TextEditingController();

  final TextEditingController contact2NameController = TextEditingController();
  final TextEditingController contact2PhoneController = TextEditingController();
  final TextEditingController contact2RelationController =
      TextEditingController();

  final TextEditingController contact3NameController = TextEditingController();
  final TextEditingController contact3PhoneController = TextEditingController();
  final TextEditingController contact3RelationController =
      TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Emergency Contacts Saved")));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> loadContacts() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection("users").doc(user.uid).get();

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
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textDark),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textDark.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 21),
          filled: true,
          fillColor: const Color(0xFFF4F1FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
          ),
        ),
      ),
    );
  }

  // ---------------- CONTACT GROUP CARD ----------------
  Widget _contactCard({
    required int number,
    required TextEditingController nameController,
    required TextEditingController phoneController,
    required TextEditingController relationController,
    required bool complete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  "$number",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Contact $number",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              if (complete)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7F8ED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF2CB25A),
                    size: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          buildTextField(
            controller: nameController,
            label: "Name",
            icon: Icons.person,
          ),
          buildTextField(
            controller: phoneController,
            label: "Phone Number",
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          buildTextField(
            controller: relationController,
            label: "Relationship",
            icon: Icons.people,
          ),
        ],
      ),
    );
  }

  bool get _c1Complete =>
      contact1NameController.text.isNotEmpty &&
      contact1PhoneController.text.isNotEmpty &&
      contact1RelationController.text.isNotEmpty;

  bool get _c2Complete =>
      contact2NameController.text.isNotEmpty &&
      contact2PhoneController.text.isNotEmpty &&
      contact2RelationController.text.isNotEmpty;

  bool get _c3Complete =>
      contact3NameController.text.isNotEmpty &&
      contact3PhoneController.text.isNotEmpty &&
      contact3RelationController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Emergency Contacts",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ---- Gradient intro header ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 90, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.contact_emergency_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            "Add up to 3 people we can alert instantly in an emergency.",
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _contactCard(
                      number: 1,
                      nameController: contact1NameController,
                      phoneController: contact1PhoneController,
                      relationController: contact1RelationController,
                      complete: _c1Complete,
                    ),
                    _contactCard(
                      number: 2,
                      nameController: contact2NameController,
                      phoneController: contact2PhoneController,
                      relationController: contact2RelationController,
                      complete: _c2Complete,
                    ),
                    _contactCard(
                      number: 3,
                      nameController: contact3NameController,
                      phoneController: contact3PhoneController,
                      relationController: contact3RelationController,
                      complete: _c3Complete,
                    ),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: saveContacts,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.save,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isContactsCompleted
                                    ? "Update Contacts"
                                    : "Save Contacts",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
