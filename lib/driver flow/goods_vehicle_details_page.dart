import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF446FA8);
const Color kFieldBg = Color(0xFFF5F7FB);

class GoodsVehicleDetailsPage extends StatefulWidget {
  const GoodsVehicleDetailsPage({super.key});

  @override
  State<GoodsVehicleDetailsPage> createState() =>
      _GoodsVehicleDetailsPageState();
}

class _GoodsVehicleDetailsPageState extends State<GoodsVehicleDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0; // 0..4

  // SECTION 1 – Owner identity
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _firmNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _altPhoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  // SECTION 2 – Address & emergency contact
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  // SECTION 3 – Govt ID + Permit
  String? _idType; // Aadhaar / PAN / GST
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();
  final TextEditingController _permitNumberController = TextEditingController();
  final TextEditingController _permitExpiryController = TextEditingController();

  // SECTION 4 – Vehicle basic details
  String? _vehicleCategory; // Pickup / Mini-truck / LCV / etc.
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _regNumberController = TextEditingController();
  final TextEditingController _loadCapacityController = TextEditingController();

  // SECTION 5 – Vehicle documents
  final TextEditingController _rcNumberController = TextEditingController();
  final TextEditingController _insuranceNumberController =
      TextEditingController();
  final TextEditingController _insuranceExpiryController =
      TextEditingController();
  final TextEditingController _pucExpiryController = TextEditingController();

  @override
  void dispose() {
    _ownerNameController.dispose();
    _firmNameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _idNumberController.dispose();
    _gstNumberController.dispose();
    _permitNumberController.dispose();
    _permitExpiryController.dispose();
    _vehicleTypeController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _regNumberController.dispose();
    _loadCapacityController.dispose();
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
    if (_currentStep < 4) {
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
    }
  }

  void _onSubmitAll() {
    final data = {
      "ownerName": _ownerNameController.text.trim(),
      "firmName": _firmNameController.text.trim(),
      "phone": _phoneController.text.trim(),
      "altPhone": _altPhoneController.text.trim(),
      "city": _cityController.text.trim(),
      "address": _addressController.text.trim(),
      "pincode": _pincodeController.text.trim(),
      "emergencyName": _emergencyNameController.text.trim(),
      "emergencyPhone": _emergencyPhoneController.text.trim(),
      "idType": _idType,
      "idNumber": _idNumberController.text.trim(),
      "gstNumber": _gstNumberController.text.trim(),
      "permitNumber": _permitNumberController.text.trim(),
      "permitExpiry": _permitExpiryController.text.trim(),
      "vehicleCategory": _vehicleCategory,
      "vehicleType": _vehicleTypeController.text.trim(),
      "brand": _brandController.text.trim(),
      "model": _modelController.text.trim(),
      "year": _yearController.text.trim(),
      "regNumber": _regNumberController.text.trim(),
      "loadCapacity": _loadCapacityController.text.trim(),
      "rcNumber": _rcNumberController.text.trim(),
      "insuranceNumber": _insuranceNumberController.text.trim(),
      "insuranceExpiry": _insuranceExpiryController.text.trim(),
      "pucExpiry": _pucExpiryController.text.trim(),
    };

    debugPrint("FINAL GOODS VEHICLE KYC DATA: $data");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Goods vehicle details captured (API pending)")),
    );
  }

  String _stepTitle() {
    switch (_currentStep) {
      case 0:
        return "Owner identity";
      case 1:
        return "Address & emergency contact";
      case 2:
        return "ID, GST & permits";
      case 3:
        return "Vehicle basic details";
      case 4:
        return "Vehicle documents";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentStep == 4;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Goods vehicle setup"),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Step indicator
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      "Step ${_currentStep + 1} of 5",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        5,
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildOwnerIdentitySection();
      case 1:
        return _buildAddressEmergencySection();
      case 2:
        return _buildIdGstPermitSection();
      case 3:
        return _buildVehicleBasicSection();
      case 4:
        return _buildVehicleDocsSection();
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------- Section UIs ---------- //

  Widget _buildOwnerIdentitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _ownerNameController,
          decoration: _inputDecoration("Owner name"),
          validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _firmNameController,
          decoration:
              _inputDecoration("Firm / company name (optional)"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          decoration: _inputDecoration("Primary mobile number"),
          keyboardType: TextInputType.phone,
          validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _altPhoneController,
          decoration:
              _inputDecoration("Alternate mobile number (optional)"),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cityController,
          decoration: _inputDecoration("Operating city"),
        ),
      ],
    );
  }

  Widget _buildAddressEmergencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _addressController,
          decoration: _inputDecoration("Full address"),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _pincodeController,
          decoration: _inputDecoration("Pincode"),
          keyboardType: TextInputType.number,
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
          decoration: _inputDecoration("Contact number"),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildIdGstPermitSection() {
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
        const SizedBox(height: 10),
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
        const SizedBox(height: 20),
        TextFormField(
          controller: _gstNumberController,
          decoration:
              _inputDecoration("GST number (optional, for firm)"),
        ),
        const SizedBox(height: 20),
        const Text(
          "Goods permit",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _permitNumberController,
          decoration: _inputDecoration("Permit number"),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _permitExpiryController,
          decoration:
              _inputDecoration("Permit expiry date", hint: "DD/MM/YYYY"),
        ),
        const SizedBox(height: 10),
        _DocumentUploadTile(
          label: "Upload permit photo",
          onTap: () => _onPickDocument("Permit"),
        ),
      ],
    );
  }

  Widget _buildVehicleBasicSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _vehicleCategory,
          decoration: _inputDecoration("Vehicle category"),
          items: const [
            DropdownMenuItem(value: "Pickup", child: Text("Pickup")),
            DropdownMenuItem(value: "Mini-truck", child: Text("Mini-truck")),
            DropdownMenuItem(value: "LCV", child: Text("LCV")),
            DropdownMenuItem(value: "Truck", child: Text("Truck")),
          ],
          onChanged: (val) => setState(() => _vehicleCategory = val),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _vehicleTypeController,
          decoration:
              _inputDecoration("Vehicle body type (open/closed, etc.)"),
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
                decoration: _inputDecoration("Year"),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _loadCapacityController,
                decoration:
                    _inputDecoration("Load capacity (kg / ton)"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _regNumberController,
          decoration: _inputDecoration("Registration number"),
        ),
      ],
    );
  }

  Widget _buildVehicleDocsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
