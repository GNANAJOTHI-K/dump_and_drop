import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'map_picker_screen.dart';
import 'your_bookings_screen.dart';
import '../controllers/ride_booking_controller.dart';

const Color kPrimaryColor = Color(0xFF446FA8);

class CustomerRideBookingScreen extends StatefulWidget {
  const CustomerRideBookingScreen({super.key});

  @override
  State<CustomerRideBookingScreen> createState() =>
      _CustomerRideBookingScreenState();
}

class _CustomerRideBookingScreenState extends State<CustomerRideBookingScreen> {
  final RideBookingController _ctrl = Get.put(RideBookingController());

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

  void _incrementPassengers() {
    _ctrl.incrementPassengers();
  }

  void _decrementPassengers() {
    _ctrl.decrementPassengers();
  }

  Future<void> _bookRide() async {
    try {
      await _ctrl.bookRide(() async {
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
                "assets/images/car.png",
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
              return RideSearchCard(
                selectedDate: _ctrl.selectedDate.value,
                leavingFrom: _ctrl.leavingFrom.value,
                goingTo: _ctrl.goingTo.value,
                passengers: _ctrl.passengers.value,
                onPickupTap: _selectPickup,
                onDropTap: _selectDrop,
                onDateTap: _selectDate,
                onIncrementPassengers: _incrementPassengers,
                onDecrementPassengers: _decrementPassengers,
                onBookTap: _ctrl.isSaving.value ? null : _bookRide,
                isSaving: _ctrl.isSaving.value,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class RideSearchCard extends StatelessWidget {
  final DateTime? selectedDate;
  final String leavingFrom;
  final String goingTo;
  final int passengers;
  final VoidCallback? onPickupTap;
  final VoidCallback? onDropTap;
  final VoidCallback? onDateTap;
  final VoidCallback? onIncrementPassengers;
  final VoidCallback? onDecrementPassengers;
  final VoidCallback? onBookTap;
  final bool isSaving;

  const RideSearchCard({
    super.key,
    required this.selectedDate,
    required this.leavingFrom,
    required this.goingTo,
    required this.passengers,
    required this.onPickupTap,
    required this.onDropTap,
    required this.onDateTap,
    required this.onIncrementPassengers,
    required this.onDecrementPassengers,
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
              _inputRow("Pickup location", leavingFrom, onPickupTap),
              _divider(),
              _inputRow("Drop location", goingTo, onDropTap),
              _divider(),
              _dateRow(onDateTap),
              _divider(),
              _passengerRow(),
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
                            "Book Ride",
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
                "Date",
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

  Widget _passengerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 22, color: Colors.grey),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onDecrementPassengers,
            icon: const Icon(Icons.remove),
          ),
          Text(
            passengers.toString(),
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2F4F4F),
            ),
          ),
          IconButton(
            onPressed: onIncrementPassengers,
            icon: const Icon(Icons.add),
          ),
        ],
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
