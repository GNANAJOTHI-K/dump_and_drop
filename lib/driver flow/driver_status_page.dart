import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'driver_home_intro_page.dart'; // your driver flow page

const Color kPrimaryColor = Color(0xFF446FA8);

class DriverStatusPage extends StatelessWidget {
  const DriverStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          final status = data?['status'] ?? 'pending';

          /// ✅ IF APPROVED → GO TO DRIVER FLOW
          if (status == "approved") {
            return const DriverHomeIntroPage(); // your real driver home
          }

          /// ⏳ ELSE → SHOW WAITING SCREEN
          return _waitingForApprovalUI();
        },
      ),
    );
  }

  Widget _waitingForApprovalUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top,
                size: 80, color: kPrimaryColor),
            const SizedBox(height: 20),
            const Text(
              "Verification in progress",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your documents are under review.\nYou will automatically enter the app once approved.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
