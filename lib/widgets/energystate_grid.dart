import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/device_service.dart';

class EnergyStatsGrid extends StatefulWidget {
  final Map<String, dynamic>? realtimeData;
  final String? deviceId;
  final int refreshTrigger;

  const EnergyStatsGrid({super.key, this.realtimeData, this.deviceId, required this.refreshTrigger});

  @override
  State<EnergyStatsGrid> createState() => _EnergyStatsGridState();
}

class _EnergyStatsGridState extends State<EnergyStatsGrid> {
  double? load;
  double? monthlyCost;
  bool isLoading = false;
  String? _currentDeviceId;
  Timer? _timer;





  Future<void> fetchBill(String deviceId) async {
    if (deviceId.isEmpty) return;

    if (_currentDeviceId == deviceId && monthlyCost != null) return;

    print("⏳ Fetching bill for device: $deviceId");

    if (!mounted) return;

    setState(() {
      isLoading = _currentDeviceId != deviceId;
    });

    try {
      final billResponse = await DeviceService.calculateBill(deviceId);

      final bill = billResponse.data;
      print("📊 Total Units: ${bill.totalUnits}");
      print("💰 Base Cost: Rs ${bill.baseCost}");
      print("🧾 Tax Percentage: ${bill.taxPercentage}%");
      print("💸 Tax Amount: Rs ${bill.taxAmount}");
      print("💵 Total Cost: Rs ${bill.totalCost}");
      print("⚡ Load: ${bill.load}%");

      if (!mounted) return;
      setState(() {
        monthlyCost = bill.totalCost;
        load = bill.load;
        _currentDeviceId = deviceId;
        isLoading = false;
      });
      print("🖥️ UI UPDATED => Cost: $monthlyCost | Load: $load");

    } catch (e) {

      print("❌ Error: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  void initState() {
    super.initState();
    if (widget.deviceId != null && widget.deviceId!.isNotEmpty) {
      fetchBill(widget.deviceId!);
      _timer?.cancel();

      _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
        print("🔄 AUTO REFRESH TRIGGERED at ${DateTime.now()}");
        if (widget.deviceId != null && widget.deviceId!.isNotEmpty) {
          fetchBill(widget.deviceId!);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant EnergyStatsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newId = widget.deviceId;
    final oldId = oldWidget.deviceId;

    final deviceChanged = newId != oldId;
    final refreshChanged = widget.refreshTrigger != oldWidget.refreshTrigger;

    if (newId == null || newId.isEmpty) {
      _timer?.cancel();
      return;
    }

    if (deviceChanged) {
      _timer?.cancel();
      _currentDeviceId = null;
      fetchBill(newId);
      return;
    }

    if (refreshChanged) {
      _currentDeviceId = null;
      fetchBill(newId);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final double? currentLoad =
    (widget.realtimeData != null && widget.realtimeData!.containsKey('load'))
        ? (widget.realtimeData!['load'] as num).toDouble()
        : load;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: "Load",
                value: _formatLoad(currentLoad),
                valueColor: _loadColor(currentLoad),
                icon: Icons.bolt,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                title: "Monthly Est Cost",
                value: isLoading
                    ? "Loading..."
                    : _formatCost(monthlyCost),
                valueColor: Colors.white,
                icon: Icons.account_balance_wallet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required Color valueColor,
    required IconData icon,
  }) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.green,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}





String _formatLoad(dynamic load) {
  if (load == null) return "0%";
  return "${load.toStringAsFixed(0)}%";
}

String _formatCost(dynamic cost) {
  if (cost == null) return "Rs 0.00";

  final format = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs ',
  );

  return format.format(cost);
}
Color _loadColor(dynamic load) {
  if (load == null) return Colors.green;
  if (load >= 80) return Colors.redAccent;
  if (load >= 50) return Colors.yellowAccent;
  return Colors.greenAccent;
}

