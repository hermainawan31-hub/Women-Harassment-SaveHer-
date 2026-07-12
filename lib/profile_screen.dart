import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // add controller for form:
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // firebase authentcation for saving data and updateing screens:
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // now for dropdown :
  String? selectedBloodGroup;
  String? selectedGender;
  String? photoUrl; // <-- add this
  // for profile :
  bool isProfileCompleted = false;
  // for updating profile image:
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  // save profile function:
  Future<void> saveProfile() async {
    try {
      if (nameController.text.trim().isEmpty ||
          phoneController.text.trim().isEmpty ||
          addressController.text.trim().isEmpty ||
          selectedBloodGroup == null ||
          selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("please fill all fields!")),
        );
        return;
      }
      final user = _auth.currentUser;
      if (user == null) return;
      final photoUrl = await uploadImageToCloudinary();
      await _firestore.collection("users").doc(user.uid).set({
        "fullName": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "address": addressController.text.trim(),
        "bloodGroup": selectedBloodGroup,
        "gender": selectedGender,
        "notes": notesController.text.trim(),
        "photoUrl": photoUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile saved successfully")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // now load from doc :
  Future<void> loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final document = await _firestore.collection("users").doc(user.uid).get();

    if (document.exists) {
      final data = document.data();
      nameController.text = data?["fullName"] ?? "";
      phoneController.text = data?["phone"] ?? "";
      addressController.text = data?["address"] ?? "";
      setState(() {
        isProfileCompleted = true;
        selectedBloodGroup = data?["bloodGroup"];
        selectedGender = data?["gender"];

        photoUrl = data?["photoUrl"];
      });

      notesController.text = data?["notes"] ?? "";
      photoUrl = data?["photoUrl"];
    }
  }

  // image picker function for uploading profile image :
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      _selectedImage = File(image.path);
    });
  }

  //  fro uploading image :
  Future<String?> uploadImageToCloudinary() async {
    if (_selectedImage == null) {
      return null;
    }

    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/mpieu48v/image/upload",
    );
    final request = http.MultipartRequest("POST", uri);

    request.fields["upload_preset"] = "safeher_profile";
    request.files.add(
      await http.MultipartFile.fromPath("file", _selectedImage!.path),
    );
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();

      final data = jsonDecode(responseData);

      return data["secure_url"];
    } else {
      return null;
    }
  }

  // now we have init function:
  @override
  void initState() {
    super.initState();

    loadProfile();
  }

  final List<String> BloodGroup = [
    "A+",
    "A-",
    "B+",
    "B-",
    "AB+",
    "AB-",
    "O+",
    "O-",
  ];
  final List<String> Gender = ["Male", "Female", "Other"];

  // ---------------- SHARED THEMED FIELD ----------------
  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: AppColors.textDark.withOpacity(0.6)),
      hintStyle: TextStyle(color: AppColors.textDark.withOpacity(0.35)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Profile",
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

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ---- Gradient header holding the avatar ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 90, 20, 32),
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
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (photoUrl != null
                                        ? NetworkImage(photoUrl!)
                                        : null)
                                    as ImageProvider?,
                          child: (_selectedImage == null && photoUrl == null)
                              ? const Icon(
                                  Icons.person,
                                  size: 55,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.accent,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              pickImage();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---- Form card ----
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
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
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: AppColors.textDark),
                        cursorColor: AppColors.primary,
                        decoration: _fieldDecoration(
                          label: "Full Name",
                          hint: "Enter your full name",
                          icon: Icons.person,
                        ),
                      ),
                      const SizedBox(height: 18),

                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: AppColors.textDark),
                        cursorColor: AppColors.primary,
                        decoration: _fieldDecoration(
                          label: "Phone Number",
                          hint: "03XXXXXXXXX",
                          icon: Icons.phone,
                        ),
                      ),
                      const SizedBox(height: 18),

                      TextField(
                        controller: addressController,
                        maxLines: 2,
                        style: const TextStyle(color: AppColors.textDark),
                        cursorColor: AppColors.primary,
                        decoration: _fieldDecoration(
                          label: "Address",
                          hint: "Enter your complete address",
                          icon: Icons.home,
                        ),
                      ),
                      const SizedBox(height: 18),

                      DropdownButtonFormField<String>(
                        initialValue: selectedBloodGroup,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                        ),
                        decoration: _fieldDecoration(
                          label: "Blood Group",
                          hint: "",
                          icon: Icons.bloodtype,
                        ),
                        items: BloodGroup.map((group) {
                          return DropdownMenuItem(
                            value: group,
                            child: Text(group),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedBloodGroup = value;
                          });
                        },
                      ),
                      const SizedBox(height: 18),

                      DropdownButtonFormField<String>(
                        initialValue: selectedGender,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                        ),
                        decoration: _fieldDecoration(
                          label: "Gender",
                          hint: "",
                          icon: Icons.person_outline,
                        ),
                        items: Gender.map((gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value;
                          });
                        },
                      ),
                      const SizedBox(height: 18),

                      TextField(
                        controller: notesController,
                        maxLines: 4,
                        style: const TextStyle(color: AppColors.textDark),
                        cursorColor: AppColors.primary,
                        decoration: _fieldDecoration(
                          label: "Emergency Notes",
                          hint:
                              "Medical conditions, allergies, or anything responders should know.",
                          icon: Icons.medical_information,
                        ),
                      ),
                      const SizedBox(height: 24),

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
                            onPressed: () {
                              saveProfile();
                            },
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
                                  isProfileCompleted
                                      ? "Update Profile"
                                      : "Save Profile",
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
