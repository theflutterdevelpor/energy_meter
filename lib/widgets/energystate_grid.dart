import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/device_service.dart';

class EnergyStatsGrid extends StatefulWidget {
  final Map<String, dynamic>? realtimeData;

  const EnergyStatsGrid({super.key, this.realtimeData});

  @override
  State<EnergyStatsGrid> createState() => _EnergyStatsGridState();
}

class _EnergyStatsGridState extends State<EnergyStatsGrid> {
  double? monthlyCost;
  bool isLoading = false;
  String? _currentDeviceId;





  Future<void> fetchBill(String deviceId) async {

    if (deviceId.isEmpty) {
      print("❌ No device ID provided");
      return;
    }
    setState(() {
      isLoading = true;
    });

    try {
      final billResponse = await DeviceService.calculateBill(deviceId);

      print("🆔 Device ID: $deviceId");
      print("✅ Bill fetched successfully!");
      print("📊 Total Units: ${billResponse.data.totalUnits}");
      print("💰 Base Cost: Rs ${billResponse.data.baseCost}");
      print("🧾 Tax Percentage: ${billResponse.data.taxPercentage}%");
      print("💸 Tax Amount: Rs ${billResponse.data.taxAmount}");
      print("💵 Total Cost: Rs ${billResponse.data.totalCost}");



      monthlyCost = billResponse.data.totalCost;


      setState(() {
        isLoading = false;
      });

    } catch (e) {
      print("❌ Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  void initState() {
    super.initState();
    // ✅ Initial load agar deviceId available ho
    if (widget.realtimeData != null && widget.realtimeData!.containsKey('deviceId')) {
      final deviceId = widget.realtimeData!['deviceId'].toString();
      if (deviceId.isNotEmpty) {
        fetchBill(deviceId);
      }
    }
  }

  @override
  void didUpdateWidget(covariant EnergyStatsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newDeviceId = widget.realtimeData != null
        ? widget.realtimeData!['deviceId']?.toString()
        : null;

    final oldDeviceId = oldWidget.realtimeData != null
        ? oldWidget.realtimeData!['deviceId']?.toString()
        : null;

    print("🔄 didUpdateWidget - Old Device: $oldDeviceId, New Device: $newDeviceId");

    if (newDeviceId != null &&
        newDeviceId.isNotEmpty &&
        newDeviceId != oldDeviceId &&
        newDeviceId != _currentDeviceId) {
      print("📡 Device changed, fetching new bill...");
      fetchBill(newDeviceId);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: "Load",
                value: _formatLoad(widget.realtimeData?['load']),
                valueColor: _loadColor(widget.realtimeData?['load']),
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
          // icon + title (start)
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

