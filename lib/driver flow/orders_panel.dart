// lib/driver_flow/orders_panel.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

Map<String, dynamic> _toStrMap(Object? raw) {
  if (raw == null) return <String, dynamic>{};
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

const Color kPrimaryColor = Color(0xFF446FA8);
const Color kSuccessColor = Color(0xFF4CAF50);
const Color kErrorColor = Color(0xFFF44336);
const Color kWarningColor = Color(0xFFFF9800);

/// Main OrdersPanel widget that shows available rides
class OrdersPanel extends StatefulWidget {
  final bool isOnline;
  final Future<void> Function(DocumentReference<Map<String, dynamic>> bookingRef)? onAccept;
  final int compactLimit;

  const OrdersPanel({
    super.key,
    required this.isOnline,
    this.onAccept,
    this.compactLimit = 4,
  });

  @override
  State<OrdersPanel> createState() => _OrdersPanelState();
}

class _OrdersPanelState extends State<OrdersPanel> {
  String? _currentOrderId;
  bool _showOrderDetails = false;

  void _showOrderInProgress(String bookingId, String driverId) {
    setState(() {
      _currentOrderId = bookingId;
      _showOrderDetails = true;
    });
  }

  void _hideOrderDetails() {
    setState(() {
      _showOrderDetails = false;
      _currentOrderId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOrderDetails && _currentOrderId != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const Center(child: Text('User not authenticated'));
      }
      return OrderInProgressPage(
        bookingId: _currentOrderId!,
        driverId: user.uid,
        onBack: _hideOrderDetails,
      );
    }

    if (!widget.isOnline) return const _OfflineView();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rideBookings')
          .where('service', isEqualTo: 'ride')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final err = snapshot.error;
          final errMsg = err is FirebaseException ? err.message ?? err.code : err.toString();
          return Center(child: Text('Error: $errMsg', style: const TextStyle(color: Colors.red)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const _WaitingForOrdersView();

        final int compactCount = docs.length < widget.compactLimit ? docs.length : widget.compactLimit;
        final List<QueryDocumentSnapshot<Map<String, dynamic>>> compactDocs = docs.take(compactCount).toList();
        final List<QueryDocumentSnapshot<Map<String, dynamic>>> remainingDocs = docs.skip(compactCount).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (compactDocs.isNotEmpty)
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: compactDocs.length,
                  itemBuilder: (context, index) {
                    final docSnap = compactDocs[index];
                    final data = docSnap.data();
                    return _CompactRideCard(
                      data: data,
                      bookingRef: docSnap.reference,
                      onAccept: (ref) => _handleAcceptAndNavigate(context, ref),
                    );
                  },
                ),
              ),

            if (remainingDocs.isNotEmpty) const SizedBox(height: 16),

            if (remainingDocs.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "All Ride Requests",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
              ),

            if (remainingDocs.isNotEmpty) const SizedBox(height: 8),

            if (remainingDocs.isNotEmpty)
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: remainingDocs.length,
                itemBuilder: (context, index) {
                  final docSnap = remainingDocs[index];
                  final data = docSnap.data();
                  return _StandardRideCard(
                    data: data,
                    bookingRef: docSnap.reference,
                    onAccept: (ref) => _handleAcceptAndNavigate(context, ref),
                  );
                },
              ),

            if (remainingDocs.isEmpty && docs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Showing top $compactCount requests. Stay online for more.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _handleAcceptAndNavigate(BuildContext context, DocumentReference<Map<String, dynamic>> bookingRef) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authenticated')));
      return;
    }
    final driverId = user.uid;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(bookingRef);
        if (!snap.exists) throw Exception('Booking removed');
        final data = snap.data()!;
        final status = (data['status'] ?? '').toString();
        if (status != 'pending') throw Exception('Booking already taken');
        tx.update(bookingRef, {
          'status': 'driver_assigned',
          'driverId': driverId,
          'assignedAt': FieldValue.serverTimestamp(),
        });
      });

      try {
        final serviceColl = bookingRef.collection('service');
        final qs = await serviceColl.get();
        final batch = FirebaseFirestore.instance.batch();
        for (final d in qs.docs) {
          batch.update(d.reference, {
            'status': 'driver_assigned',
            'driverId': driverId,
            'assignedAt': FieldValue.serverTimestamp(),
          });
        }
        if (qs.docs.isNotEmpty) await batch.commit();
      } catch (_) {}

      if (widget.onAccept != null) {
        try {
          await widget.onAccept!(bookingRef);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Warning: post-accept hook failed: ${e.toString()}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      if (Navigator.canPop(context)) Navigator.pop(context);

      if (context.mounted) {
        _showOrderInProgress(bookingRef.id, driverId);
      }
    } on FirebaseException catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      final code = e.code;
      if (code == 'permission-denied') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission denied while accepting. Check Firestore rules.'),
              backgroundColor: kErrorColor,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Accept failed: ${e.message ?? e.code}'), backgroundColor: kErrorColor),
          );
        }
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Accept failed: ${e.toString()}'), backgroundColor: kErrorColor),
        );
      }
    }
  }
}

/// =================== ORDER IN PROGRESS PAGE ===================
class OrderInProgressPage extends StatefulWidget {
  final String bookingId;
  final String driverId;
  final VoidCallback? onBack;

  const OrderInProgressPage({
    super.key,
    required this.bookingId,
    required this.driverId,
    this.onBack,
  });

  @override
  State<OrderInProgressPage> createState() => _OrderInProgressPageState();
}

class _OrderInProgressPageState extends State<OrderInProgressPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late DocumentReference<Map<String, dynamic>> _bookingRef;
  Map<String, dynamic>? _bookingData;
  bool _loading = true;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _bookingStream;
  final MapController _mapController = MapController();
  TextEditingController _otpController = TextEditingController();
  TextEditingController _amountController = TextEditingController();
  String _paymentMode = 'cash';
  double _currentZoom = 15.0;
  LatLng? _pickupLocation;
  LatLng? _dropLocation;

  @override
  void initState() {
    super.initState();
    _bookingRef = _firestore.collection('rideBookings').doc(widget.bookingId);
    _setupBookingListener();
  }

  void _setupBookingListener() {
    _bookingStream = _bookingRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          _bookingData = data;
          _loading = false;

          // Update locations for map
          if (data['pickupLat'] != null && data['pickupLng'] != null) {
            _pickupLocation = LatLng(
              (data['pickupLat'] as num).toDouble(),
              (data['pickupLng'] as num).toDouble(),
            );
          }
          if (data['dropLat'] != null && data['dropLng'] != null) {
            _dropLocation = LatLng(
              (data['dropLat'] as num).toDouble(),
              (data['dropLng'] as num).toDouble(),
            );
          }

          // Initialize amount controller
          if (data['estimatedFare'] != null && _amountController.text.isEmpty) {
            _amountController.text = (data['estimatedFare'] as num).toStringAsFixed(0);
          }
        });

        // Center map on pickup location using post-frame callback so controller is ready.
        if (_pickupLocation != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              _mapController.move(_pickupLocation!, _currentZoom);
            } catch (_) {
              // controller not ready yet or other map issue — ignore; next snapshot will attempt again
            }
          });
        }
      }
    }, onError: (error) {
      setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _bookingStream?.cancel();
    _otpController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _callCustomer() async {
    final phone = (_bookingData?['customerPhone'] ?? '').toString();
    if (phone.isEmpty) {
      _showSnackBar('No phone number available', isError: true);
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnackBar('Cannot open dialer', isError: true);
    }
  }

  Future<void> _smsCustomer() async {
    final phone = (_bookingData?['customerPhone'] ?? '').toString();
    if (phone.isEmpty) {
      _showSnackBar('No phone number available', isError: true);
      return;
    }
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnackBar('Cannot open SMS app', isError: true);
    }
  }

  Future<void> _openGoogleMaps(double lat, double lng, String label) async {
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    final googleMapsAppUrl = Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving');
    final appleMapsUrl = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d');

    if (await canLaunchUrl(googleMapsAppUrl)) {
      await launchUrl(googleMapsAppUrl);
    } else if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl);
    } else {
      _showSnackBar('Could not open maps app', isError: true);
    }
  }

  Future<void> _verifyPickupOTP() async {
    final expectedOTP = (_bookingData?['pickupOtp'] ?? '').toString();

    if (expectedOTP.isEmpty) {
      _confirmPickup();
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Pickup OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Customer OTP: $expectedOTP'),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                border: OutlineInputBorder(),
              ),
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _otpController.text.trim()),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (result == expectedOTP) {
        _confirmPickup();
      } else {
        _showSnackBar('Invalid OTP', isError: true);
      }
    }
  }

  Future<void> _confirmPickup() async {
    try {
      await _bookingRef.update({
        'status': 'picked_up',
        'pickedUpAt': FieldValue.serverTimestamp(),
        'driverPickedUpBy': widget.driverId,
      });
      _showSnackBar('Pickup confirmed!', isError: false);
    } catch (e) {
      _showSnackBar('Failed: $e', isError: true);
    }
  }

  Future<void> _showPaymentDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Complete Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Mode:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: [
                        ChoiceChip(
                          label: const Text('Cash'),
                          selected: _paymentMode == 'cash',
                          onSelected: (selected) => setState(() => _paymentMode = 'cash'),
                        ),
                        ChoiceChip(
                          label: const Text('Card'),
                          selected: _paymentMode == 'card',
                          onSelected: (selected) => setState(() => _paymentMode = 'card'),
                        ),
                        ChoiceChip(
                          label: const Text('UPI'),
                          selected: _paymentMode == 'upi',
                          onSelected: (selected) => setState(() => _paymentMode = 'upi'),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount Collected (₹)',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _completeRide();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: kSuccessColor),
                        child: const Text('Complete Ride'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _completeRide() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 0) {
      _showSnackBar('Enter valid amount', isError: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Amount: ₹$amount'),
            Text('Payment: $_paymentMode'),
            const SizedBox(height: 10),
            const Text('Complete this ride?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _bookingRef.update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'paymentMode': _paymentMode,
          'collectedAmount': amount,
          'driverCompletedBy': widget.driverId,
        });

        _showSnackBar('Ride completed!', isError: false);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && widget.onBack != null) widget.onBack!();
        });
      } catch (e) {
        _showSnackBar('Failed: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? kErrorColor : kSuccessColor,
      ),
    );
  }

  Widget _buildMap() {
    final center = _pickupLocation ?? const LatLng(12.9716, 77.5946);

    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: _currentZoom,
            maxZoom: 19.0,
            minZoom: 3.0,
            onPositionChanged: (pos, hasGesture) {
              if (pos.zoom != null) _currentZoom = pos.zoom!;
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.dump_and_drop',
            ),
            if (_pickupLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pickupLocation!,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1.5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: kPrimaryColor,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            if (_dropLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _dropLocation!,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kErrorColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1.5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: kErrorColor,
                        size: 28,
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final customerName = (_bookingData?['customerName'] ?? 'Customer').toString();
    final customerPhone = (_bookingData?['customerPhone'] ?? '').toString();
    final pickupLabel = (_bookingData?['pickupLabel'] ?? 'Pickup Location').toString();
    final dropLabel = (_bookingData?['dropLabel'] ?? 'Drop Location').toString();
    final status = (_bookingData?['status'] ?? '').toString();
    final pickupLat = (_bookingData?['pickupLat'] is num) ? (_bookingData!['pickupLat'] as num).toDouble() : null;
    final pickupLng = (_bookingData?['pickupLng'] is num) ? (_bookingData!['pickupLng'] as num).toDouble() : null;
    final dropLat = (_bookingData?['dropLat'] is num) ? (_bookingData!['dropLat'] as num).toDouble() : null;
    final dropLng = (_bookingData?['dropLng'] is num) ? (_bookingData!['dropLng'] as num).toDouble() : null;

    final isPickedUp = status == 'picked_up' || status == 'completed';
    final isCompleted = status == 'completed';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('Order in Progress'),
        backgroundColor: kPrimaryColor,
        actions: [
          if (customerPhone.isNotEmpty) IconButton(icon: const Icon(Icons.call), onPressed: _callCustomer),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Info
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(customerPhone, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _callCustomer,
                            icon: const Icon(Icons.call),
                            label: const Text('Call'),
                            style: ElevatedButton.styleFrom(backgroundColor: kSuccessColor),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _smsCustomer,
                            icon: const Icon(Icons.message),
                            label: const Text('Message'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Map
            _buildMap(),

            const SizedBox(height: 20),

            // Pickup Section
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: kPrimaryColor),
                        const SizedBox(width: 8),
                        const Text('Pickup Point', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(pickupLabel, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: pickupLat != null && pickupLng != null ? () => _openGoogleMaps(pickupLat, pickupLng, pickupLabel) : null,
                            icon: const Icon(Icons.navigation),
                            label: const Text('Navigate'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isPickedUp || isCompleted ? null : _verifyPickupOTP,
                            icon: const Icon(Icons.check),
                            label: Text(isPickedUp ? 'Picked Up' : 'Reached'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPickedUp ? Colors.grey : kWarningColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Drop Section
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: kErrorColor),
                        const SizedBox(width: 8),
                        const Text('Drop Point', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(dropLabel, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: dropLat != null && dropLng != null && isPickedUp ? () => _openGoogleMaps(dropLat, dropLng, dropLabel) : null,
                            icon: const Icon(Icons.navigation),
                            label: const Text('Navigate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPickedUp ? kPrimaryColor : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isPickedUp && !isCompleted ? _showPaymentDialog : null,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Complete Ride'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPickedUp && !isCompleted ? kSuccessColor : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Status Info
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ride Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'driver_assigned':
        return kPrimaryColor;
      case 'picked_up':
        return kWarningColor;
      case 'completed':
        return kSuccessColor;
      default:
        return Colors.grey;
    }
  }
}

/// ---------------- Compact Ride Card ----------------
class _CompactRideCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final DocumentReference<Map<String, dynamic>> bookingRef;
  final Future<void> Function(DocumentReference<Map<String, dynamic>> bookingRef) onAccept;

  const _CompactRideCard({
    required this.data,
    required this.bookingRef,
    required this.onAccept,
  });

  @override
  State<_CompactRideCard> createState() => __CompactRideCardState();
}

class __CompactRideCardState extends State<_CompactRideCard> {
  bool _isAccepting = false;

  @override
  Widget build(BuildContext context) {
    final passengerName = (widget.data['customerName'] ?? widget.data['customerId'] ?? 'Passenger').toString();
    final pickup = (widget.data['pickupLabel'] ?? 'Pickup').toString();
    final drop = (widget.data['dropLabel'] ?? 'Drop').toString();
    final fareText = widget.data['estimatedFare'] != null ? "₹${(widget.data['estimatedFare'] as num).toStringAsFixed(0)}" : null;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: kPrimaryColor, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passengerName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber.shade600, size: 12),
                          const SizedBox(width: 2),
                          Text('4.8', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (fareText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kSuccessColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      fareText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kSuccessColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pickup,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Container(width: 2, height: 12, color: Colors.grey.shade300),
                ),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: kErrorColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        drop,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: _isAccepting
                  ? null
                  : () async {
                      setState(() => _isAccepting = true);
                      try {
                        await widget.onAccept(widget.bookingRef);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed: ${e.toString()}'),
                              backgroundColor: kErrorColor,
                            ),
                          );
                          setState(() => _isAccepting = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kSuccessColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _isAccepting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'ACCEPT RIDE',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------- Standard Ride Card ----------------
class _StandardRideCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final DocumentReference<Map<String, dynamic>> bookingRef;
  final Future<void> Function(DocumentReference<Map<String, dynamic>> bookingRef) onAccept;

  const _StandardRideCard({
    required this.data,
    required this.bookingRef,
    required this.onAccept,
  });

  @override
  State<_StandardRideCard> createState() => __StandardRideCardState();
}

class __StandardRideCardState extends State<_StandardRideCard> {
  bool _isAccepting = false;
  bool _isIgnored = false;

  @override
  Widget build(BuildContext context) {
    if (_isIgnored) return const SizedBox();

    final passengerName = (widget.data['customerName'] ?? widget.data['customerId'] ?? 'Passenger').toString();
    final pickup = (widget.data['pickupLabel'] ?? 'Pickup').toString();
    final drop = (widget.data['dropLabel'] ?? 'Drop').toString();
    final fareText = widget.data['estimatedFare'] != null
        ? "₹${(widget.data['estimatedFare'] as num).toStringAsFixed(0)}"
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: kPrimaryColor, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passengerName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber.shade600, size: 12),
                          const SizedBox(width: 2),
                          Text('4.8', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          const SizedBox(width: 6),
                          Icon(Icons.directions_car, color: Colors.grey.shade600, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            'SUV • AC',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (fareText != null)
                  Text(
                    fareText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kSuccessColor,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pickup,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: kErrorColor, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        drop,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isAccepting
                        ? null
                        : () async {
                            setState(() => _isAccepting = true);
                            try {
                              await widget.onAccept(widget.bookingRef);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed: ${e.toString()}'),
                                    backgroundColor: kErrorColor,
                                  ),
                                );
                                setState(() => _isAccepting = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSuccessColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isAccepting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Accept Ride',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() => _isIgnored = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ride ignored'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    icon: Icon(Icons.close, color: Colors.grey.shade600, size: 20),
                    padding: EdgeInsets.zero,
                    tooltip: 'Ignore',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------- Offline & Waiting UIs ----------------
class _OfflineView extends StatelessWidget {
  const _OfflineView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_outlined, size: 40, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'You are Offline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Go online to receive new ride requests',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingForOrdersView extends StatelessWidget {
  const _WaitingForOrdersView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_empty, size: 40, color: kPrimaryColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Waiting for Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Stay online and keep your location enabled to receive nearby ride requests.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
