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
    pickupLat.value = result['lat'] as double?;
    pickupLng.value = result['lng'] as double?;
  }

  void setDrop(Map<String, dynamic> result) {
    goingTo.value = result['label'] as String? ?? '';
    dropLat.value = result['lat'] as double?;
    dropLng.value = result['lng'] as double?;
  }

  void setDate(DateTime d) {
    selectedDate.value = d;
  }

  void incrementPassengers() => passengers.value++;
  void decrementPassengers() {
    if (passengers.value > 1) passengers.value--;
  }

  Future<void> bookRide(Future<void> Function() navigatorCallback) async {
    if (leavingFrom.value.isEmpty || goingTo.value.isEmpty || pickupLat.value == null || pickupLng.value == null || dropLat.value == null || dropLng.value == null) {
      throw Exception('Select pickup and drop locations');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    isSaving.value = true;
    try {
      final bookingsRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .collection('bookings');

      await bookingsRef.add({
        'customerId': user.uid,
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
        'createdAt': FieldValue.serverTimestamp(),
      });

      // call navigator callback for navigation
      await navigatorCallback();
    } finally {
      isSaving.value = false;
    }
  }
}
