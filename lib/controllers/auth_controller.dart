import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../customer_login_page.dart';
import '../customer_detail_page.dart';
import '../customer flow/home_intro_page.dart';

class AuthController extends GetxController {
  final isLoading = false.obs;

  Future<void> continueWithGoogle(BuildContext context) async {
    isLoading.value = true;

    try {
      final googleSignIn = GoogleSignIn();

      // Always show account chooser
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // user cancelled
        isLoading.value = false;
        return;
      }

      final String email = googleUser.email;

      // STEP 1: Check if this email already has an Auth account
      final methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

      if (methods.isNotEmpty) {
        // This email already registered in Firebase Auth
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This email already exists. Please login.'),
          ),
        );

        // Optional: sign out Google so chooser appears again next time
        await googleSignIn.signOut();

        // Go to login page
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CustomerLoginPage()),
          );
        }

        isLoading.value = false;
        return;
      }

      // STEP 2: Safe to create new Google Auth account (brand new email)
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User user = userCred.user!;
      final bool isNew = userCred.additionalUserInfo?.isNewUser ?? true;
      debugPrint('Google sign-up success, uid=${user.uid}, isNew=$isNew');

      // STEP 3: Create Firestore customer doc now (Auth is valid)
      await _ensureCustomerDoc(user);

      // STEP 4: Go to DETAILS PAGE (not home!)
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerDetailPage(
              userUid: user.uid,
              userEmail: user.email ?? '',
              isNewUser: true,
            ),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException on Google sign-in: ${e.code} - ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Google sign-in failed')),
        );
      }
    } catch (e) {
      debugPrint('Unknown error during Google sign-in: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in failed')),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _ensureCustomerDoc(User user) async {
    final ref = FirebaseFirestore.instance.collection('customers').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'email': user.email,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> loginWithEmail(
      BuildContext context, String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password')),
      );
      return;
    }

    isLoading.value = true;
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = cred.user!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(uid)
          .get();

      if (!doc.exists || doc.data()?['role'] != 'customer') {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('This email is not registered as a customer account'),
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeIntroPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed';
      if (e.code == 'user-not-found') msg = 'User not found';
      if (e.code == 'wrong-password') msg = 'Wrong password';
      if (e.message != null) msg = e.message!;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    isLoading.value = true;

    try {
      final googleSignIn = GoogleSignIn();

      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        isLoading.value = false;
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User user = userCred.user!;
      final String uid = user.uid;

      final customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(uid)
          .get();

      if (!customerDoc.exists || customerDoc.data()?['role'] != 'customer') {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No customer account found for this Google login. Please sign up first.',
              ),
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomerLoginPage()),
          );
        }

        isLoading.value = false;
        return;
      }

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
          SnackBar(content: Text(e.message ?? 'Google login failed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in failed')),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
