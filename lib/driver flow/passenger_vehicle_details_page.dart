import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF446FA8);
const Color kFieldBg = Color(0xFFF5F7FB);

class PassengerVehicleDetailsPage extends StatefulWidget {
  const PassengerVehicleDetailsPage({super.key});

  @override
  State<PassengerVehicleDetailsPage> createState() =>
      _PassengerVehicleDetailsPageState();
}

class _PassengerVehicleDetailsPageState
    extends State<PassengerVehicleDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0; // 0..3 (4 sections)

  // SECTION 1 – Driver Identity
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // SECTION 2 – Address + Emergency
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  // SECTION 3 – Govt ID + Driving License
  String? _idType; // Aadhaar / PAN / Passport
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _dlNumberController = TextEditingController();
  final TextEditingController _dlValidFromController = TextEditingController();
  final TextEditingController _dlValidToController = TextEditingController();

  // SECTION 4 – Capacity & Vehicle docs (includes basic details)
  String? _seatCapacity;
  bool _isAC = true;

  String? _vehicleType; // Car / Van / SUV
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _regNumberController = TextEditingController();

  final TextEditingController _rcNumberController = TextEditingController();
  final TextEditingController _insuranceNumberController =
      TextEditingController();
  final TextEditingController _insuranceExpiryController =
      TextEditingController();
  final TextEditingController _pucExpiryController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _idNumberController.dispose();
    _dlNumberController.dispose();
    _dlValidFromController.dispose();
    _dlValidToController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _regNumberController.dispose();
    _rcNumberController.dispose();
    _insuranceNumberController.dispose();
    _insuranceExpiryController.dispose();
    _pucExpiryController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: kFieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1.4),
      ),
    );
  }

  void _onPickDocument(String docName) {
    debugPrint("Pick image for: $docName");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Photo picker for $docName (to be implemented)")),
    );
  }

  void _onNextStep() {
    if (!_formKey.currentState!.validate()) return;

    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    } else {
      _onSubmitAll();
    }
  }

  void _onPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context); // back from whole flow
    }
  }

  void _onSubmitAll() {
    final data = {
      "fullName": _fullNameController.text.trim(),
      "dob": _dobController.text.trim(),
      "phone": _phoneController.text.trim(),
      "password": _passwordController.text.trim(),
      "address": _addressController.text.trim(),
      "pincode": _pincodeController.text.trim(),
      "emergencyName": _emergencyNameController.text.trim(),
      "emergencyPhone": _emergencyPhoneController.text.trim(),
      "idType": _idType,
      "idNumber": _idNumberController.text.trim(),
      "dlNumber": _dlNumberController.text.trim(),
      "dlValidFrom": _dlValidFromController.text.trim(),
      "dlValidTo": _dlValidToController.text.trim(),
      "seatCapacity": _seatCapacity,
      "isAC": _isAC,
      "vehicleType": _vehicleType,
      "brand": _brandController.text.trim(),
      "model": _modelController.text.trim(),
      "year": _yearController.text.trim(),
      "color": _colorController.text.trim(),
      "regNumber": _regNumberController.text.trim(),
      "rcNumber": _rcNumberController.text.trim(),
      "insuranceNumber": _insuranceNumberController.text.trim(),
      "insuranceExpiry": _insuranceExpiryController.text.trim(),
      "pucExpiry": _pucExpiryController.text.trim(),
    };

    debugPrint("FINAL PASSENGER VEHICLE DATA: $data");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All details captured (API pending)")),
    );
  }

  String _stepTitle() {
    switch (_currentStep) {
      case 0:
        return "Driver identity";
      case 1:
        return "Address & emergency contact";
      case 2:
        return "ID & driving licence";
      case 3:
        return "Vehicle capacity & documents";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentStep == 3;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Passenger vehicle setup"),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onPreviousStep,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      "Step ${_currentStep + 1} of 4",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        4,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index <= _currentStep
                                ? kPrimaryColor
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _stepTitle(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),
              const Divider(height: 1),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 12.0),
                  child: _buildStepContent(),
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom buttons
      bottomNavigationBar: SafeArea(
        minimum:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _onPreviousStep,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("Back"),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _onNextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text(isLastStep ? "Submit details" : "Save & continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- STEP CONTENTS ---------- //

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDriverIdentitySection();
      case 1:
        return _buildAddressEmergencySection();
      case 2:
        return _buildIdAndDLSection();
      case 3:
        return _buildCapacityAndDocsSection();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1 – Identity
  Widget _buildDriverIdentitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _fullNameController,
          decoration: _inputDecoration("Full name"),
          validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _dobController,
          decoration: _inputDecoration("Date of birth", hint: "DD/MM/YYYY"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration("Mobile number"),
          validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: _inputDecoration("Password"),
          validator: (v) =>
              v == null || v.trim().length < 6 ? "Min 6 characters" : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: _inputDecoration("Confirm password"),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return "Required";
            if (v.trim() != _passwordController.text.trim()) {
              return "Passwords do not match";
            }
            return null;
          },
        ),
      ],
    );
  }

  // STEP 2 – Address & emergency
  Widget _buildAddressEmergencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _addressController,
          decoration: _inputDecoration("Address"),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _pincodeController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration("Pincode"),
        ),
        const SizedBox(height: 20),
        const Text(
          "Emergency contact",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _emergencyNameController,
          decoration: _inputDecoration("Contact name"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emergencyPhoneController,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration("Contact number"),
        ),
      ],
    );
  }

  // STEP 3 – ID & DL
  Widget _buildIdAndDLSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _idType,
          decoration: _inputDecoration("ID proof type"),
          items: const [
            DropdownMenuItem(value: "Aadhaar", child: Text("Aadhaar")),
            DropdownMenuItem(value: "PAN", child: Text("PAN card")),
            DropdownMenuItem(value: "Passport", child: Text("Passport")),
          ],
          onChanged: (val) => setState(() => _idType = val),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _idNumberController,
          decoration: _inputDecoration("ID proof number"),
        ),
        const SizedBox(height: 12),
        Text(
          "ID proof photos",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DocumentUploadTile(
                label: "ID front photo",
                onTap: () => _onPickDocument("ID front"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DocumentUploadTile(
                label: "ID back photo",
                onTap: () => _onPickDocument("ID back"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          "Driving licence",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _dlNumberController,
          decoration: _inputDecoration("Licence number"),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _dlValidFromController,
                decoration:
                    _inputDecoration("Valid from", hint: "DD/MM/YYYY"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _dlValidToController,
                decoration: _inputDecoration("Valid to", hint: "DD/MM/YYYY"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "Licence photos",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DocumentUploadTile(
                label: "Licence front",
                onTap: () => _onPickDocument("Licence front"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DocumentUploadTile(
                label: "Licence back",
                onTap: () => _onPickDocument("Licence back"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 4 – Capacity & docs (includes basic vehicle info)
  Widget _buildCapacityAndDocsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _seatCapacity,
          decoration: _inputDecoration("Seating capacity"),
          items: const [
            DropdownMenuItem(value: "4", child: Text("4 seats")),
            DropdownMenuItem(value: "5", child: Text("5 seats")),
            DropdownMenuItem(value: "6", child: Text("6 seats")),
            DropdownMenuItem(value: "7", child: Text("7+ seats")),
          ],
          onChanged: (val) => setState(() => _seatCapacity = val),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: _isAC,
          onChanged: (val) => setState(() => _isAC = val),
          contentPadding: EdgeInsets.zero,
          activeColor: kPrimaryColor,
          title: const Text("Air-conditioned vehicle"),
        ),
        const SizedBox(height: 16),

        // Vehicle basic fields moved here
        DropdownButtonFormField<String>(
          value: _vehicleType,
          decoration: _inputDecoration("Vehicle type"),
          items: const [
            DropdownMenuItem(value: "Car", child: Text("Car")),
            DropdownMenuItem(value: "Van", child: Text("Van")),
            DropdownMenuItem(value: "SUV", child: Text("SUV")),
          ],
          onChanged: (val) => setState(() => _vehicleType = val),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _brandController,
                decoration: _inputDecoration("Brand"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _modelController,
                decoration: _inputDecoration("Model"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Year"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _colorController,
                decoration: _inputDecoration("Colour"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _regNumberController,
          decoration: _inputDecoration("Registration number"),
        ),
        const SizedBox(height: 24),

        const Text(
          "Vehicle documents",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),

        TextFormField(
          controller: _rcNumberController,
          decoration: _inputDecoration("RC (Registration) number"),
        ),
        const SizedBox(height: 10),
        _DocumentUploadTile(
          label: "Upload RC photo",
          onTap: () => _onPickDocument("RC"),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _insuranceNumberController,
          decoration: _inputDecoration("Insurance policy number"),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _insuranceExpiryController,
          decoration:
              _inputDecoration("Insurance expiry date", hint: "DD/MM/YYYY"),
        ),
        const SizedBox(height: 10),
        _DocumentUploadTile(
          label: "Upload insurance photo",
          onTap: () => _onPickDocument("Insurance"),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _pucExpiryController,
          decoration:
              _inputDecoration("PUC expiry date", hint: "DD/MM/YYYY"),
        ),
        const SizedBox(height: 10),
        _DocumentUploadTile(
          label: "Upload PUC photo",
          onTap: () => _onPickDocument("PUC"),
        ),

        const SizedBox(height: 16),
        _DocumentUploadTile(
          label: "Upload vehicle photo",
          onTap: () => _onPickDocument("Vehicle"),
        ),
      ],
    );
  }
}

// Reusable upload tile
class _DocumentUploadTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DocumentUploadTile({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: kFieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.upload_file, size: 22, color: kPrimaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}
