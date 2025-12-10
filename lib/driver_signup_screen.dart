import 'package:flutter/material.dart';
import 'driver flow/choose_things_page.dart';

const Color kPrimaryColor = Color(0xFF446FA8);
const Color kFieldBg = Color(0xFFF5F7FB);

class DriverSignupScreen extends StatefulWidget {
  const DriverSignupScreen({super.key});

  @override
  State<DriverSignupScreen> createState() => _DriverSignupScreenState();
}

class _DriverSignupScreenState extends State<DriverSignupScreen> {
  void _onGoogleSignup() {
    // TODO: Google sign-in
    debugPrint("Google signup tapped");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ChooseThingsPage(),
      ),
    );
  }

  void _onFacebookSignup() {
    // TODO: Facebook sign-in
    debugPrint("Facebook signup tapped");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ChooseThingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Create your driver account",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome driver 👋",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Sign up quickly to receive trip and delivery requests.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // Google button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _onGoogleSignup,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.g_mobiledata, size: 28),
                      SizedBox(width: 6),
                      Text(
                        "Sign up with Google",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Facebook button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _onFacebookSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.facebook, size: 22),
                      SizedBox(width: 8),
                      Text("Sign up with Facebook"),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Privacy / terms text
              Center(
                child: Text(
                  "By continuing, you agree to our Terms of Service\nand acknowledge the Privacy Policy.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
