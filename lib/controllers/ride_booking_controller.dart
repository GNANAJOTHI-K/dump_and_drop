// lib/controllers/ride_booking_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RideBookingController extends GetxController {
  final leavingFrom = ''.obs;
  final goingTo = ''.obs;
  final selectedDate = Rxn<DateTime>();
  final passengers = 1.obs;

  final pickupLat = Rxn<double>();
  final pickupLng = Rxn<double>();
  final dropLat = Rxn<double>();
  final dropLng = Rxn<double>();

  final isSaving = false.obs;

  void setPickup(Map<String, dynamic> result) {
    leavingFrom.value = result['label'] as String? ?? '';
    pickupLat.value = (result['lat'] is num) ? (result['lat'] as num).toDouble() : result['lat'] as double?;
    pickupLng.value = (result['lng'] is num) ? (result['lng'] as num).toDouble() : result['lng'] as double?;
  }

  void setDrop(Map<String, dynamic> result) {
    goingTo.value = result['label'] as String? ?? '';
    dropLat.value = (result['lat'] is num) ? (result['lat'] as num).toDouble() : result['lat'] as double?;
    dropLng.value = (result['lng'] is num) ? (result['lng'] as num).toDouble() : result['lng'] as double?;
  }

  void setDate(DateTime d) {
    selectedDate.value = d;
  }

  void incrementPassengers() => passengers.value++;
  void decrementPassengers() {
    if (passengers.value > 1) passengers.value--;
  }

  /// navigatorCallback receives the created bookingId (or null on failure)
  /// Saves booking to top-level collection: rideBookings/{bookingId}
  Future<void> bookRide(Future<void> Function(String? bookingId) navigatorCallback) async {
    if (leavingFrom.value.isEmpty ||
        goingTo.value.isEmpty ||
        pickupLat.value == null ||
        pickupLng.value == null ||
        dropLat.value == null ||
        dropLng.value == null) {
      throw Exception('Select pickup and drop locations');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    isSaving.value = true;
    String? bookingId;
    try {
      // Use a top-level collection so bookings are easy to query across users:
      final bookingsRef = FirebaseFirestore.instance.collection('rideBookings');

      // fetch customer details (name/phone) if available
      String? customerName;
      String? customerPhone;
      try {
        final custSnap = await FirebaseFirestore.instance.collection('customers').doc(user.uid).get();
        if (custSnap.exists) {
          final cdata = custSnap.data();
          if (cdata != null) {
            customerName = (cdata['name'] ?? cdata['fullName'])?.toString();
            customerPhone = (cdata['mobile'] ?? cdata['phone'] ?? '')?.toString();
          }
        }
      } catch (_) {
        // ignore fetch errors; not critical
      }

      // booking-level document (top-level)
      final bookingData = <String, dynamic>{
        'customerId': user.uid,
        'customerName': customerName ?? '',
        'customerPhone': customerPhone ?? '',
        'pickupLabel': leavingFrom.value,
        'pickupLat': pickupLat.value,
        'pickupLng': pickupLng.value,
        'dropLabel': goingTo.value,
        'dropLat': dropLat.value,
        'dropLng': dropLng.value,
        'passengers': passengers.value,
        'service': 'ride',
        'status': 'pending',
        'rideDate': selectedDate.value != null ? Timestamp.fromDate(selectedDate.value!) : null,
        'serviceCreated': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Create top-level booking doc
      final bookingDocRef = await bookingsRef.add(bookingData);
      bookingId = bookingDocRef.id;

      // service subdocument under rideBookings/{bookingId}/service/{serviceDocId}
      final serviceData = <String, dynamic>{
        'serviceType': 'ride',
        'status': 'pending',
        'pickup': leavingFrom.value,
        'pickupLat': pickupLat.value,
        'pickupLng': pickupLng.value,
        'drop': goingTo.value,
        'dropLat': dropLat.value,
        'dropLng': dropLng.value,
        'passengers': passengers.value,
        'customerId': user.uid,
        'bookingId': bookingDocRef.id,
        'customerName': customerName ?? '',
        'estimatedFare': null,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await bookingDocRef.collection('service').add(serviceData);

      // mark serviceCreated flag
      await bookingDocRef.set({'serviceCreated': true}, SetOptions(merge: true));

      // call callback with bookingId
      await navigatorCallback(bookingId);
    } catch (e) {
      // on error, inform callback with null so UI can fallback
      try {
        await navigatorCallback(null);
      } catch (_) {}
      rethrow;
    } finally {
      isSaving.value = false;
    }
  }
}
