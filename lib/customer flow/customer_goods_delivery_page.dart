import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'map_picker_screen.dart';
import 'your_bookings_screen.dart';

const Color kPrimaryColor = Color(0xFF446FA8);

class CustomerGoodsDeliveryScreen extends StatefulWidget {
  const CustomerGoodsDeliveryScreen({super.key});

  @override
  State<CustomerGoodsDeliveryScreen> createState() =>
      _CustomerGoodsDeliveryScreenState();
}

class _CustomerGoodsDeliveryScreenState
    extends State<CustomerGoodsDeliveryScreen> {
  String pickupAddress = "";
  String dropAddress = "";
  DateTime? selectedDate;
  double packageWeight = 1.0;
  String packageCategory = "Documents";
  String vehicleType = "Bike";
  String specialInstructions = "";

  double? pickupLat;
  double? pickupLng;
  double? dropLat;
  double? dropLng;

  bool _isSaving = false;

  Future<void> _selectPickup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerScreen(isPickup: true),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        pickupAddress = result['label'] as String;
        pickupLat = result['lat'] as double;
        pickupLng = result['lng'] as double;
      });
    }
  }

  Future<void> _selectDrop() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerScreen(isPickup: false),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        dropAddress = result['label'] as String;
        dropLat = result['lat'] as double;
        dropLng = result['lng'] as double;
      });
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      initialDate: selectedDate ?? now,
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _changeWeight() async {
    double tempWeight = packageWeight;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select package weight"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${tempWeight.toStringAsFixed(1)} kg"),
              Slider(
                min: 0.5,
                max: 50.0,
                divisions: 99,
                value: tempWeight,
                onChanged: (v) {
                  setState(() {
                    tempWeight = v;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  packageWeight = tempWeight;
                });
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _selectCategory() async {
    final List<String> options = [
      "Documents",
      "Electronics",
      "Clothes",
      "Food",
      "Fragile",
      "Others",
    ];

    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return ListView(
          children: options
              .map(
                (e) => ListTile(
                  title: Text(e),
                  onTap: () => Navigator.pop(context, e),
                ),
              )
              .toList(),
        );
      },
    );

    if (result != null) {
      setState(() {
        packageCategory = result;
      });
    }
  }

  void _selectVehicle() async {
    final List<String> options = [
      "Bike",
      "Auto",
      "Mini Truck",
      "Truck",
    ];

    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return ListView(
          children: options
              .map(
                (e) => ListTile(
                  title: Text(e),
                  onTap: () => Navigator.pop(context, e),
                ),
              )
              .toList(),
        );
      },
    );

    if (result != null) {
      setState(() {
        vehicleType = result;
      });
    }
  }

  void _editInstructions() async {
    final controller = TextEditingController(text: specialInstructions);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Special instructions"),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "E.g., Handle with care, fragile item",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        specialInstructions = result;
      });
    }
  }

  Future<void> _bookGoodsDelivery() async {
    if (pickupAddress.isEmpty ||
        dropAddress.isEmpty ||
        pickupLat == null ||
        pickupLng == null ||
        dropLat == null ||
        dropLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select pickup and drop locations")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final bookingsRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .collection('bookings');

      await bookingsRef.add({
        'customerId': user.uid,
        'pickupLabel': pickupAddress,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropLabel': dropAddress,
        'dropLat': dropLat,
        'dropLng': dropLng,
        'service': 'goods',
        'status': 'pending',
        'pickupDate':
            selectedDate != null ? Timestamp.fromDate(selectedDate!) : null,
        'packageWeight': packageWeight,
        'packageCategory': packageCategory,
        'vehicleType': vehicleType,
        'specialInstructions': specialInstructions,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const YourBookingsScreen()),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save delivery: ${e.message}")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final double topHeight = size.height * 0.55;
    final double overlap = 90;
    final double cardTop = topHeight - overlap;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: topHeight,
              width: size.width,
              child: Image.asset(
                "assets/images/home_logo.jpg",
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            top: cardTop,
            child: GoodsDeliveryCard(
              selectedDate: selectedDate,
              pickupAddress: pickupAddress,
              dropAddress: dropAddress,
              packageWeight: packageWeight,
              packageCategory: packageCategory,
              vehicleType: vehicleType,
              specialInstructions: specialInstructions,
              onPickupTap: _selectPickup,
              onDropTap: _selectDrop,
              onDateTap: _selectDate,
              onWeightTap: _changeWeight,
              onCategoryTap: _selectCategory,
              onVehicleTap: _selectVehicle,
              onInstructionsTap: _editInstructions,
              onBookTap: _isSaving ? null : _bookGoodsDelivery,
              isSaving: _isSaving,
            ),
          ),
        ],
      ),
    );
  }
}

class GoodsDeliveryCard extends StatelessWidget {
  final DateTime? selectedDate;
  final String pickupAddress;
  final String dropAddress;
  final double packageWeight;
  final String packageCategory;
  final String vehicleType;
  final String specialInstructions;
  final VoidCallback? onPickupTap;
  final VoidCallback? onDropTap;
  final VoidCallback? onDateTap;
  final VoidCallback? onWeightTap;
  final VoidCallback? onCategoryTap;
  final VoidCallback? onVehicleTap;
  final VoidCallback? onInstructionsTap;
  final VoidCallback? onBookTap;
  final bool isSaving;

  const GoodsDeliveryCard({
    super.key,
    required this.selectedDate,
    required this.pickupAddress,
    required this.dropAddress,
    required this.packageWeight,
    required this.packageCategory,
    required this.vehicleType,
    required this.specialInstructions,
    required this.onPickupTap,
    required this.onDropTap,
    required this.onDateTap,
    required this.onWeightTap,
    required this.onCategoryTap,
    required this.onVehicleTap,
    required this.onInstructionsTap,
    required this.onBookTap,
    required this.isSaving,
  });

  String get dateLabel {
    if (selectedDate == null) return "Today";
    return "${selectedDate!.day.toString().padLeft(2, '0')}/"
        "${selectedDate!.month.toString().padLeft(2, '0')}/"
        "${selectedDate!.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputRow("Pickup address", pickupAddress, onPickupTap),
              _divider(),
              _inputRow("Drop address", dropAddress, onDropTap),
              _divider(),
              _dateRow(onDateTap),
              _divider(),
              _weightRow(onWeightTap),
              _divider(),
              _categoryRow(onCategoryTap),
              _divider(),
              _vehicleRow(onVehicleTap),
              _divider(),
              _specialInstructionsRow(onInstructionsTap),
              SizedBox(
                width: double.infinity,
                child: InkWell(
                  onTap: onBookTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: kPrimaryColor,
                    alignment: Alignment.center,
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Book Delivery",
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputRow(String title, String value, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF9AA5A9), width: 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value.isEmpty ? title : value,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6E7A7C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateRow(VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 22, color: Colors.grey),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Pickup date",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6E7A7C),
                ),
              ),
            ),
            Text(
              dateLabel,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F2F3F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weightRow(VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 22, color: Colors.grey),
            const SizedBox(width: 12),
            Text(
              "${packageWeight.toStringAsFixed(1)} kg",
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2F4F4F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryRow(VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.category_outlined,
                size: 22, color: Colors.grey),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Package category",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6E7A7C),
                ),
              ),
            ),
            Text(
              packageCategory,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2F4F4F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleRow(VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.local_shipping_outlined,
                size: 22, color: Colors.grey),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Vehicle type",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6E7A7C),
                ),
              ),
            ),
            Text(
              vehicleType,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2F4F4F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specialInstructionsRow(VoidCallback? onTap) {
    final String shownText =
        specialInstructions.isEmpty ? "Add instructions" : specialInstructions;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.notes_outlined, size: 22, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                shownText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight:
                      specialInstructions.isEmpty ? FontWeight.w600 : FontWeight.w700,
                  color: specialInstructions.isEmpty
                      ? const Color(0xFF6E7A7C)
                      : const Color(0xFF2F4F4F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFEDEDED),
    );
  }
}
