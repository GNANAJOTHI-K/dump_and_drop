import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'splash_screen.dart';
import 'role_selection_screen.dart';
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
      home: const _Root(),
    );
  }
}
class _Root extends StatefulWidget {
  const _Root({Key? key}) : super(key: key);

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // show splash briefly on cold start, then go to role selection
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const SplashScreen();


    return const RoleSelectionScreen();
  }
}
