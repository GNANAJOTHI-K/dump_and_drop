// lib/driver_flow/order_in_progress_page.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color kPrimaryColor = Color(0xFF446FA8);
const Color kSuccessColor = Color(0xFF4CAF50);
const Color kErrorColor = Color(0xFFF44336);

class OrderInProgressPage extends StatefulWidget {
  final String bookingId;
  final String driverId;

  const OrderInProgressPage({super.key, required this.bookingId, required this.driverId});

  @override
  State<OrderInProgressPage> createState() => _OrderInProgressPageState();
}

class _OrderInProgressPageState extends State<OrderInProgressPage> {
  final _fire = FirebaseFirestore.instance;
  late final DocumentReference<Map<String, dynamic>> _bookingRef;
  bool _loading = true;
  Map<String, dynamic>? _bookingData;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _bookingSub;

  @override
  void initState() {
    super.initState();
    _bookingRef = _fire.collection('rideBookings').doc(widget.bookingId);

    // subscribe and keep the subscription so we can cancel in dispose()
    _bookingSub = _bookingRef.snapshots().listen((snap) {
      if (!snap.exists) return;
      if (!mounted) return;
      setState(() {
        _bookingData = snap.data();
        _loading = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _bookingSub?.cancel();
    super.dispose();
  }

  Future<void> _callCustomer() async {
    final phone = (_bookingData?['customerPhone'] ?? '').toString();
    if (phone.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number available')));
      return;
    }
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open dialer')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open dialer')));
    }
  }

  Future<void> _smsCustomer() async {
    final phone = (_bookingData?['customerPhone'] ?? '').toString();
    if (phone.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number available')));
      return;
    }
    final uri = Uri.parse('sms:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open SMS app')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open SMS app')));
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final googleUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final appleUrl = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d');
    final web = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');

    try {
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleUrl)) {
        await launchUrl(appleUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(web)) {
        await launchUrl(web, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps')));
    }
  }

  Future<void> _verifyPickupOtpOrConfirm() async {
    final expected = (_bookingData?['pickupOtp'] ?? '').toString();
    if (expected.isNotEmpty) {
      final entered = await showDialog<String?>(
        context: context,
        builder: (context) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: const Text('Enter pickup OTP'),
            content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'OTP')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Verify')),
            ],
          );
        },
      );
      if (entered == null) return;
      if (entered.trim() != expected.trim()) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP mismatch'), backgroundColor: kErrorColor));
        return;
      }
    } else {
      final ok = await showDialog<bool?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm pickup'),
          content: const Text('No OTP set. Mark as picked up?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
          ],
        ),
      );
      if (ok != true) return;
    }

    await _bookingRef.update({
      'status': 'picked_up',
      'pickedUpAt': FieldValue.serverTimestamp(),
      'driverPickedUpBy': widget.driverId,
    });

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pickup confirmed'), backgroundColor: kSuccessColor));
  }

  Future<void> _completeRideFlow() async {
    final mode = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) {
        String selectedMode = 'cash';
        final ctrl = TextEditingController(text: (_bookingData?['estimatedFare'] ?? '').toString());
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Complete Ride', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedMode,
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'card', child: Text('Card/Online')),
              ],
              onChanged: (v) => selectedMode = v ?? 'cash',
              decoration: const InputDecoration(labelText: 'Payment mode'),
            ),
            const SizedBox(height: 8),
            TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount collected')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel'))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, '$selectedMode|${ctrl.text.trim()}'),
                child: const Text('Complete'),
              ),
            ]),
            const SizedBox(height: 12),
          ]),
        );
      },
    );

    if (mode == null) return;
    final parts = mode.split('|');
    final paymentMode = parts[0];
    final amountText = parts.length > 1 ? parts[1] : '';
    final collected = double.tryParse(amountText) ?? 0.0;

    await _bookingRef.update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'paymentMode': paymentMode,
      'collectedAmount': collected,
      'driverCompletedBy': widget.driverId,
    });

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride completed'), backgroundColor: kSuccessColor));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _bookingData == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final name = (_bookingData?['customerName'] ?? 'Passenger').toString();
    final phone = (_bookingData?['customerPhone'] ?? '').toString();
    final pickupLat = (_bookingData?['pickupLat'] is num) ? (_bookingData!['pickupLat'] as num).toDouble() : null;
    final pickupLng = (_bookingData?['pickupLng'] is num) ? (_bookingData!['pickupLng'] as num).toDouble() : null;
    final pickupLabel = (_bookingData?['pickupLabel'] ?? 'Pickup').toString();
    final dropLat = (_bookingData?['dropLat'] is num) ? (_bookingData!['dropLat'] as num).toDouble() : null;
    final dropLng = (_bookingData?['dropLng'] is num) ? (_bookingData!['dropLng'] as num).toDouble() : null;
    final dropLabel = (_bookingData?['dropLabel'] ?? 'Drop').toString();
    final status = (_bookingData?['status'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order in progress'),
        backgroundColor: kPrimaryColor,
        actions: [if (phone.isNotEmpty) IconButton(icon: const Icon(Icons.call), onPressed: _callCustomer)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(children: [
            Text(phone, style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(width: 12),
            ElevatedButton.icon(onPressed: _callCustomer, icon: const Icon(Icons.call), label: const Text('Call')),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: _smsCustomer, icon: const Icon(Icons.message), label: const Text('Message')),
          ]),
          const Divider(height: 22),
          Text('Pickup', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(pickupLabel, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 8),
          Row(children: [
            if (pickupLat != null && pickupLng != null)
              ElevatedButton.icon(onPressed: () => _openMaps(pickupLat, pickupLng), icon: const Icon(Icons.navigation), label: const Text('Navigate to pickup')),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: (status == 'picked_up' || status == 'completed') ? null : _verifyPickupOtpOrConfirm,
              icon: const Icon(Icons.check),
              label: Text(status == 'picked_up' ? 'Picked up' : 'Reached Pickup'),
              style: ElevatedButton.styleFrom(backgroundColor: status == 'picked_up' ? Colors.grey : kPrimaryColor),
            ),
          ]),
          const SizedBox(height: 16),
          Text('Drop', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(dropLabel, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 8),
          Row(children: [
            if (dropLat != null && dropLng != null)
              ElevatedButton.icon(onPressed: status == 'picked_up' ? () => _openMaps(dropLat, dropLng) : null, icon: const Icon(Icons.navigation), label: const Text('Navigate to drop')),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: status == 'picked_up' ? _completeRideFlow : null,
              icon: const Icon(Icons.check_circle),
              label: const Text('Complete Ride'),
              style: ElevatedButton.styleFrom(backgroundColor: status == 'picked_up' ? kSuccessColor : Colors.grey),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w700)), Text(status, style: const TextStyle(color: Colors.black54))]),
          const SizedBox(height: 16),
          if (_bookingData != null) Expanded(child: SingleChildScrollView(child: Text(_bookingData.toString(), style: const TextStyle(fontSize: 10, color: Colors.black26)))),
        ]),
      ),
    );
  }
}
