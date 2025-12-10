import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'splash_screen.dart';
import 'customer_signup_screen.dart';   // contains CustomerAuthPage
import 'customer flow/home_intro_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dump & Drop',
      theme: ThemeData(
        fontFamily: 'Nunito',
      ),
      home: const _Root(), // use auth gate instead of direct SplashScreen
    );
  }
}

class _Root extends StatelessWidget {
  const _Root({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // listens to login/logout
      builder: (context, snapshot) {
        // still connecting → show splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // user is logged in → go to home; will stay here until signOut()
        if (snapshot.data != null) {
          return const HomeIntroPage();
        }

        // no user → show your auth/signup page
        return const CustomerAuthPage();
      },
    );
  }
}
