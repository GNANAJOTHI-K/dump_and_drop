// lib/driver_status_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'driver_home_intro_page.dart'; // your driver flow page

const Color kPrimaryColor = Color(0xFF446FA8);

class DriverStatusPage extends StatefulWidget {
  const DriverStatusPage({super.key});

  @override
  State<DriverStatusPage> createState() => _DriverStatusPageState();
}

class _DriverStatusPageState extends State<DriverStatusPage> {
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
      appBar: AppBar(
        title: const Text('Driver Status'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance.collection('drivers').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          // Error handling (including permission issues)
          if (snapshot.hasError) {
            final err = snapshot.error;
            String msg = 'Error loading status';
            if (err is FirebaseException) {
              msg = '${err.code}: ${err.message}';
            } else {
              msg = err.toString();
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(msg, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data;
          if (doc == null || !doc.exists) {
            // driver doc missing — show helpful message & sign-out option
            return _missingDriverDocUI();
          }

          final data = doc.data()!;
          final status = (data['status'] ?? 'pending').toString();

          // If approved — navigate to driver home (do it once)
          if (status == 'approved') {
            // avoid calling Navigator during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => DriverHomeIntroPage()),
                );
              }
            });

            // show a quick transitional UI while navigation completes
            return const Center(child: CircularProgressIndicator());
          }

          // else show waiting UI (you had this already)
          return _waitingForApprovalUI();
        },
      ),
    );
  }

  Widget _missingDriverDocUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off, size: 72, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              "Driver profile not found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "We couldn't find your driver profile in the database. If you just signed up, wait a few seconds and press Retry. If the problem continues contact support.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
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
            const Icon(Icons.hourglass_top, size: 80, color: kPrimaryColor),
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
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Refresh'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
