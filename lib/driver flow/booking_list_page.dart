// lib/bookings_list_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'booking_details_page.dart';
import 'package:intl/intl.dart';

class BookingsListPage extends StatelessWidget {
  const BookingsListPage({super.key});

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '—';
    try {
      if (ts is Timestamp) return DateFormat('yyyy-MM-dd HH:mm').format(ts.toDate().toLocal());
      if (ts is DateTime) return DateFormat('yyyy-MM-dd HH:mm').format(ts.toLocal());
      if (ts is int) return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ts).toLocal());
    } catch (_) {}
    return ts.toString();
  }

  Map<String, String>? _extractIdsFromPath(String path) {
    final parts = path.split('/');
    final custIdx = parts.indexOf('customers');
    if (custIdx != -1 && parts.length > custIdx + 3 && parts[custIdx + 2] == 'bookings') {
      final customerId = parts[custIdx + 1];
      final bookingId = parts[custIdx + 3];
      return {'customerId': customerId, 'bookingId': bookingId};
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance.collectionGroup('bookings').orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('All Bookings')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No bookings found.'));

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final createdAt = _formatTimestamp(data['createdAt']);
              final pickup = data['pickupLabel']?.toString() ?? '—';
              final drop = data['dropLabel']?.toString() ?? '—';
              final status = data['status']?.toString() ?? '—';
              final ids = _extractIdsFromPath(doc.reference.path);

              return ListTile(
                title: Text(pickup, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('Drop: $drop\nCreated: $createdAt'),
                trailing: Text(status),
                onTap: () {
                  if (ids == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open booking (unexpected path).')));
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailsPage(customerId: ids['customerId']!, bookingId: ids['bookingId']!)));
                },
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
