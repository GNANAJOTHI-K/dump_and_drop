// lib/customer_detail_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'controllers/customer_detail_controller.dart';

const Color kPrimaryColor = Color(0xFF446FA8);
const Color kFieldBg = Color(0xFFF5F7FB);

class CustomerDetailPage extends StatefulWidget {
  final String userUid;
  final String userEmail;
  final bool isNewUser;

  const CustomerDetailPage({
    super.key,
    required this.userUid,
    required this.userEmail,
    required this.isNewUser,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final _basicFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  /// Controls which "screen" is visible: false => basic info, true => set password
  bool _showPasswordStep = false;

  /// Whether user changed any field compared to loaded values
  bool _hasChanges = false;

  /// initial values loaded (from controller or prefs)
  Map<String, String> _initialValues = {
    'name': '',
    'dob': '',
    'mobile': '',
    'email': '',
  };

  final CustomerDetailController _ctrl = Get.put(CustomerDetailController());

  // SharedPrefs keys
  static const String _prefPrefix = 'customer_details_';
  static const String _prefName = '${_prefPrefix}name';
  static const String _prefDob = '${_prefPrefix}dob';
  static const String _prefMobile = '${_prefPrefix}mobile';
  static const String _prefEmail = '${_prefPrefix}email';
  static const String _prefStep = '${_prefPrefix}step_passwordShown';

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.userEmail;
    _attachListeners();
    _loadPersistedAndExisting();
  }

  void _attachListeners() {
    _nameController.addListener(_onFieldChanged);
    _dobController.addListener(_onFieldChanged);
    _mobileController.addListener(_onFieldChanged);
    // email is readOnly but keep listener if changed programmatically
    _emailController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final changed = _nameController.text.trim() != (_initialValues['name'] ?? '') ||
        _dobController.text.trim() != (_initialValues['dob'] ?? '') ||
        _mobileController.text.trim() != (_initialValues['mobile'] ?? '') ||
        _emailController.text.trim() != (_initialValues['email'] ?? '');

    if (changed != _hasChanges) {
      setState(() {
        _hasChanges = changed;
      });
    }

    // persist progress locally every time a field changes
    _persistProgress();
  }

  Future<void> _loadPersistedAndExisting() async {
    final prefs = await SharedPreferences.getInstance();

    // load persisted values first
    final persistedName = prefs.getString(_prefName) ?? '';
    final persistedDob = prefs.getString(_prefDob) ?? '';
    final persistedMobile = prefs.getString(_prefMobile) ?? '';
    final persistedEmail = prefs.getString(_prefEmail) ?? '';
    final persistedStep = prefs.getBool(_prefStep) ?? false;

    // load existing data from controller (remote / firestore)
    final data = await _ctrl.loadExistingData(widget.userUid);

    // merge order: persisted (highest), otherwise controller data, otherwise fallback
    final name = persistedName.isNotEmpty ? persistedName : (data['name'] ?? '');
    final dob = persistedDob.isNotEmpty ? persistedDob : (data['dob'] ?? '');
    final mobile = persistedMobile.isNotEmpty ? persistedMobile : (data['mobile'] ?? '');
    final email = persistedEmail.isNotEmpty
        ? persistedEmail
        : (data['email'] != '' ? data['email']! : widget.userEmail);

    // set controllers and initial values
    setState(() {
      _nameController.text = name;
      _dobController.text = dob;
      _mobileController.text = mobile;
      _emailController.text = email;
      _initialValues = {
        'name': name,
        'dob': dob,
        'mobile': mobile,
        'email': email,
      };
      _showPasswordStep = persistedStep || _ctrl.basicSaved.value;
      // set hasChanges false because these are considered loaded baseline
      _hasChanges = false;
    });
  }

  Future<void> _persistProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefName, _nameController.text.trim());
    await prefs.setString(_prefDob, _dobController.text.trim());
    await prefs.setString(_prefMobile, _mobileController.text.trim());
    await prefs.setString(_prefEmail, _emailController.text.trim());
    await prefs.setBool(_prefStep, _showPasswordStep);
  }

  /// Save basic info. If controller update sets basicSaved, switch to password step.
  Future<void> _saveBasicInfo() async {
    if (!_basicFormKey.currentState!.validate()) return;

    await _ctrl.saveBasicInfo(widget.userUid, {
      'name': _nameController.text.trim(),
      'dob': _dobController.text.trim(),
      'mobile': _mobileController.text.trim(),
      'email': _emailController.text.trim(),
    }, context);

    // Move to next step only if controller indicates basicSaved true
    if (_ctrl.basicSaved.value == true) {
      setState(() {
        _showPasswordStep = true;
      });
      await _persistProgress();
      // update initial values so save button is disabled if user returns
      _initialValues = {
        'name': _nameController.text.trim(),
        'dob': _dobController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'email': _emailController.text.trim(),
      };
      setState(() => _hasChanges = false);
    }
  }

  Future<void> _savePasswordAndFinish() async {
    if (!_ctrl.basicSaved.value && !_showPasswordStep) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save basic details first')),
      );
      return;
    }

    if (!_passwordFormKey.currentState!.validate()) return;

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    await _ctrl.savePasswordAndFinish(
      uid: widget.userUid,
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      profileValues: {
        'name': _nameController.text.trim(),
        'dob': _dobController.text.trim(),
        'mobile': _mobileController.text.trim(),
      },
      context: context,
    );

    // If finish succeeded, clear persisted progress for safety.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefName);
    await prefs.remove(_prefDob);
    await prefs.remove(_prefMobile);
    await prefs.remove(_prefEmail);
    await prefs.remove(_prefStep);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Button style that ensures white text even when disabled
  ButtonStyle _primaryButtonStyle(Color bgColor) {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled)) {
          return Colors.grey.shade400;
        }
        return bgColor;
      }),
      foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F7),
      appBar: AppBar(
        title: const Text("Customer Details"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        // show back only when on password step
        leading: _showPasswordStep
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () {
                  // go back to basic info
                  setState(() => _showPasswordStep = false);
                  _persistProgress();
                },
              )
            : null,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            final inAnim = SlideTransition(
                position:
                    Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                        .animate(animation),
                child: child);
            return inAnim;
          },
          child: _showPasswordStep ? _buildPasswordScreen(context) : _buildBasicInfoScreen(context),
        ),
      ),
    );
  }

  // ---------------------------
  // BASIC INFO SCREEN (STEP 1)
  // ---------------------------
  Widget _buildBasicInfoScreen(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      key: const ValueKey('basic_screen'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeaderSimple(Icons.person, "Basic information"),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(top: 4, bottom: 20),
            decoration: _boxDecoration(),
            child: Form(
              key: _basicFormKey,
              child: Column(
                children: [
                  _label("Full name", required: true),
                  _inputField(
                    controller: _nameController,
                    validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),

                  _label("Date of birth", required: true),
                  // readOnly DOB with onTap
                  TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    onTap: () => _pickDob(context),
                    validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                    decoration: InputDecoration(
                      hintText: "DD/MM/YYYY",
                      filled: true,
                      fillColor: kFieldBg,
                      border: _border(),
                      enabledBorder: _border(),
                      focusedBorder: _border(kPrimaryColor),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _label("Mobile number", required: true),
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                      PhoneNumberFormatter(), // custom formatter
                    ],
                    decoration: InputDecoration(
                      hintText: "12345 67890",
                      filled: true,
                      fillColor: kFieldBg,
                      border: _border(),
                      enabledBorder: _border(),
                      focusedBorder: _border(kPrimaryColor),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    ),
                    validator: (v) {
                      final digitsOnly = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                      return digitsOnly.length == 10 ? null : "Enter valid number";
                    },
                  ),
                  const SizedBox(height: 12),

                  _label("Email"),
                  _inputField(
                    controller: _emailController,
                    readOnly: true,
                  ),

                  const SizedBox(height: 18),
                  Obx(() {
                    final loading = _ctrl.isLoading.value;
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (!loading && _hasChanges) ? _saveBasicInfo : null,
                        style: _primaryButtonStyle(kPrimaryColor),
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Text(
                                "Save & Continue",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          SizedBox(height: h * 0.02),
          // small hint showing user can go to password only after save
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _ctrl.basicSaved.value
                      ? "Basic details saved — you can proceed to set password."
                      : _hasChanges
                          ? "You have unsaved changes. Tap 'Save & Continue' to proceed."
                          : "No changes yet — edit the fields to enable Save.",
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ---------------------------
  // PASSWORD SCREEN (STEP 2)
  // ---------------------------
  Widget _buildPasswordScreen(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('password_screen'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeaderSimple(Icons.lock, "Set password"),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(top: 4),
            decoration: _boxDecoration(),
            child: Form(
              key: _passwordFormKey,
              child: Column(
                children: [
                  _label("Password", required: true),
                  _passwordField(
                    controller: _passwordController,
                    visible: _passwordVisible,
                    onToggle: () {
                      setState(() => _passwordVisible = !_passwordVisible);
                    },
                  ),
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "• Minimum 6 characters\n• Use letters and numbers",
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label("Confirm password", required: true),
                  _passwordField(
                    controller: _confirmPasswordController,
                    visible: _confirmPasswordVisible,
                    onToggle: () {
                      setState(() => _confirmPasswordVisible = !_confirmPasswordVisible);
                    },
                  ),
                  const SizedBox(height: 22),
                  Obx(() {
                    final loading = _ctrl.isLoading.value;
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : _savePasswordAndFinish,
                        style: _primaryButtonStyle(kPrimaryColor),
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Text(
                                "Finish",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // -------------------------------
  // UI WIDGETS
  // -------------------------------

  /// Minimal header: single icon + title (keeps UI clean)
  Widget _sectionHeaderSimple(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          blurRadius: 10,
          color: Colors.black12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        if (required) const Text("*", style: TextStyle(color: Colors.red, fontSize: 18)),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
    bool readOnly = false,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: validator,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: kFieldBg,
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(kPrimaryColor),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator: (v) => v != null && v.trim().length >= 6 ? null : "Minimum 6 characters",
      decoration: InputDecoration(
        filled: true,
        fillColor: kFieldBg,
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(kPrimaryColor),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
          onPressed: onToggle,
        ),
      ),
    );
  }

  OutlineInputBorder _border([Color color = Colors.transparent]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 1.3),
    );
  }

  // Opens a date picker and writes DD/MM/YYYY to controller
  Future<void> _pickDob(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    // if existing dob parse it
    final existing = _dobController.text.trim();
    if (existing.isNotEmpty) {
      try {
        final parts = existing.split('/');
        if (parts.length == 3) {
          final d = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final y = int.parse(parts[2]);
          // ensure valid date values
          if (y > 1900 && y <= DateTime.now().year) {
            initialDate = DateTime(y, m.clamp(1, 12), d.clamp(1, 31));
          }
        }
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final formatted = _formatDate(picked);
      setState(() {
        _dobController.text = formatted;
      });
      _persistProgress();
    }
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }
}

/// Custom TextInputFormatter to format 10-digit mobile as "##### #####"
class PhoneNumberFormatter extends TextInputFormatter {
  // Takes only digits (assume FilteringTextInputFormatter.digitsOnly applied earlier)
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 10; i++) {
      buffer.write(digits[i]);
      if (i == 4 && i != digits.length - 1) {
        buffer.write(' ');
      }
    }
    final formatted = buffer.toString();
    // compute new selection offset
    int selectionIndex = formatted.length;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
