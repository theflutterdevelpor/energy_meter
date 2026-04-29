import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../bottom_nav_bar/home_nav_bar.dart';
import '../models/request/billing_request.dart';
import '../services/billing_service.dart';
import '../services/device_service.dart';


class UnitSlab {
  TextEditingController fromCtrl  = TextEditingController();
  TextEditingController toCtrl    = TextEditingController();
  TextEditingController priceCtrl = TextEditingController();

  UnitSlab({String from = '', String to = '', String price = ''}) {
    fromCtrl.text  = from;
    toCtrl.text    = to;
    priceCtrl.text = price;
  }

  void dispose() {
    fromCtrl.dispose();
    toCtrl.dispose();
    priceCtrl.dispose();
  }
}


class DeviceConfigForm extends StatefulWidget {
  final bool showBackButton;
  final String? selectedDeviceId;
  const DeviceConfigForm({super.key, this.showBackButton = false, this.selectedDeviceId});

  @override
  State<DeviceConfigForm> createState() => _DeviceConfigFormState();
}

class _DeviceConfigFormState extends State<DeviceConfigForm> {
  static const _surface = Color(0xFF2C2C2E);
  static const _card    = Color(0xFF1C1C1E);
  static const _border  = Color(0xFF3A3A3C);
  static const _accent  = Colors.green;
  static const _muted   = Colors.white38;
  static const _text    = Colors.white;


  final _formKey = GlobalKey<FormState>();


  DateTime _selectedDate = DateTime.now();

  final _deviceIdCtrl = TextEditingController();
  final _maxLoadCtrl  = TextEditingController();
  final _taxCtrl      = TextEditingController();
  final _readingDateCtrl = TextEditingController();
  List<String> _devices = [];
  String? _selectedDeviceId;
  String? _billingId;



  List<UnitSlab> _slabs = [UnitSlab()];

  bool _loading = true;
  bool _isSaving = false;



  @override
  void initState() {
    super.initState();

    if (widget.selectedDeviceId != null) {
      _selectedDeviceId = widget.selectedDeviceId;
    }

    _loadData();
  }

  // ================= LOAD DATA =================
  Future<void> _loadData() async {
    setState(() => _loading = true);

    await _loadDevices();
    await _loadBilling();

    setState(() => _loading = false);
  }

  // ================= DEVICES =================
  Future<void> _loadDevices() async {
    try {
      final devices = await DeviceService.getDevices();

      _devices = devices
          .where((e) => e.name == "Energy Meter")
          .map((e) => e.deviceId ?? "")
          .where((e) => e.isNotEmpty)
          .toList();

      if (_selectedDeviceId == null && _devices.isNotEmpty) {
        _selectedDeviceId = _devices.first;
      }
    } catch (e) {
      debugPrint("Device error: $e");
    }
  }

  // ================= BILLING LOAD FLOW =================
  Future<void> _loadBilling() async {
    try {
      if (_selectedDeviceId == null) return;

      final allBillings = await BillingService.getAllBillings();

      final filtered = allBillings
          .where((b) => b.data.deviceId == _selectedDeviceId)
          .toList();

      if (filtered.isEmpty) return;

      _billingId = filtered.first.data.id;

      final res = await BillingService.getBillingById(_billingId!);
      final data = res.data;

      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _readingDateCtrl.text = data.readingDate.toString();
        _taxCtrl.text = (data.taxPercentage ?? 0).toString();
        _maxLoadCtrl.text = (data.maxLoad ?? 0).toString();

        _slabs = data.unitPriceSlabs.map((s) {
          return UnitSlab(
            from: s.from.toString(),
            to: s.to.toString(),
            price: s.pricePerUnit.toString(),
          );
        }).toList();
      });

      if (data.organizationId != null && data.organizationId.isNotEmpty) {
        await prefs.setString("organizationId", data.organizationId);
        debugPrint(" ORG ID SAVED: ${data.organizationId}");
      }

    } catch (e) {
      debugPrint("Load billing error: $e");
    }
  }

  // ================= UPDATE =================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_billingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Billing not found")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final organizationId = prefs.getString("organizationId");

      debugPrint("🔥 ORG ID FROM PREFS: $organizationId");

      if (organizationId == null || organizationId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Organization ID missing. Please login again.")),
        );
        setState(() => _isSaving = false);
        return;
      }

      final slabs = _slabs.map((s) {
        return UnitPriceSlab(
          from: int.tryParse(s.fromCtrl.text) ?? 0,
          to: int.tryParse(s.toCtrl.text) ?? 0,
          pricePerUnit: double.tryParse(s.priceCtrl.text) ?? 0,
        );
      }).toList();

      final request = BillingRequest(
        deviceId: _selectedDeviceId!,
        organizationId: organizationId,
        readingDate: int.tryParse(_readingDateCtrl.text) ?? 0,
        unitPriceSlabs: slabs,
        taxPercentage: double.tryParse(_taxCtrl.text) ?? 0,
        maxLoad: double.tryParse(_maxLoadCtrl.text),
      );

      await BillingService.updateBilling(_billingId!, request);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updated successfully")),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      Navigator.pop(context, true);

    } catch (e) {
      debugPrint("Save error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _addSlab() {
    setState(() {
      _slabs.add(UnitSlab());
    });
  }

  void _removeSlab(int index) {
    if (_slabs.length == 1) return;

    setState(() {
      _slabs[index].dispose();
      _slabs.removeAt(index);
    });
  }

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    _maxLoadCtrl.dispose();
    _taxCtrl.dispose();
    _readingDateCtrl.dispose();

    for (var s in _slabs) {
      s.dispose();
    }

    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit / Configure Device',
          style: TextStyle(color: Colors.white),
        ),

      )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 15),
                _buildCard(children: [
                  Row(children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Device ID',
                        value: _selectedDeviceId,
                        items: _devices,
                        hintText: _devices.isEmpty
                            ? 'No devices saved'
                            : 'Select…',
                        onChanged: (v) {
                          setState(() {
                            _selectedDeviceId = v;
                            _deviceIdCtrl.text = v ?? '';
                          });
                        },
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
                        label: 'Reading Date',
                        controller: _readingDateCtrl,
                        hint: 'e.g. 15',
                        keyboard: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final d = int.tryParse(v);
                          if (d == null || d < 1 || d > 31) return 'Enter 1–31';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(
                      label: 'Max Load (kw)',
                      controller: _maxLoadCtrl,
                      hint: 'e.g. 500',
                      keyboard: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final d = int.tryParse(v);
                        if (d == null || d < 0 || d > 60) return 'Enter 0–60';
                        return null;
                      },
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
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final d = int.tryParse(v);
                      if (d == null || d < 1 || d > 200) return 'Enter 1–200';
                      return null;
                    },
                  ),
                  const SizedBox(height: 26),

                  _buildSaveButton(),
                ]),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildHeader() => const Text(
    'CONFIGURE DEVICE',
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _text, height: 1.15),
  );

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2E2E30), width: 1.2),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.6), blurRadius: 30, offset: const Offset(0, 12),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
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
          value: (value != null && value.isNotEmpty && items.contains(value))
              ? value
              : null,
          validator: validator,
          onChanged: onChanged,

          hint: Text(
            items.isEmpty ? 'No devices found' : 'Select Device',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),

          dropdownColor: const Color(0xFF2C2C2E),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white38,
          ),

          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),

          decoration: _inputDecoration(),

          items: items.map((e) {
            return DropdownMenuItem<String>(
              value: e,
              child: Text(
                e,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
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
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          cursorColor: Colors.green,
          enableInteractiveSelection: false,
          keyboardType: keyboard,
          validator: validator,
         readOnly: readOnly,
          style:  TextStyle(color: readOnly ? Colors.grey : _text, fontSize: 13, fontFamily: 'RobotoMono'),
          decoration: _inputDecoration(hint: hint),
          inputFormatters: (keyboard == TextInputType.number ||
              keyboard ==  TextInputType.numberWithOptions(decimal: true))
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
        color: const Color(0xFF2C2C2E).withValues(alpha:  0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3C), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.bolt_rounded, color: Colors.greenAccent, size: 16),
            const SizedBox(width: 6),
            const Text('UNIT PRICE SLABS', style: TextStyle(
              fontSize: 10, letterSpacing: 1.8,
              color: Colors.greenAccent, fontWeight: FontWeight.w700,
            )),
            const Spacer(),
            GestureDetector(
              onTap: _addSlab,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.add, color: Colors.greenAccent, size: 14),
                  SizedBox(width: 4),
                  Text('Add Slab', style: TextStyle(
                      color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 14),
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
      child: Row(children: [
        Expanded(flex: 2, child: _slabField(ctrl: slab.fromCtrl,  hint: '0',      validator: (v) => (v == null || v.isEmpty) ? '*' : null)),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: _slabField(ctrl: slab.toCtrl,    hint: '100',    validator: (v) => (v == null || v.isEmpty) ? '*' : null)),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: _slabField(ctrl: slab.priceCtrl, hint: '₨ 0.00', validator: (v) => (v == null || v.isEmpty) ? '*' : null)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => _removeSlab(index),
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _slabs.length == 1 ? _border : Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.close_rounded, size: 14,
                color: _slabs.length == 1 ? _muted : Colors.redAccent),
          ),
        ),
      ]),
    );
  }

  Widget _slabField({
    required TextEditingController ctrl,
    required String hint,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      cursorColor: Colors.green,
      enableInteractiveSelection: false,
      validator: validator,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      style: const TextStyle(color: _text, fontSize: 12, fontFamily: 'RobotoMono'),
      decoration: _inputDecoration(hint: hint, compact: true),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          disabledBackgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.green.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
            ? const SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(
            color: Colors.white, strokeWidth: 2,
          ),
        )
            : const Text(
          'Update',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(fontSize: 9.5, letterSpacing: 1.2, color: _muted, fontWeight: FontWeight.w600),
  );

  InputDecoration _inputDecoration({String hint = '', bool compact = false}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
    filled: true,
    fillColor: const Color(0xFF2C2C2E).withValues(alpha:  0.85),
    isDense: compact,
    contentPadding: compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border:            OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3A3A3C), width: 0.5)),
    enabledBorder:     OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3A3A3C), width: 0.5)),
    focusedBorder:     OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green, width: 1)),
    errorBorder:       OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
    focusedErrorBorder:OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
    errorStyle: const TextStyle(fontSize: 9, color: Colors.redAccent),
  );
}