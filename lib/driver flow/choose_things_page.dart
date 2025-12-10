import 'package:flutter/material.dart';
import 'passenger_vehicle_details_page.dart';
import 'goods_vehicle_details_page.dart';

const Color kPrimaryColor = Color(0xFF446FA8);

enum DriverCategory { passenger, goods }

class ChooseThingsPage extends StatefulWidget {
  const ChooseThingsPage({super.key});

  @override
  State<ChooseThingsPage> createState() => _ChooseThingsPageState();
}

class _ChooseThingsPageState extends State<ChooseThingsPage> {
  DriverCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Driver Flow",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              const Text(
                "What type of vehicle do you drive?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Choose whether you want to accept rides for passengers or transport goods using your vehicle.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // Two options – Passenger vs Goods
              Row(
                children: [
                  Expanded(
                    child: _buildCategoryCard(
                      category: DriverCategory.passenger,
                      icon: Icons.directions_car_filled,
                      title: "Passenger Vehicle",
                      subtitle: "Car, van or SUV\nfor people travel.",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCategoryCard(
                      category: DriverCategory.goods,
                      icon: Icons.local_shipping_rounded,
                      title: "Goods Vehicle",
                      subtitle: "Pickup, mini-truck\nfor goods delivery.",
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedCategory == null
                          ? null
                          : () {
                              if (_selectedCategory == DriverCategory.passenger) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PassengerVehicleDetailsPage(),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const GoodsVehicleDetailsPage(),
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
                  child: Text(
                    "Continue",
                    style: TextStyle(
                      color: _selectedCategory == null
                          ? Colors.white70
                          : Colors.white,
                    ),
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

  Widget _buildCategoryCard({
    required DriverCategory category,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool isSelected = _selectedCategory == category;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withOpacity(0.08) : Colors.white,
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
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? kPrimaryColor : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
