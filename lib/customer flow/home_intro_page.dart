import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:dump_and_drop/customer flow/customer_goods_delivery_page.dart';
import 'package:dump_and_drop/customer flow/customer_ride_booking_page.dart';
import 'package:dump_and_drop/customer flow/your_bookings_screen.dart';
import 'package:dump_and_drop/customer flow/inbox_screen.dart';
import 'package:dump_and_drop/customer flow/profile_screen.dart';
import '../controllers/home_controller.dart';

const Color kPrimaryColor = Color(0xFF446FA8);

class HomeIntroPage extends StatefulWidget {
  const HomeIntroPage({super.key});

  @override
  State<HomeIntroPage> createState() => _HomeIntroPageState();
}

class _HomeIntroPageState extends State<HomeIntroPage> {
  final HomeController _ctrl = Get.put(HomeController());

  User? get _user => FirebaseAuth.instance.currentUser;

  void _goToGoodsDelivery() {
    _ctrl.selectService('goods');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerGoodsDeliveryScreen(),
      ),
    );
  }

  void _goToRideBooking() {
    _ctrl.selectService('ride');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerRideBookingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeBody(),
      const InboxScreen(),
      const YourBookingsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: _buildUserHeader(),
      ),
      body: Obx(() => pages[_ctrl.currentIndex.value]),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            currentIndex: _ctrl.currentIndex.value,
            selectedItemColor: kPrimaryColor,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              _ctrl.setIndex(index);
            },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
          )),
    );
  }

  Widget _buildUserHeader() {
    final user = _user;
    if (user == null) {
      return const Text(
        'Dump & Drop',
        style: TextStyle(
          color: Color(0xFF2F4F4F),
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final name = (data['name'] ?? '') as String;
        final photoUrl = (data['photoUrl'] ?? '') as String;

        return Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE0E0E0),
              backgroundImage:
                  photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.black54)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? 'Hi, $name' : 'Hi, Customer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F4F4F),
                  ),
                ),
                Text(
                  user.email ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildHomeBody() {
    const darkGreen = Color(0xFF2F4F4F);
    return Obx(() => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose a service',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Book instant rides or schedule goods delivery whenever you need.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _ServiceCard(
            isSelected: _ctrl.selectedService.value == 'ride',
            title: 'Book a Ride',
            subtitle: 'Quick rides for you or your team, any time.',
            onBookNow: _goToRideBooking,
            onSchedule: _goToRideBooking,
          ),
          const SizedBox(height: 16),
          _ServiceCard(
            isSelected: _ctrl.selectedService.value == 'goods',
            title: 'Goods Delivery',
            subtitle: 'Send parcels and goods safely and on time.',
            onBookNow: _goToGoodsDelivery,
            onSchedule: _goToGoodsDelivery,
          ),
        ],
      ),
    ));
  }
}

class _ServiceCard extends StatelessWidget {
  final bool isSelected;
  final String title;
  final String subtitle;
  final VoidCallback onBookNow;
  final VoidCallback onSchedule;

  const _ServiceCard({
    required this.isSelected,
    required this.title,
    required this.subtitle,
    required this.onBookNow,
    required this.onSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final IconData leadingIcon =
        title.toLowerCase().contains('ride') ? Icons.directions_car : Icons.local_shipping;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? kPrimaryColor : Colors.grey.shade300,
          width: 1.4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  leadingIcon,
                  color: kPrimaryColor,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onBookNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Book now',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSchedule,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kPrimaryColor, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Schedule',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
