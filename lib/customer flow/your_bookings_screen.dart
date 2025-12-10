import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color kPrimaryColor = Color(0xFF446FA8);

class YourBookingsScreen extends StatelessWidget {
  const YourBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          title: const Text('Your Bookings'),
        ),
        body: const Center(
          child: Text('User not logged in'),
        ),
      );
    }

    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        title: const Text('Your Bookings'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future:
            FirebaseFirestore.instance.collection('customers').doc(uid).get(),
        builder: (context, userSnap) {
          String customerName = '';
          if (userSnap.hasData && userSnap.data!.data() != null) {
            customerName =
                (userSnap.data!.data()!['name'] ?? '') as String? ?? '';
          }

          final bookingsStream = FirebaseFirestore.instance
              .collection('customers')
              .doc(uid)
              .collection('bookings')
              .orderBy('createdAt', descending: true)
              .snapshots();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: bookingsStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No bookings yet'),
                );
              }

              final docs = snap.data!.docs;

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data();

                  final pickupLabel =
                      (data['pickupLabel'] ?? '') as String? ?? '';
                  final dropLabel = (data['dropLabel'] ?? '') as String? ?? '';
                  final passengers = data['passengers'];
                  final service =
                      (data['service'] ?? 'ride') as String? ?? 'ride';
                  final status = (data['status'] ?? 'pending') as String? ??
                      'pending';

                  final rideDateTs = data['rideDate'] as Timestamp?;
                  final pickupDateTs = data['pickupDate'] as Timestamp?;
                  String dateText = 'Not set';
                  final ts = rideDateTs ?? pickupDateTs;
                  if (ts != null) {
                    final d = ts.toDate();
                    dateText =
                        "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
                  }

                  final statusLabel =
                      status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : 'Pending';

                  String serviceLabel = 'Ride';
                  if (service == 'goods') {
                    serviceLabel = 'Goods Delivery';
                  }

                  String middleLine = "";
                  if (service == 'ride' && passengers != null) {
                    middleLine = "Passengers: $passengers";
                  } else if (service == 'goods') {
                    final w = data['packageWeight'];
                    final category = (data['packageCategory'] ?? '') as String? ?? '';
                    final weightStr =
                        w != null ? "${(w as num).toStringAsFixed(1)} kg" : "";
                    middleLine = [weightStr, category]
                        .where((e) => e.isNotEmpty)
                        .join(" • ");
                  }

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: kPrimaryColor,
                                child: Icon(
                                  service == 'goods'
                                      ? Icons.local_shipping
                                      : Icons.directions_car,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "$pickupLabel → $dropLabel",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (customerName.isNotEmpty)
                            Text(
                              "Booked by: $customerName",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          const SizedBox(height: 4),
                          if (middleLine.isNotEmpty)
                            Text(
                              middleLine,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            "Date: $dateText",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Status: $statusLabel",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: status == 'completed'
                                      ? Colors.green
                                      : status == 'cancelled'
                                          ? Colors.red
                                          : Colors.orange,
                                ),
                              ),
                              Text(
                                serviceLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
