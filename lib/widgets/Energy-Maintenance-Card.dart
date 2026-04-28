import 'package:flutter/material.dart';
import '../services/device_service.dart';
import '../services/energy_services.dart';


class EnergyMeterCard extends StatefulWidget {
  final Map<String, dynamic>? realtimeData;
  final String deviceId;
  const EnergyMeterCard({super.key,this.realtimeData, required this.deviceId});

  @override
  State<EnergyMeterCard> createState() => _EnergyMeterCardState();

  static Widget infoBox(String title, String value, String unit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A202A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                text: value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                children: [
                  TextSpan(
                    text: " $unit",
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnergyMeterCardState extends State<EnergyMeterCard> {
  bool isLoading = true;
  String errorMessage = "";

  double totalPowerKw = 0.0;
  double totalPowerW = 0.0;
  double todayEnergy = 0.0;
  // double monthlyEnergy = 0.0;
  double monthlyUnits = 0.0; // 👈 CHANGED
  double frequency = 50.0;


  @override
  void initState() {
    super.initState();

    fetchEnergyData();

  }

  double _toDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }



  Future<void> fetchEnergyData() async {
    try {
      debugPrint("📡 fetchEnergyData() START");

      setState(() {
        isLoading = true;
        errorMessage = "";
      });

      final now = DateTime.now();
      final todayDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final firstDayOfMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}-01";

      final response = await EnergyService.fetchEnergy(
        fromDate: firstDayOfMonth,
        toDate: todayDate,
      );

      final billResponse =
      await DeviceService.calculateBill(widget.deviceId);



      debugPrint("✅ API Response Received");

      if (response['success'] != true || response['data'] == null) {
        throw Exception("Invalid API response");
      }

      final data = response['data'];
      final bill = billResponse.data;


      final List threePhaseData = data['threePhaseData'] ?? [];
      if (threePhaseData.isNotEmpty) {
        final latestData = threePhaseData.last;
        totalPowerKw = (latestData['dailyAvgPower'] ?? 0.0).toDouble();
        totalPowerW = totalPowerKw * 1000;
        frequency = (latestData['dailyAvgFrequency'] ?? 50.0).toDouble();

        debugPrint("✅ API POWER: $totalPowerKw KW");
        debugPrint("✅ API POWER SET: $totalPowerKw KW");
      } else {
        debugPrint("⚠️ No threePhaseData found in API response");
      }

      todayEnergy = (data['todayEnergyUsage'] ?? 0.0).toDouble();
      monthlyUnits = _toDouble(bill.totalUnits, 0);
      // monthlyEnergy = (data['thisMonthEnergyUsage'] ?? 0.0).toDouble();

      debugPrint("📊 Today Energy: $todayEnergy kWh");
      debugPrint("📦 Monthly Units: $monthlyUnits kWh");
      // debugPrint("📊 Monthly Energy: $monthlyEnergy kWh");

      setState(() {
        isLoading = false;
      });

    } catch (e) {
      debugPrint("❌ fetchEnergyData error: $e");
      setState(() {
        errorMessage = "Failed to load energy data";
        isLoading = false;
      });
    }
  }
  @override
  void didUpdateWidget(covariant EnergyMeterCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.realtimeData != null) {
      debugPrint("🔄 REALTIME UPDATE RECEIVED: ${widget.realtimeData}");

      double newPowerKw = 0.0;


      if (widget.realtimeData!.containsKey('threePhase') &&
          widget.realtimeData!['threePhase'] is Map) {
        var threePhase = widget.realtimeData!['threePhase'];
        if (threePhase.containsKey('power')) {
          newPowerKw = _toDouble(threePhase['power'], 0);
          debugPrint("⚡ Socket Power (threePhase): $newPowerKw KW");
        }
      }
      else if (widget.realtimeData!.containsKey('power')) {
        newPowerKw = _toDouble(widget.realtimeData!['power'], 0);
        debugPrint("⚡ Socket Power (direct): $newPowerKw KW");
      }
      else if (widget.realtimeData!.containsKey('power_w')) {
        newPowerKw = _toDouble(widget.realtimeData!['power_w'], 0) / 1000;
        debugPrint("⚡ Socket Power (power_w): $newPowerKw KW");
      }


      if (newPowerKw >= 0) {
        setState(() {
          totalPowerKw = newPowerKw;
          totalPowerW = totalPowerKw * 1000;

          if (widget.realtimeData!.containsKey('totalUnits')) {
            monthlyUnits = _toDouble(
              widget.realtimeData!['totalUnits'],
              monthlyUnits,
            );
            debugPrint("📦 Realtime Monthly Units: $monthlyUnits kWh");
          }


          if (widget.realtimeData!.containsKey('threePhase') &&
              widget.realtimeData!['threePhase'] is Map) {
            frequency = _toDouble(widget.realtimeData!['threePhase']['frequency'], frequency);
          }

          if (widget.realtimeData!.containsKey('todayEnergyUsage')) {
            todayEnergy = _toDouble(
              widget.realtimeData!['todayEnergyUsage'],
              todayEnergy,
            );
          }

          // if (widget.realtimeData!.containsKey('thisMonthEnergyUsage')) {
          //   monthlyEnergy = _toDouble(
          //     widget.realtimeData!['thisMonthEnergyUsage'],
          //     monthlyEnergy,
          //   );
          // }

          debugPrint("✅ UPDATED - Power: ${totalPowerKw}KW, Today: ${todayEnergy}kWh");

          debugPrint("REALTIME DATA: ${widget.realtimeData}");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final safePower = totalPowerKw.isNaN ? 0.0 : totalPowerKw;
    final safeToday = todayEnergy.isNaN ? 0.0 : todayEnergy;
    // final safeMonthly = monthlyEnergy.isNaN ? 0.0 : monthlyEnergy;
    final safeFreq = frequency.isNaN ? 50.0 : frequency;
    debugPrint("BUILD CALLED - Power: $safePower KW, Today: $safeToday");

    return Container(
      width: double.infinity,
      height: 287,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:  Color(0xFF121821),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.6),
            blurRadius: 18,
          ),
        ],
      ),
      child: isLoading
          ? const Center(
        child: CircularProgressIndicator(
            color: Colors.green),
      )
          : errorMessage.isNotEmpty
          ? Center(
        child: Text(errorMessage,
            style: const TextStyle(
                color: Colors.redAccent)),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children:  [
              Icon(Icons.flash_on,
                  color: Colors.green),
              SizedBox(width: 12),
              Text("Total Power",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14)),
              Spacer(),

              Text("${frequency.toStringAsFixed(2)} Hz",
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12)),
            ],
          ),

          const SizedBox(height: 16),

          Center(
            child: Column(
              children: [
                Text(
                  "${totalPowerW.toStringAsFixed(0)} W",
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.green
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${totalPowerKw.toStringAsFixed(2)} kW",
                  style: const TextStyle(
                      color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              EnergyMeterCard.infoBox(
                "TODAY",
                todayEnergy.toStringAsFixed(2),
                "kWh",
              ),
              const SizedBox(width: 12),
              EnergyMeterCard.infoBox(
                "MONTHLY",
                monthlyUnits.toStringAsFixed(2),
                "kWh",
              ),
            ],
          ),
        ],
      ),
    );
  }
}
