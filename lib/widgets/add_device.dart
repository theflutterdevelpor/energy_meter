import 'dart:convert';
import 'package:energy_meter/widgets/qr_scnner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bottom_nav_bar/home_nav_bar.dart';
import '../models/request/billing_request.dart';
import '../models/response/device_response.dart';
import '../services/billing_service.dart';
import '../services/device_service.dart';


class UnitSlab {
  TextEditingController fromCtrl = TextEditingController();
  TextEditingController toCtrl   = TextEditingController();
  TextEditingController priceCtrl= TextEditingController();

  void dispose() {
    fromCtrl.dispose();
    toCtrl.dispose();
    priceCtrl.dispose();
  }
}

class DeviceReadingForm extends StatefulWidget {
  final bool showBackButton;
  const DeviceReadingForm({super.key, this.showBackButton = false});

  @override
  State<DeviceReadingForm> createState() => _DeviceReadingFormState();
}

class _DeviceReadingFormState extends State<DeviceReadingForm> {
  final _formKey = GlobalKey<FormState>();


  String? _selectedDeviceId;
  final _readingDateCtrl = TextEditingController();
  final _maxLoadCtrl = TextEditingController();
  final _taxCtrl     = TextEditingController();

  final List<UnitSlab> _slabs = [UnitSlab()];




  static const _surface = Color(0xFF2C2C2E);
  static const _card    = Color(0xFF1C1C1E);
  static const _border  = Color(0xFF3A3A3C);
  static const _muted   = Colors.white38;
  static const _text    = Colors.white;

  List<DeviceModel> _devices = [];
  List<String> _savedDeviceIds = [];
  bool _isLoadingDevices = false;
  Map<String, String> _deviceIdToObjectId = {};

  bool _isSubmitting = false;


  @override
  void dispose() {
    _maxLoadCtrl.dispose();
    _readingDateCtrl.dispose();
    _taxCtrl.dispose();
    for (var s in _slabs) {
      s.dispose();
    }
    super.dispose();
  }

  void _addSlab() => setState(() => _slabs.add(UnitSlab()));

  void _removeSlab(int index) {
    if (_slabs.length == 1) return;
    setState(() {
      _slabs[index].dispose();
      _slabs.removeAt(index);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    _loadDevices();
    super.initState();
  }



  Future<void> _loadDevices() async {
    setState(() => _isLoadingDevices = true);

    try {
      final devices = await DeviceService.getDevices();

      final filtered = devices
          .where((d) => d.name == "Energy Meter")
          .toList();

      setState(() {
        _devices = filtered;

        _savedDeviceIds = filtered.map((d) => d.deviceId).toList();

        _deviceIdToObjectId = {};
        for (var device in filtered) {
          _deviceIdToObjectId[device.deviceId] = device.id;
        }
      });



      print("✅ Loaded ${_devices.length} Energy Meter devices");
      print("📱 Display IDs: $_savedDeviceIds");
      print("📱 Mapping: $_deviceIdToObjectId");


    } catch (e) {
      print("❌ Error loading devices: $e");
    } finally {
      setState(() => _isLoadingDevices = false);
    }
  }

  // Validate slabs
  bool _validateSlabs() {
    for (int i = 0; i < _slabs.length; i++) {
      final slab = _slabs[i];

      // Check empty fields
      if (slab.fromCtrl.text.isEmpty ||
          slab.toCtrl.text.isEmpty ||
          slab.priceCtrl.text.isEmpty) {
        _showError('Please fill all slab fields');
        return false;
      }

      // Parse values
      final from = int.tryParse(slab.fromCtrl.text);
      final to = int.tryParse(slab.toCtrl.text);
      final price = double.tryParse(slab.priceCtrl.text);

      // Validate numbers
      if (from == null || to == null || price == null) {
        _showError('Invalid numbers in slab ${i + 1}');
        return false;
      }

      // Validate range
      if (from >= to) {
        _showError('Slab ${i + 1}: "From" must be less than "To"');
        return false;
      }

      // Validate price
      if (price <= 0) {
        _showError('Slab ${i + 1}: Price must be greater than 0');
        return false;
      }

      // Check continuity between slabs
      if (i > 0) {
        final prevTo = int.tryParse(_slabs[i - 1].toCtrl.text) ?? 0;
        if (from != prevTo + 1) {
          _showError('Slabs must be continuous. Expected "From": ${prevTo + 1}');
          return false;
        }
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }



  Future<void> _submit() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Validate slabs
    if (!_validateSlabs()) return;

    setState(() => _isSubmitting = true);

    try {
      // Get SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Get organization ID (saved during login)
      final organizationId = prefs.getString('organization_id');
      if (organizationId == null || organizationId.isEmpty) {
        throw Exception('Organization ID not found. Please login again.');
      }

      final selectedDisplayId = _selectedDeviceId; // "SEM00001"
      final deviceObjectId = _deviceIdToObjectId[selectedDisplayId];

      if (deviceObjectId == null) {
        throw Exception('Invalid device selected');
      }

      if (_selectedDeviceId == null || _selectedDeviceId!.isEmpty) {
        throw Exception('Please select a device');
      }

      final readingDate = int.tryParse(_readingDateCtrl.text);
      if (readingDate == null || readingDate < 1 || readingDate > 31) {
        throw Exception('Please enter a valid reading date (1-31)');
      }

      final taxPercentage = double.tryParse(_taxCtrl.text);
      if (taxPercentage == null || taxPercentage < 0) {
        throw Exception('Please enter a valid tax percentage');
      }

      final unitPriceSlabs = _slabs.map((slab) {
        return UnitPriceSlab(
          from: int.parse(slab.fromCtrl.text),
          to: int.parse(slab.toCtrl.text),
          pricePerUnit: double.parse(slab.priceCtrl.text),
        );
      }).toList();

      final request = BillingRequest(
        deviceId: deviceObjectId,
        organizationId: organizationId,
        readingDate: readingDate,
        unitPriceSlabs: unitPriceSlabs,
        taxPercentage: taxPercentage,
      );

      // Call API
      final response = await BillingService.createBilling(request);

      print("✅ Billing created successfully!");
      print("   Billing ID: ${response.data.id}");
      print("   Device ID: ${response.data.deviceId}");

      // Save to local storage (optional backup)
      await prefs.setString('last_billing_id', response.data.id);
      await prefs.setString('last_billing_date', DateTime.now().toIso8601String());

      await prefs.setBool('has_devices', true);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.green),
              SizedBox(width: 10),
              Text('Billing information saved successfully!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: _card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.green, width: 1),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) =>  HomeScreen()),
            (route) => false,
      );

    } catch (e) {
      print('❌ Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: widget.showBackButton
          ? AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Add Billing Information",
          style: TextStyle(color: Colors.white),
        ),
      )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [


                // _buildHeader(),
                const SizedBox(height: 15),

                _buildCard(
                  children: [
                    Row(children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Device ID',
                          value: _selectedDeviceId,
                          items: _savedDeviceIds,
                          hintText: _savedDeviceIds.isEmpty
                              ? 'No devices saved'
                              : 'Select…',
                          onChanged: (v) =>
                              setState(() => _selectedDeviceId = v),
                          validator: (v) =>
                          v == null ? 'Required' : null,
                        ),
                      ),
                    ],
                    ),
                    const SizedBox(height: 18),

                    Row(children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Reading Days',
                          controller: _readingDateCtrl,
                          hint: 'e.g. 12,24',
                          keyboard: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            final day = int.tryParse(v);
                            if (day == null || day < 1 || day > 31) return 'Enter 1-31';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(
                        label: 'Max Load',
                        controller: _maxLoadCtrl,
                        hint: 'e.g. 500',
                        keyboard: TextInputType.number,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      )),
                    ]),
                    const SizedBox(height: 22),

                    _buildUnitPriceSection(),
                    const SizedBox(height: 22),


                    _buildTextField(
                      label: 'Tax (%)',
                      controller: _taxCtrl,
                      hint: 'e.g. 17',
                      keyboard: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 26),

                    _buildSubmitButton(),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildHeader() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //
  //       const Text('ADD Device',
  //           style: TextStyle(
  //             fontSize: 20, fontWeight: FontWeight.w600,
  //             color: _text, height: 1.15,
  //           )),
  //     ],
  //   );
  // }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2E2E30), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: _openScanner,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.4)),
                ),
                child: const Icon(Icons.qr_code_rounded,
                    color: Colors.greenAccent, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          onScan: (data) {
            _fillFormFromQR(data);
          },
        ),
      ),
    );
  }

  /// FILL FORM FROM QR
  void _fillFormFromQR(String data) {
    try {
      final jsonData = jsonDecode(data);
      _selectedDeviceId = jsonData['deviceId'];
      _readingDateCtrl.text = (jsonData['readingDate'] ?? '').toString();
      _taxCtrl.text = (jsonData['taxPercentage'] ?? '').toString();

      if (jsonData['unitPriceSlabs'] != null) {
        for (var slab in _slabs) {
          slab.dispose();
        }
        _slabs.clear();

        for (var slab in jsonData['unitPriceSlabs']) {
          final newSlab = UnitSlab();
          newSlab.fromCtrl.text = slab['from'].toString();
          newSlab.toCtrl.text = slab['to'].toString();
          newSlab.priceCtrl.text = slab['pricePerUnit'].toString();
          _slabs.add(newSlab);
        }
      }
    } catch (e) {
      final parts = data.split('|');
      for (var part in parts) {
        final keyValue = part.split(':');
        if (keyValue.length != 2) continue;
        final key = keyValue[0];
        final value = keyValue[1];

        switch (key) {
          case 'DeviceID':
            _selectedDeviceId = value;
            break;
          case 'ReadingDate':
            _readingDateCtrl.text = value;
            break;
          case 'Tax':
            _taxCtrl.text = value;
            break;
        }
      }
    }
    setState(() {});
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    FormFieldValidator<String>? validator,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          validator: validator,
          onChanged: onChanged,
          hint: Text('Select…', style: TextStyle(color: _muted, fontSize: 13)),
          dropdownColor: _surface,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _muted, size: 18),
          style: const TextStyle(color: _text, fontSize: 13, fontFamily: 'Roboto'),
          decoration: _inputDecoration(),
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Text(e, style: const TextStyle(color: _text, fontSize: 13)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    TextInputType keyboard = TextInputType.text,
    FormFieldValidator<String>? validator,
    List<TextInputFormatter>? inputFormatters,

  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          validator: validator,
          style: const TextStyle(
              color: _text, fontSize: 13, fontFamily: 'RobotoMono'),
          decoration: _inputDecoration(hint: hint),
          inputFormatters: keyboard == TextInputType.number ||
              keyboard == const TextInputType.numberWithOptions(decimal: true)
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
              : null,
        ),
      ],
    );
  }



  Widget _buildUnitPriceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3C), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 6),
              const Text('UNIT PRICE SLABS',
                  style: TextStyle(
                    fontSize: 10, letterSpacing: 1.8,
                    color: Colors.greenAccent, fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              GestureDetector(
                onTap: _addSlab,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add, color: Colors.greenAccent, size: 14),
                      SizedBox(width: 4),
                      Text('Add Slab',
                          style: TextStyle(
                              color: Colors.greenAccent, fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Column headers
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(flex: 2, child: _label('From (Units)')),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _label('To (Units)')),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _label('Price / Unit')),
              const SizedBox(width: 32),
            ]),
          ),


          ...List.generate(_slabs.length, (i) => _buildSlabRow(i)),
        ],
      ),
    );
  }

  Widget _buildSlabRow(int index) {
    final slab = _slabs[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [

          Expanded(flex: 2, child: _slabField(
            ctrl: slab.fromCtrl,
            hint: '0',
            validator: (v) => (v == null || v.isEmpty) ? '*' : null,
          )),
          const SizedBox(width: 8),

          Expanded(flex: 2, child: _slabField(
            ctrl: slab.toCtrl,
            hint: '100',
            validator: (v) => (v == null || v.isEmpty) ? '*' : null,
          )),
          const SizedBox(width: 8),

          Expanded(flex: 2, child: _slabField(
            ctrl: slab.priceCtrl,
            hint: '₨ 0.00',
            validator: (v) => (v == null || v.isEmpty) ? '*' : null,
          )),
          const SizedBox(width: 6),

          GestureDetector(
            onTap: () => _removeSlab(index),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: _slabs.length == 1
                    ? _border
                    : Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.close_rounded,
                  size: 14,
                  color: _slabs.length == 1 ? _muted : Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slabField({
    required TextEditingController ctrl,
    required String hint,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      style: const TextStyle(
          color: _text, fontSize: 12, fontFamily: 'RobotoMono'),
      decoration: _inputDecoration(hint: hint, compact: true),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.green.withOpacity(0.4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSubmitting
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text(
          'ADD',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
        fontSize: 9.5, letterSpacing: 1.2,
        color: _muted, fontWeight: FontWeight.w600),
  );

  InputDecoration _inputDecoration({String hint = '', bool compact = false}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF2C2C2E).withOpacity(0.85),
        isDense: compact,
        contentPadding: compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A3A3C), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A3A3C), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        errorStyle: const TextStyle(fontSize: 9, color: Colors.redAccent),
      );
}