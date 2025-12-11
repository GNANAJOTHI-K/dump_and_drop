import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../driver_login_screen.dart';

const Color kPrimaryColor = Color(0xFF446FA8);

class DriverHomeIntroPage extends StatelessWidget {
  const DriverHomeIntroPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DriverLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Driver not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('drivers')
              .doc(user.uid)
              .snapshots(),
          builder: (context, driverSnap) {
            if (!driverSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final driverData =
                driverSnap.data!.data() as Map<String, dynamic>? ?? {};

            final details =
                (driverData['passengerVehicleDetails'] ?? {}) as Map<String, dynamic>;
            final name = (details['fullName'] ?? 'Driver') as String;
            final profileUrl =
                (details['vehiclePhotoUrl'] ?? '') as String;
            final isOnline = (driverData['online'] ?? false) as bool;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- TOP NAV STYLE: AVATAR + NAME + LOGOUT ----------
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: kPrimaryColor.withOpacity(0.12),
                        backgroundImage:
                            profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                        child: profileUrl.isEmpty
                            ? const Icon(Icons.person, color: kPrimaryColor)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome back,",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFFDEF7E1)
                              : const Color(0xFFE7EAF5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: isOnline
                                  ? Colors.green
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? "Online" : "Offline",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isOnline
                                    ? Colors.green.shade700
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.black87),
                        onPressed: () => _logout(context),
                        tooltip: "Logout",
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Your account has been approved by Dump & Drop.\n"
                    "You can now start accepting trips and deliveries.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Small section title
                  const Text(
                    "Ride requests near you",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ---------- BOOKINGS + RIDE SERVICE LIST ----------
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      // Get all bookings where status = pending
                      // Path: customers/{anyCustomerId}/bookings/{bookingId}
                      stream: FirebaseFirestore.instance
                          .collectionGroup('bookings')
                          .where('status', isEqualTo: 'pending')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              "No active ride requests now.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }

                        final bookingDocs = snapshot.data!.docs;

                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          itemCount: bookingDocs.length,
                          itemBuilder: (context, index) {
                            final bookingDoc = bookingDocs[index];
                            final bookingRef = bookingDoc.reference;

                            // 🔹 bookingRef path:
                            // /customers/{customerId}/bookings/{bookingId}
                            final customerId =
                                bookingRef.parent.parent!.id;
                            final bookingId = bookingRef.id;

                            // 🔹 EXACT STREAM YOU ASKED FOR:
                            final rideServiceStream = FirebaseFirestore.instance
                                .collection('customers')
                                .doc(customerId)
                                .collection('bookings')
                                .doc(bookingId)
                                .collection('service')
                                .where('serviceType', isEqualTo: 'ride')
                                .orderBy('createdAt', descending: true)
                                .snapshots();

                            return StreamBuilder<QuerySnapshot>(
                              stream: rideServiceStream,
                              builder: (context, rideSnap) {
                                if (rideSnap.connectionState ==
                                    ConnectionState.waiting) {
                                  // can show a small loader or nothing
                                  return const SizedBox.shrink();
                                }

                                if (!rideSnap.hasData ||
                                    rideSnap.data!.docs.isEmpty) {
                                  // This booking has no ride service → skip
                                  return const SizedBox.shrink();
                                }

                                // Take latest ride service doc
                                final rideDoc = rideSnap.data!.docs.first;
                                final rideData = rideDoc.data()
                                    as Map<String, dynamic>;

                                return _RideBookingCard(
                                  bookingRef: rideDoc.reference, // points to service/ride doc
                                  data: rideData,
                                  driverId: user.uid,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),

      // ---------- GO ONLINE BUTTON AT BOTTOM ----------
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('drivers')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final data =
                  snapshot.data?.data() as Map<String, dynamic>? ?? {};
              final isOnline = (data['online'] ?? false) as bool;

              return SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(
                    isOnline
                        ? Icons.power_settings_new_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(isOnline ? "Go Offline" : "Go Online"),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('drivers')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .update({"online": !isOnline});

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isOnline
                              ? "You are now Offline"
                              : "You are now Online",
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RideBookingCard extends StatelessWidget {
  final DocumentReference bookingRef;
  final Map<String, dynamic> data;
  final String driverId;

  const _RideBookingCard({
    required this.bookingRef,
    required this.data,
    required this.driverId,
  });

  @override
  Widget build(BuildContext context) {
    final passengerName = (data['customerName'] ?? 'Passenger') as String;
    final pickup =
        (data['pickup'] ?? data['pickupLocation'] ?? 'Pickup') as String;
    final drop =
        (data['drop'] ?? data['dropLocation'] ?? 'Drop') as String;
    final serviceType = (data['serviceType'] ?? 'Ride') as String;
    final fareText =
        data['estimatedFare'] != null ? "₹${data['estimatedFare']}" : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                passengerName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  serviceType,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.radio_button_checked,
                  size: 16, color: kPrimaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pickup,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.redAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  drop,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),

          if (fareText != null) ...[
            const SizedBox(height: 8),
            Text(
              "Estimated fare: $fareText",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await bookingRef.update({
                  "status": "driver_assigned",
                  "driverId": driverId,
                  "assignedAt": FieldValue.serverTimestamp(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text("Ride accepted. Passenger will see driver info."),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Accept ride"),
            ),
          ),
        ],
      ),
    );
  }
}
