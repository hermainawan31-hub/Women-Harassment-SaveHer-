import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // add controller for form:
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController=TextEditingController();
  final TextEditingController addressController=TextEditingController();
  final TextEditingController notesController=TextEditingController();

  // firebase authentcation for saving data and updateing screens:
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // now for dropdown :
  String? selectedBloodGroup;
  String? selectedGender;
  String? photoUrl;   // <-- add this
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
    selectedGender == null) 
    
    {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("please fill all fields!")));
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
  const SnackBar(
    content: Text("Profile saved successfully"),
  ),
);
      Navigator.pop(context);
      }
      catch(e){
        ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
      content: Text(e.toString()),
              ),
            );
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
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                );

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
        await http.MultipartFile.fromPath(
        "file",
        _selectedImage!.path,
                ),
              );
              final response = await request.send();

              if (response.statusCode == 200) {
                final responseData =
                    await response.stream.bytesToString();

                    final data = jsonDecode(responseData);

                    return data["secure_url"];

              } 
              else {
                return null;
              }
}
// now we have init function:
        @override
        void initState() {
          super.initState();

          loadProfile();
        }

  final List<String> BloodGroup=[
      "A+",
      "A-",
      "B+",
      "B-",
      "AB+",
      "AB-",
      "O+",
      "O-",
];
final List<String> Gender=[
  "Male",
  "Female",
  "Other",
];
  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(" Profile"),
        backgroundColor: const Color.fromARGB(255, 158, 11, 87),
        foregroundColor: Colors.white,
        ),


//  now  i will make profile page first:
        body: SafeArea(
          child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [

// profile photo avatar and event to put profile photo:
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
  radius: 60,
  backgroundColor: Colors.grey.shade300,

  backgroundImage: _selectedImage != null
      ? FileImage(_selectedImage!)
      : (photoUrl != null
          ? NetworkImage(photoUrl!)
          : null) as ImageProvider?,

  child: (_selectedImage == null && photoUrl == null)
      ? const Icon(
          Icons.person,
          size: 60,
          color: Colors.white,
        )
      : null,
),
// positioned where to add next in that parent:
                      Positioned(
                          bottom: 0,
                          right: 0,

                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFD81B60),

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
                    const SizedBox(height: 15),

// now we will add tex fields here :it is name text field:
// name text field
                TextField(          
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    hintText: "Enter your full name",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    )
                  ),
                ),
           
            const SizedBox(height: 18),
// phone text field;
             TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Phone Number",
                hintText: "03XXXXXXXXX",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                )
              ),
             ),
             const SizedBox(height: 18),
//  address textfield
             TextField(
                   controller: addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                  labelText: "Address",
                  hintText: "Enter your complete address",
                  prefixIcon: 
                  Icon(Icons.home),
                
                  border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
                const SizedBox(height: 18),
// Now drop down for blood group :
            const SizedBox(height: 18),

              DropdownButtonFormField<String>(
              initialValue: selectedBloodGroup,
              decoration: InputDecoration(
              labelText: "Blood Group",
              prefixIcon: const Icon(Icons.bloodtype),
              border: OutlineInputBorder(
               borderRadius: BorderRadius.circular(12),
                ),
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
// Now dropdown for gneder:
                  DropdownButtonFormField<String>(
                  initialValue: selectedGender,
                  decoration: InputDecoration(
                  labelText: "Gender",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                      ),
                  ),

                  items:  Gender.map((gender) {
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
// now add texfield for notes:
                    TextField(
                      controller: notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "Emergency Notes",
                        hintText: "Medical conditions, allergies, or anything responders should know.",
                        prefixIcon: Icon(Icons.medical_information),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        )
                      ),
                    ),
                    const SizedBox(height: 18),
// now we will add button here :
                      Container(
                        width: double.infinity,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD81B60), Color(0xFF8E24AA)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.shade300,
                                  blurRadius: 12,
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
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child:  Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, color: Colors.white, size: 24),
                                  SizedBox(width: 10),
                                  Text(
                                    isProfileCompleted ? "Update Profile" : "Save Profile",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                   ],
            
                ),
              )
            
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
