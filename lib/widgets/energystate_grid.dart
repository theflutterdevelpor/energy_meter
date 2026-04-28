import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/device_service.dart';
import '../services/billing_service.dart';

class EnergyStatsGrid extends StatefulWidget {
  final Map<String, dynamic>? realtimeData;
  final String? deviceId;
  final int refreshTrigger;

  const EnergyStatsGrid({
    super.key,
    this.realtimeData,
    this.deviceId,
    required this.refreshTrigger
  });

  @override
  State<EnergyStatsGrid> createState() => _EnergyStatsGridState();
}

class _EnergyStatsGridState extends State<EnergyStatsGrid> {
  double? load;
  double? monthlyCost;
  bool isLoading = false;
  String? _currentDeviceId;
  Timer? _timer;
  int? _maxLoad;
  double? _currentPower;
  bool isFirstLoad = true;

  Future<void> fetchBill(String deviceId) async {
    if (deviceId.isEmpty) return;

    print("⏳ Fetching bill for device: $deviceId");

    if (!mounted) return;

    if (isFirstLoad) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final allBillings = await BillingService.getAllBillings();
      final billing = allBillings.firstWhere(
            (b) => b.data.deviceId == deviceId,
        orElse: () => throw Exception('No billing found for device $deviceId'),
      );

      _maxLoad = billing.data.maxLoad;
      print("📋 Max Load from DB: $_maxLoad kW");

      _currentPower = 0.0;
      if (widget.realtimeData != null) {
        if (widget.realtimeData!.containsKey('threePhase') &&
            widget.realtimeData!['threePhase'] is Map) {
          final threePhase = widget.realtimeData!['threePhase'] as Map;
          if (threePhase.containsKey('power')) {
            _currentPower = (threePhase['power'] as num).toDouble();
          }
        }
        else if (widget.realtimeData!.containsKey('power')) {
          _currentPower = (widget.realtimeData!['power'] as num).toDouble();
        }
        else if (widget.realtimeData!.containsKey('power_w')) {
          _currentPower = (widget.realtimeData!['power_w'] as num).toDouble();
        }
      }

      print("⚡ Current Power (realtime): $_currentPower kW");

      double calculatedLoad = 0;
      if (_maxLoad != null && _maxLoad! > 0 && _currentPower != null && _currentPower! > 0) {
        calculatedLoad = (_currentPower! / _maxLoad!) * 100;
        print("⚡ MANUAL LOAD CALCULATION: $calculatedLoad%");
      } else {
        print("⚠️ Cannot calculate load - MaxLoad: $_maxLoad, CurrentPower: $_currentPower");
      }

      final billResponse = await DeviceService.calculateBill(deviceId);
      final bill = billResponse.data;

      print("💰 API Cost: Rs ${bill.totalCost}");
      print("💰 Base Cost: Rs ${bill.baseCost}");
      print("🧾 Tax Percentage: ${bill.taxPercentage}%");
      print("📊 API Load (ignored): ${bill.load}%");

      if (!mounted) return;

      setState(() {
        monthlyCost = bill.totalCost;
        load = calculatedLoad > 0 ? calculatedLoad : bill.load;
        _currentDeviceId = deviceId;
        isLoading = false;
        isFirstLoad = false;
      });

      print("🖥️ UI UPDATED => Cost: $monthlyCost | Load: $load%");

    } catch (e) {
      print("❌ Error in fetchBill: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    print("🔵 EnergyStatsGrid INIT");
    print("   DeviceId: ${widget.deviceId}");
    print("   RefreshTrigger: ${widget.refreshTrigger}");

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

    print("🟡 DID UPDATE WIDGET");
    print("   Old deviceId: ${oldWidget.deviceId}");
    print("   New deviceId: ${widget.deviceId}");
    print("   Old refreshTrigger: ${oldWidget.refreshTrigger}");
    print("   New refreshTrigger: ${widget.refreshTrigger}");

    // Refresh when device changes OR refreshTrigger changes
    if (widget.deviceId != oldWidget.deviceId ||
        widget.refreshTrigger != oldWidget.refreshTrigger) {
      print("🔄 Widget updated - refreshing...");
      _currentDeviceId = null;
      fetchBill(widget.deviceId!);
    }
  }

  @override
  void dispose() {
    print("🔴 DISPOSING EnergyStatsGrid");
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Update current power from realtime data without full refresh
    if (widget.realtimeData != null && mounted) {
      double newPower = 0.0;

      // Extract power from realtime data
      if (widget.realtimeData!.containsKey('threePhase') &&
          widget.realtimeData!['threePhase'] is Map) {
        final threePhase = widget.realtimeData!['threePhase'] as Map;
        if (threePhase.containsKey('power')) {
          newPower = (threePhase['power'] as num).toDouble();
        }
      } else if (widget.realtimeData!.containsKey('power')) {
        newPower = (widget.realtimeData!['power'] as num).toDouble();
      } else if (widget.realtimeData!.containsKey('power_w')) {
        newPower = (widget.realtimeData!['power_w'] as num).toDouble();
      }

      // If power changed significantly, recalculate load in real-time
      if (newPower != _currentPower && newPower > 0 && _maxLoad != null && _maxLoad! > 0) {
        print("⚡ Power changed from $_currentPower to $newPower - recalculating load");
        _currentPower = newPower;
        final newLoad = (newPower / _maxLoad!) * 100;
        if (mounted) {
          setState(() {
            load = newLoad;
          });
        }
      }
    }

    final double? currentLoad = load;

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
                value: isLoading && isFirstLoad
                    ? "Loading..."
                    : _formatCost(monthlyCost),
                valueColor: Colors.white,
                icon: Icons.account_balance_wallet,
              ),
            ),
          ],
        ),
        // const SizedBox(height: 12),
        // // Debug info (remove in production)
        // if (_maxLoad != null && _currentPower != null)
        //   Padding(
        //     padding: const EdgeInsets.only(top: 4),
        //     child: Text(
        //       "${_currentPower?.toStringAsFixed(1)} kW / ${_maxLoad?.toStringAsFixed(0)} kW = ${load?.toStringAsFixed(1)}%",
        //       style: const TextStyle(color: Colors.white38, fontSize: 9),
        //     ),
        //   ),
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
                style: const TextStyle(
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