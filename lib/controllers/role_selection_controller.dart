import 'package:get/get.dart';

import '../role_selection_screen.dart';

class RoleSelectionController extends GetxController {
  final selectedRole = Rxn<UserRole>();

  void select(UserRole role) => selectedRole.value = role;
}
