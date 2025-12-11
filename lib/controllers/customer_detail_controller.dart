import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../customer flow/home_intro_page.dart';

class CustomerDetailController extends GetxController {
  final isLoading = false.obs;
  final basicSaved = false.obs;

  Future<Map<String, String>> loadExistingData(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('customers').doc(uid).get();
    if (doc.exists) {
      final data = doc.data() ?? {};
      return {
        'name': (data['name'] ?? '') as String,
        'dob': (data['dob'] ?? '') as String,
        'mobile': (data['mobile'] ?? '') as String,
        'email': (data['email'] ?? '') as String,
      };
    }
    return {'name': '', 'dob': '', 'mobile': '', 'email': ''};
  }

  Future<void> saveBasicInfo(String uid, Map<String, String> values, BuildContext context) async {
    isLoading.value = true;
    try {
      await FirebaseFirestore.instance.collection('customers').doc(uid).set({
        'name': values['name'],
        'dob': values['dob'],
        'mobile': values['mobile'],
        'email': values['email'],
        'role': 'customer',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      basicSaved.value = true;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Basic details saved. Now set password.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving details: $e')),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> savePasswordAndFinish({
    required String uid,
    required String email,
    required String password,
    required Map<String, String> profileValues,
    required BuildContext context,
  }) async {
    if (!basicSaved.value) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please save basic details first')),
        );
      }
      return;
    }

    isLoading.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != uid) {
        throw Exception('User not authenticated correctly');
      }

      final cred = EmailAuthProvider.credential(email: email.trim(), password: password.trim());
      await user.linkWithCredential(cred);

      await FirebaseFirestore.instance.collection('customers').doc(uid).set({
        'email': email.trim(),
        'name': profileValues['name'],
        'dob': profileValues['dob'],
        'mobile': profileValues['mobile'],
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeIntroPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Auth error: ${e.code}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving password: $e')),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
