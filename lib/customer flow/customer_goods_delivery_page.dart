import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'map_picker_screen.dart';
import 'your_bookings_screen.dart';
import '../controllers/goods_delivery_controller.dart';

const Color kPrimaryColor = Color(0xFF446FA8);

class CustomerGoodsDeliveryScreen extends StatefulWidget {
  const CustomerGoodsDeliveryScreen({super.key});

  @override
  State<CustomerGoodsDeliveryScreen> createState() =>
      _CustomerGoodsDeliveryScreenState();
}

class _CustomerGoodsDeliveryScreenState
    extends State<CustomerGoodsDeliveryScreen> {
  final GoodsDeliveryController _ctrl = Get.put(GoodsDeliveryController());

  Future<void> _selectPickup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerScreen(isPickup: true),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      _ctrl.setPickup(result);
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
      _ctrl.setDrop(result);
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      initialDate: _ctrl.selectedDate.value ?? now,
    );
    if (picked != null) {
      _ctrl.setDate(picked);
    }
  }

  void _changeWeight() async {
    double tempWeight = _ctrl.packageWeight.value;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
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
                  _ctrl.setWeight(tempWeight);
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          );
        });
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
      _ctrl.setCategory(result);
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
      _ctrl.setVehicle(result);
    }
  }

  void _editInstructions() async {
    final controller = TextEditingController(text: _ctrl.specialInstructions.value);
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
      _ctrl.setInstructions(result);
    }
  }

  Future<void> _bookGoodsDelivery() async {
    try {
      await _ctrl.bookDelivery(() async {
        if (!mounted) return;
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const YourBookingsScreen()),
        );
      });
    } catch (e) {
      final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
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
            child: Obx(() {
              return GoodsDeliveryCard(
                selectedDate: _ctrl.selectedDate.value,
                pickupAddress: _ctrl.pickupAddress.value,
                dropAddress: _ctrl.dropAddress.value,
                packageWeight: _ctrl.packageWeight.value,
                packageCategory: _ctrl.packageCategory.value,
                vehicleType: _ctrl.vehicleType.value,
                specialInstructions: _ctrl.specialInstructions.value,
                onPickupTap: _selectPickup,
                onDropTap: _selectDrop,
                onDateTap: _selectDate,
                onWeightTap: _changeWeight,
                onCategoryTap: _selectCategory,
                onVehicleTap: _selectVehicle,
                onInstructionsTap: _editInstructions,
                onBookTap: _ctrl.isSaving.value ? null : _bookGoodsDelivery,
                isSaving: _ctrl.isSaving.value,
              );
            }),
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
