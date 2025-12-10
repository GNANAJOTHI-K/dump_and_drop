// lib/customer_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'customer flow/home_intro_page.dart';

const Color kPrimaryColor = Color(0xFF446FA8);
const Color kFieldBg = Color(0xFFF5F7FB);

class CustomerDetailPage extends StatefulWidget {
  final String userUid;
  final String userEmail;
  final bool isNewUser;

  const CustomerDetailPage({
    super.key,
    required this.userUid,
    required this.userEmail,
    required this.isNewUser,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final _basicFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _basicSaved = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.userEmail;
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final doc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.userUid)
        .get();

    if (doc.exists) {
      final data = doc.data() ?? {};
      _nameController.text = (data['name'] ?? '') as String;
      _dobController.text = (data['dob'] ?? '') as String;
      _mobileController.text = (data['mobile'] ?? '') as String;
      _emailController.text = (data['email'] ?? widget.userEmail) as String;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveBasicInfo() async {
    if (!_basicFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.userUid)
          .set({
        'name': _nameController.text.trim(),
        'dob': _dobController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'customer',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _basicSaved = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Basic details saved. Now set password.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving details: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePasswordAndFinish() async {
    if (!_basicSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please save basic details first')),
      );
      return;
    }

    if (!_passwordFormKey.currentState!.validate()) return;
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || user.uid != widget.userUid) {
        throw Exception('User not authenticated correctly');
      }

      // Link email+password with this Google user
      final cred = EmailAuthProvider.credential(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await user.linkWithCredential(cred); // link providers [web:28][web:32]

      // Only profile data in Firestore, no password
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.userUid)
          .set({
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'dob': _dobController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // save extra fields [web:1][web:20]

      if (!mounted) return;

      // Go to HomeIntroPage and clear previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeIntroPage()),
        (route) => false,
      ); // clean navigation stack after signup [web:21][web:31]
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Auth error: ${e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving password: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // SECTION 1: Basic details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _basicFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          filled: true,
                          fillColor: kFieldBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _dobController,
                        decoration: const InputDecoration(
                          labelText: 'Date of birth (DD/MM/YYYY)',
                          filled: true,
                          fillColor: kFieldBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile number',
                          filled: true,
                          fillColor: kFieldBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.trim().length < 10
                                ? 'Enter valid mobile number'
                                : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          filled: true,
                          fillColor: kFieldBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveBasicInfo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Save & continue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // SECTION 2: Password
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          filled: true,
                          fillColor: kFieldBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.trim().length < 6
                                ? 'Min 6 characters'
                                : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          filled: true,
                          fillColor: kFieldBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.trim().length < 6
                                ? 'Min 6 characters'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _savePasswordAndFinish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: h * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
