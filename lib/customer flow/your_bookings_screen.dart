// lib/screens/your_bookings_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'live_ride_screen.dart';

class YourBookingsScreen extends StatefulWidget {
  const YourBookingsScreen({super.key});

  @override
  State<YourBookingsScreen> createState() => _YourBookingsScreenState();
}

class _YourBookingsScreenState extends State<YourBookingsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot<Map<String, dynamic>>> _bookingsStream() {
    if (user == null) {
      // Return an empty stream if user is null
      return const Stream.empty() as Stream<QuerySnapshot<Map<String, dynamic>>>;
    }
    return FirebaseFirestore.instance
        .collection('rideBookings')
        .where('customerId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Bookings'),
        backgroundColor: const Color(0xFF446FA8),
      ),
      body: user == null
          ? const Center(child: Text('Please sign in'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _bookingsStream(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No bookings yet'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final docSnap = docs[index];
                    final d = docSnap.data();
                    final bookingId = docSnap.id;
                    final status = d['status']?.toString() ?? 'unknown';
                    final pickup = d['pickupLabel']?.toString() ?? '';
                    final drop = d['dropLabel']?.toString() ?? '';
                    final createdAtTs = d['createdAt'] is Timestamp ? d['createdAt'] as Timestamp : null;
                    final createdAt = createdAtTs != null ? createdAtTs.toDate() : null;
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text('$pickup → $drop'),
                        subtitle: Text('Status: ${status.toUpperCase()}'
                            + (createdAt != null ? ' • ${createdAt.toLocal()}' : '')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LiveRideScreen(bookingId: bookingId),
                                  ),
                                );
                              },
                              child: const Text('Live'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF446FA8)),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                // simple cancel (optional)
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Cancel booking'),
                                    content: const Text('Do you want to cancel this booking?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          await FirebaseFirestore.instance.collection('rideBookings').doc(bookingId).set({
                                            'status': 'cancelled',
                                          }, SetOptions(merge: true));
                                        },
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.delete_outline),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
