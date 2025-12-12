// lib/booking_details_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingDetailsPage extends StatelessWidget {
  final String customerId;
  final String bookingId;

  const BookingDetailsPage({super.key, required this.customerId, required this.bookingId});

  Stream<DocumentSnapshot<Map<String, dynamic>>> _bookingStream() {
    return FirebaseFirestore.instance.collection('customers').doc(customerId).collection('bookings').doc(bookingId).snapshots();
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '—';
    try {
      if (ts is Timestamp) return DateFormat('yyyy-MM-dd HH:mm').format(ts.toDate().toLocal());
      if (ts is DateTime) return DateFormat('yyyy-MM-dd HH:mm').format(ts.toLocal());
      if (ts is int) return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ts).toLocal());
    } catch (_) {}
    return ts.toString();
  }

  Widget _row(String title, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 120, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))), Expanded(child: Text(value))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _bookingStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('Booking not found'));

          final data = snapshot.data!.data()!;
          final createdAt = _formatTimestamp(data['createdAt']);
          final pickupLabel = data['pickupLabel']?.toString() ?? '—';
          final pickupLat = data['pickupLat']?.toString() ?? '—';
          final pickupLng = data['pickupLng']?.toString() ?? '—';
          final dropLabel = data['dropLabel']?.toString() ?? '—';
          final dropLat = data['dropLat']?.toString() ?? '—';
          final dropLng = data['dropLng']?.toString() ?? '—';
          final passengers = data['passengers']?.toString() ?? '—';
          final rideDate = data['rideDate'] == null ? 'Not scheduled' : _formatTimestamp(data['rideDate']);
          final service = data['service']?.toString() ?? '—';
          final status = data['status']?.toString() ?? '—';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
  'Booking ID: $bookingId',
  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
         ?? const TextStyle(fontWeight: FontWeight.bold),
),
                  const SizedBox(height: 8),
                  _row('Created at', createdAt),
                  const Divider(),
                  _row('Customer ID', customerId),
                  const SizedBox(height: 8),
                  const Text('Pickup', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _row('Label', pickupLabel),
                  _row('Lat', pickupLat),
                  _row('Lng', pickupLng),
                  const Divider(),
                  const Text('Drop', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _row('Label', dropLabel),
                  _row('Lat', dropLat),
                  _row('Lng', dropLng),
                  const Divider(),
                  _row('Passengers', passengers),
                  _row('Ride date', rideDate),
                  _row('Service', service),
                  _row('Status', status),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
