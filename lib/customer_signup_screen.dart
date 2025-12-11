// lib/customer_signup_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'customer_login_page.dart';
import 'controllers/auth_controller.dart';

const Color kPrimaryColor = Color(0xFF446FA8);
const Color kFieldBg = Color(0xFFF5F7FB);

class CustomerAuthPage extends StatefulWidget {
  const CustomerAuthPage({super.key});

  @override
  State<CustomerAuthPage> createState() => _CustomerAuthPageState();
}

class _CustomerAuthPageState extends State<CustomerAuthPage> {
  final AuthController _auth = Get.put(AuthController());

  // ---------------- GOOGLE SIGNUP FLOW ----------------
  Future<void> _continueWithGoogle() async {
    await _auth.continueWithGoogle(context);
  }

  // Create Firestore customer doc if not exists
  // Firestore doc creation moved to `AuthController`.

  void _continueWithFacebookDummy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Facebook login coming soon')),
    );
  }

  void _openLoginPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomerLoginPage()),
    );
  }

  void _onBackPressed() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top image with back button
              Container(
                height: h * 0.45,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/signup.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _onBackPressed,
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom content
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome 👋',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sign up to book rides and goods vehicles easily.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Sign up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Continue with Google
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Obx(() {
                        final loading = _auth.isLoading.value;
                        return OutlinedButton(
                          onPressed: loading ? null : _continueWithGoogle,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.g_mobiledata, size: 28),
                              const SizedBox(width: 6),
                              Text(
                                loading ? 'Please wait...' : 'Continue with Google',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),

                    // Facebook (dummy)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Obx(() {
                        final loading = _auth.isLoading.value;
                        return ElevatedButton(
                          onPressed: loading ? null : _continueWithFacebookDummy,
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
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.facebook, size: 22),
                              SizedBox(width: 8),
                              Text('Continue with Facebook'),
                            ],
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: Obx(() {
                        final loading = _auth.isLoading.value;
                        return OutlinedButton(
                          onPressed: loading ? null : _openLoginPage,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Already have an account? Login',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kPrimaryColor,
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
