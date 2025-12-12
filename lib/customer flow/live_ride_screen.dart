// lib/screens/live_ride_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color kPrimaryColor = Color(0xFF446FA8);

class LiveRideScreen extends StatelessWidget {
  final String bookingId;

  const LiveRideScreen({super.key, required this.bookingId});

  static const List<_StepDef> _steps = [
    _StepDef(key: 'pending', label: 'Waiting'),
    _StepDef(key: 'accepted', label: 'Accepted'),
    _StepDef(key: 'arriving', label: 'Arriving'),
    _StepDef(key: 'on_trip', label: 'On Trip'),
    _StepDef(key: 'reached', label: 'Reached'),
    _StepDef(key: 'completed', label: 'Completed'),
  ];

  @override
  Widget build(BuildContext context) {
    final bookingsRef = FirebaseFirestore.instance.collection('rideBookings').doc(bookingId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Ride'),
        backgroundColor: kPrimaryColor,
        automaticallyImplyLeading: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: bookingsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _centerMessage('Error: ${snapshot.error}');
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() ?? {};
          // Primary state — this screen no longer shows driver personal details
          final status = (data['status'] as String?)?.toLowerCase() ?? 'pending';
          final etaRaw = data['eta'];
          final Timestamp? lastUpdatedTs = data['lastUpdated'] is Timestamp ? data['lastUpdated'] as Timestamp : null;

          // driver location can be in driverLocation map or fields driverLat/driverLng
          Map<String, dynamic>? driverLocation;
          if (data['driverLocation'] is Map) {
            driverLocation = Map<String, dynamic>.from(data['driverLocation'] as Map);
          } else if (data.containsKey('driverLat') && data.containsKey('driverLng')) {
            driverLocation = {
              'lat': (data['driverLat'] is num) ? (data['driverLat'] as num).toDouble() : data['driverLat'],
              'lng': (data['driverLng'] is num) ? (data['driverLng'] as num).toDouble() : data['driverLng'],
            };
          }

          final double? lat = driverLocation != null ? (driverLocation['lat'] as double?) : null;
          final double? lng = driverLocation != null ? (driverLocation['lng'] as double?) : null;

          String etaLabel = '—';
          if (etaRaw is Timestamp) etaLabel = DateFormat.Hm().format(etaRaw.toDate());
          else if (etaRaw is String) etaLabel = etaRaw;
          else if (etaRaw is int) etaLabel = DateFormat.Hm().format(DateTime.fromMillisecondsSinceEpoch(etaRaw));

          final lastUpdatedLabel = lastUpdatedTs != null ? DateFormat('dd MMM, HH:mm').format(lastUpdatedTs.toDate()) : '—';

          // compute currentStepIndex for stepper UI
          final int stepIndex = _steps.indexWhere((s) => s.key == status).clamp(0, _steps.length - 1);

          return Column(
            children: [
              // Top summary card with ETA + last updated
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 36, color: kPrimaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Live updates', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              const SizedBox(height: 6),
                              Text(
                                _statusHeadline(status),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Text('Last update: $lastUpdatedLabel', style: const TextStyle(fontSize: 12, color: Colors.black45)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('ETA', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            Text(etaLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Horizontal stepper
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: _HorizontalStepper(steps: _steps, activeIndex: stepIndex),
              ),

              const SizedBox(height: 12),

              // Map / location area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F9FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE6EEF3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_outlined, size: 64, color: Colors.black26),
                        const SizedBox(height: 8),
                        const Text('Map preview (replace with GoogleMap widget if available)', style: TextStyle(color: Colors.black45)),
                        const SizedBox(height: 12),
                        if (lat != null && lng != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Driver position:\nLat: ${lat.toStringAsFixed(6)}  ,  Lng: ${lng.toStringAsFixed(6)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          )
                        else
                          const Text('Driver location not yet available', style: TextStyle(color: Colors.black45)),
                        const SizedBox(height: 10),
                        Text('Last update: $lastUpdatedLabel', style: const TextStyle(fontSize: 12, color: Colors.black38)),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom action area: change according to status
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildBottomArea(context, status),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomArea(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return Row(
          children: [
            Expanded(child: ElevatedButton(onPressed: null, child: const Text('Waiting for driver'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700))),
          ],
        );
      case 'accepted':
        return Row(
          children: [
            Expanded(child: ElevatedButton(onPressed: null, child: const Text('Driver accepted — coming'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700))),
          ],
        );
      case 'arriving':
        return Row(
          children: [
            Expanded(child: ElevatedButton(onPressed: null, child: const Text('Driver has arrived'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700))),
          ],
        );
      case 'on_trip':
        return Row(
          children: [
            Expanded(child: ElevatedButton(onPressed: null, child: const Text('Trip in progress'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700))),
          ],
        );
      case 'reached':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: const [
                  Text('Driver has reached the destination', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  SizedBox(height: 6),
                  Text('Please confirm arrival and complete the ride.', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // You can wire this to a confirm-completion API: for now update the booking doc
                FirebaseFirestore.instance.collection('rideBookings').doc(bookingId).set({'status': 'completed'}, SetOptions(merge: true));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as completed')));
              },
              child: const Text('Confirm & Complete'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
            ),
          ],
        );
      case 'completed':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: const [
                  Text('Ride completed', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  SizedBox(height: 6),
                  Text('Thank you for riding with us.', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      case 'cancelled':
        return Row(
          children: [
            Expanded(child: ElevatedButton(onPressed: null, child: const Text('Booking cancelled'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700))),
          ],
        );
      default:
        return Row(
          children: [
            Expanded(child: ElevatedButton(onPressed: null, child: const Text('Status unknown'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey))),
          ],
        );
    }
  }

  static String _statusHeadline(String status) {
    switch (status) {
      case 'pending':
        return 'Waiting for driver to accept your booking';
      case 'accepted':
        return 'Driver accepted — heading to pickup';
      case 'arriving':
        return 'Driver is nearby — prepare to board';
      case 'on_trip':
        return 'Trip in progress';
      case 'reached':
        return 'Driver reached the destination';
      case 'completed':
        return 'Ride completed';
      case 'cancelled':
        return 'Booking was cancelled';
      default:
        return 'Status: $status';
    }
  }

  Widget _centerMessage(String text) => Center(child: Text(text));
}

// small helper classes for the stepper
class _StepDef {
  final String key;
  final String label;
  const _StepDef({required this.key, required this.label});
}

class _HorizontalStepper extends StatelessWidget {
  final List<_StepDef> steps;
  final int activeIndex;
  const _HorizontalStepper({super.key, required this.steps, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isEven) {
            final idx = i ~/ 2;
            final step = steps[idx];
            final bool isActive = idx == activeIndex;
            final bool isComplete = idx < activeIndex;
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: isActive ? 34 : 28,
                    height: isActive ? 34 : 28,
                    decoration: BoxDecoration(
                      color: isActive ? kPrimaryColor : (isComplete ? Colors.green : Colors.grey.shade300),
                      shape: BoxShape.circle,
                      boxShadow: isActive ? [BoxShadow(color: kPrimaryColor.withOpacity(0.2), blurRadius: 6)] : null,
                    ),
                    child: Center(
                      child: Icon(
                        _iconForStep(step.key),
                        size: isActive ? 18 : 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.label,
                    style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w800 : FontWeight.w600, color: isActive ? Colors.black87 : Colors.black54),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            );
          } else {
            final leftIdx = (i - 1) ~/ 2;
            final bool isPassed = leftIdx < activeIndex;
            return SizedBox(
              width: 12,
              child: Center(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isPassed ? Colors.green : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          }
        }),
      ),
    );
  }

  static IconData _iconForStep(String key) {
    switch (key) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check;
      case 'arriving':
        return Icons.location_on;
      case 'on_trip':
        return Icons.directions_car;
      case 'reached':
        return Icons.flag;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.circle;
    }
  }
}
