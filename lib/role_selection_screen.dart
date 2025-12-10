import 'package:flutter/material.dart';
import 'customer_signup_screen.dart';              // <-- relative import
import 'package:dump_and_drop/driver_signup_screen.dart';

const Color kPrimaryColor = Color(0xFF446FA8);

enum UserRole { driver, customer }

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              const Text(
                "Welcome to",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                "DUMP & DROP",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "THE TRAVELES",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: kPrimaryColor,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Please select your role to continue. "
                "You can always switch roles later from settings.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      role: UserRole.driver,
                      icon: Icons.local_shipping,
                      label: "Driver",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRoleCard(
                      role: UserRole.customer,
                      icon: Icons.person,
                      label: "Customer",
                    ),
                  ),
                ],
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedRole == null
                      ? null
                      : () {
                          if (_selectedRole == UserRole.driver) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DriverSignupScreen(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustomerAuthPage(), // class from file above
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    disabledBackgroundColor: Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? kPrimaryColor : Colors.grey.shade700,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? kPrimaryColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
