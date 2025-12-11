import 'package:get/get.dart';

class HomeController extends GetxController {
  final currentIndex = 0.obs;
  final selectedService = ''.obs;

  void selectService(String s) => selectedService.value = s;
  void setIndex(int i) => currentIndex.value = i;
}
