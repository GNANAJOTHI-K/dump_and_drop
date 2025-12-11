import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'customer_signup_screen.dart';
import 'package:dump_and_drop/driver_signup_screen.dart';
import 'controllers/role_selection_controller.dart';

const Color kPrimaryColor = Color(0xFF446FA8);

enum UserRole { driver, customer }

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RoleSelectionController _ctrl = Get.put(RoleSelectionController());

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
                    child: Obx(() => _buildRoleCard(
                          ctrl: _ctrl,
                          role: UserRole.driver,
                          icon: Icons.local_shipping,
                          label: "Driver",
                        )),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => _buildRoleCard(
                          ctrl: _ctrl,
                          role: UserRole.customer,
                          icon: Icons.person,
                          label: "Customer",
                        )),
                  ),
                ],
              ),

              const Spacer(),

              Obx(() {
                final sel = _ctrl.selectedRole.value;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: sel == null
                        ? null
                        : () {
                            if (sel == UserRole.driver) {
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
                                  builder: (context) => CustomerAuthPage(),
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
                );
              }),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// --------------------------------------------------
  /// 🔥 UPDATED ROLE CARD — Bigger Size + Bigger Icons
  /// --------------------------------------------------
  Widget _buildRoleCard({
    required RoleSelectionController ctrl,
    required UserRole role,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = ctrl.selectedRole.value == role;

    return GestureDetector(
      onTap: () {
        ctrl.select(role);
      },
      child: Container(
        height: 240, // 🔥 Increased height
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 100, // 🔥 Bigger icon
              color: isSelected ? kPrimaryColor : Colors.grey.shade700,
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 20, // 🔥 Bigger label text
                fontWeight: FontWeight.w700,
                color: isSelected ? kPrimaryColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
