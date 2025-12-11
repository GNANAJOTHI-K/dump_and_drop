import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoodsDeliveryController extends GetxController {
  final pickupAddress = ''.obs;
  final dropAddress = ''.obs;
  final selectedDate = Rxn<DateTime>();
  final packageWeight = 1.0.obs;
  final packageCategory = 'Documents'.obs;
  final vehicleType = 'Bike'.obs;
  final specialInstructions = ''.obs;

  final pickupLat = Rxn<double>();
  final pickupLng = Rxn<double>();
  final dropLat = Rxn<double>();
  final dropLng = Rxn<double>();

  final isSaving = false.obs;

  void setPickup(Map<String, dynamic> result) {
    pickupAddress.value = result['label'] as String? ?? '';
    pickupLat.value = result['lat'] as double?;
    pickupLng.value = result['lng'] as double?;
  }

  void setDrop(Map<String, dynamic> result) {
    dropAddress.value = result['label'] as String? ?? '';
    dropLat.value = result['lat'] as double?;
    dropLng.value = result['lng'] as double?;
  }

  void setDate(DateTime d) => selectedDate.value = d;
  void setWeight(double w) => packageWeight.value = w;
  void setCategory(String c) => packageCategory.value = c;
  void setVehicle(String v) => vehicleType.value = v;
  void setInstructions(String s) => specialInstructions.value = s;

  Future<void> bookDelivery(Future<void> Function() navigatorCallback) async {
    if (pickupAddress.value.isEmpty || dropAddress.value.isEmpty || pickupLat.value == null || pickupLng.value == null || dropLat.value == null || dropLng.value == null) {
      throw Exception('Select pickup and drop locations');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    isSaving.value = true;
    try {
      final bookingsRef = FirebaseFirestore.instance.collection('customers').doc(user.uid).collection('bookings');
      await bookingsRef.add({
        'customerId': user.uid,
        'pickupLabel': pickupAddress.value,
        'pickupLat': pickupLat.value,
        'pickupLng': pickupLng.value,
        'dropLabel': dropAddress.value,
        'dropLat': dropLat.value,
        'dropLng': dropLng.value,
        'service': 'goods',
        'status': 'pending',
        'pickupDate': selectedDate.value != null ? Timestamp.fromDate(selectedDate.value!) : null,
        'packageWeight': packageWeight.value,
        'packageCategory': packageCategory.value,
        'vehicleType': vehicleType.value,
        'specialInstructions': specialInstructions.value,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await navigatorCallback();
    } finally {
      isSaving.value = false;
    }
  }
}
