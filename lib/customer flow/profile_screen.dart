import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dump_and_drop/role_selection_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Not logged in'),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final name = (data['name'] ?? '') as String;
        final photoUrl = (data['photoUrl'] ?? '') as String;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFE0E0E0),
                backgroundImage:
                    photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 40, color: Colors.black54)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                name.isNotEmpty ? name : 'Customer',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // You can add more profile items here later
              const ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
              ),
              const ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('Help & Support'),
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _logout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
