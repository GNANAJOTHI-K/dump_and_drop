import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:dump_and_drop/role_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  String photoUrl = "";
  File? pickedImage;

  final blue = const Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final snap = await FirebaseFirestore.instance
        .collection('customers')
        .doc(user!.uid)
        .get();

    final data = snap.data();
    if (data != null) {
      nameCtrl.text = data['name'] ?? "";
      phoneCtrl.text = data['phone'] ?? "";
      addressCtrl.text = data['address'] ?? "";
      setState(() => photoUrl = data['photoUrl'] ?? "");
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => pickedImage = File(picked.path));
    }
  }

  Future<void> saveProfile() async {
    String uploadedUrl = photoUrl;

    if (pickedImage != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user!.uid}.jpg');

      await ref.putFile(pickedImage!);
      uploadedUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance
        .collection('customers')
        .doc(user!.uid)
        .set({
      'name': nameCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'address': addressCtrl.text.trim(),
      'photoUrl': uploadedUrl,
      'email': user!.email,
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Profile Updated")));
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("Not Logged In"));
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ✅ BIG PROFILE HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              decoration: BoxDecoration(
                color: blue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      backgroundImage: pickedImage != null
                          ? FileImage(pickedImage!)
                          : (photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null) as ImageProvider?,
                      child: pickedImage == null && photoUrl.isEmpty
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nameCtrl.text.isNotEmpty
                        ? nameCtrl.text
                        : "Complete Your Profile",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(user!.email ?? "",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ✅ EDIT PROFILE CARD
            profileCard(
              title: "Personal Details",
              child: Column(
                children: [
                  field("Full Name", nameCtrl),
                  field("Phone Number", phoneCtrl),
                  field("Address", addressCtrl),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: blue),
                      onPressed: saveProfile,
                      child: const Text("Save"),
                    ),
                  )
                ],
              ),
            ),

            // ✅ PAYMENT METHODS
            profileCard(
              title: "Payment Methods",
              child: const ListTile(
                leading: Icon(Icons.payment),
                title: Text("Add Bank / UPI"),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),

            // ✅ REFUNDS
            profileCard(
              title: "Refunds",
              child: const ListTile(
                leading: Icon(Icons.refresh),
                title: Text("View Refund History"),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),

            // ✅ RATINGS
            profileCard(
              title: "Ratings",
              child: const ListTile(
                leading: Icon(Icons.star),
                title: Text("Your Ratings"),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),

            const SizedBox(height: 10),

            // ✅ LOGOUT BUTTON
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Logout",
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ COMPONENTS
  Widget profileCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          child
        ],
      ),
    );
  }

  Widget field(String hint, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
