import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../services/energy_services.dart';

class PhaseEnergyWidget extends StatefulWidget {
  final Map<String, dynamic>? realtimeData;
  const PhaseEnergyWidget({super.key, this.realtimeData});

  @override
  State<PhaseEnergyWidget> createState() => _PhaseEnergyWidgetState();
}

class _PhaseEnergyWidgetState extends State<PhaseEnergyWidget> {

  String selectedPhase = "3-PHASE";
  final numberFormat = NumberFormat('#,##0.00');


  String selectedTimeFilter = "Today";
  final List<String> filterOptions = [
    "Today",
    "Yesterday",
    "Week",
    "30 Days",
    "6 Months",
  ];


  List<ChartData> chartData = [];
  bool isLoading = false;
  late ZoomPanBehavior _zoomPanBehavior;
  late TooltipBehavior _tooltipBehavior;



  Map<String, dynamic> phaseCardsData = {
    'phaseOne': {
      'voltage': 0.0,
      'current': 0.0,
      'power': 0.0,
      'reactivePower': 0.0,
      'apparentPower': 0.0,
      'frequency': 0.0,
      'pf': 0.0,
      'color': Colors.green,
    },
    'phaseTwo': {
      'voltage': 0.0,
      'current': 0.0,
      'power': 0.0,
      'reactivePower': 0.0,
      'apparentPower': 0.0,
      'frequency': 0.0,
      'pf': 0.0,
      'color': Color(0xFFFFB74D),
    },
    'phaseThree': {
      'voltage': 0.0,
      'current': 0.0,
      'power': 0.0,
      'reactivePower': 0.0,
      'apparentPower': 0.0,
      'frequency': 0.0,
      'pf': 0.0,
      'color': Colors.red,
    },
    'threePhase': {
      'voltage': 0.0,
      'current': 0.0,
      'power': 0.0,
      'reactivePower': 0.0,
      'apparentPower': 0.0,
      'frequency': 0.0,
      'pf': 0.0,
      'color': Color(0xFF00BCD4),
    },
  };


  String formatNumber(double value) {
    return numberFormat.format(value);
  }

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(
        enable: true,
      activationMode: ActivationMode.singleTap,
    );
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
    );
    loadEnergyData();
    loadPhaseCardsData();
  }

  @override
  void didUpdateWidget(covariant PhaseEnergyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if realtime data has changed
    if (widget.realtimeData != null &&
        widget.realtimeData != oldWidget.realtimeData) {

      debugPrint("⚡ PhaseEnergyWidget REALTIME UPDATE");
      debugPrint("📦 SOCKET DATA => ${widget.realtimeData}");

      final data = widget.realtimeData!;
      if (!mounted) return;

      setState(() {
        // ========== PHASE 1 (A) ==========
        if (data.containsKey('phaseOne') && data['phaseOne'] is Map) {
          final phase1 = data['phaseOne'] as Map;
          phaseCardsData['phaseOne']!['voltage'] = _getDoubleValue(phase1['voltage'], 0.0);
          phaseCardsData['phaseOne']!['current'] = _getDoubleValue(phase1['current'], 0.0);
          phaseCardsData['phaseOne']!['power'] = _getDoubleValue(phase1['power'], 0.0);
          phaseCardsData['phaseOne']!['reactivePower'] = _getDoubleValue(phase1['reactivePower'], 0.0);
          phaseCardsData['phaseOne']!['apparentPower'] = _getDoubleValue(phase1['apparentPower'], 0.0);
          phaseCardsData['phaseOne']!['frequency'] = _getDoubleValue(phase1['frequency'], 0.0);
          phaseCardsData['phaseOne']!['pf'] = _getDoubleValue(phase1['powerFactor'], 0.0);
        }

        // ========== PHASE 2 (B) ==========
        if (data.containsKey('phaseTwo') && data['phaseTwo'] is Map) {
          final phase2 = data['phaseTwo'] as Map;
          phaseCardsData['phaseTwo']!['voltage'] = _getDoubleValue(phase2['voltage'], 0.0);
          phaseCardsData['phaseTwo']!['current'] = _getDoubleValue(phase2['current'], 0.0);
          phaseCardsData['phaseTwo']!['power'] = _getDoubleValue(phase2['power'], 0.0);
          phaseCardsData['phaseTwo']!['reactivePower'] = _getDoubleValue(phase2['reactivePower'], 0.0);
          phaseCardsData['phaseTwo']!['apparentPower'] = _getDoubleValue(phase2['apparentPower'], 0.0);
          phaseCardsData['phaseTwo']!['frequency'] = _getDoubleValue(phase2['frequency'], 0.0);
          phaseCardsData['phaseTwo']!['pf'] = _getDoubleValue(phase2['powerFactor'], 0.0);
        }

        // ========== PHASE 3 (C) ==========
        if (data.containsKey('phaseThree') && data['phaseThree'] is Map) {
          final phase3 = data['phaseThree'] as Map;
          phaseCardsData['phaseThree']!['voltage'] = _getDoubleValue(phase3['voltage'], 0.0);
          phaseCardsData['phaseThree']!['current'] = _getDoubleValue(phase3['current'], 0.0);
          phaseCardsData['phaseThree']!['power'] = _getDoubleValue(phase3['power'], 0.0);
          phaseCardsData['phaseThree']!['reactivePower'] = _getDoubleValue(phase3['reactivePower'], 0.0);
          phaseCardsData['phaseThree']!['apparentPower'] = _getDoubleValue(phase3['apparentPower'], 0.0);
          phaseCardsData['phaseThree']!['frequency'] = _getDoubleValue(phase3['frequency'], 0.0);
          phaseCardsData['phaseThree']!['pf'] = _getDoubleValue(phase3['powerFactor'], 0.0);
        }

        // ========== THREE PHASE ==========
        if (data.containsKey('threePhase') && data['threePhase'] is Map) {
          final threePhase = data['threePhase'] as Map;
          phaseCardsData['threePhase']!['voltage'] = _getDoubleValue(threePhase['voltage'], 0.0);
          phaseCardsData['threePhase']!['current'] = _getDoubleValue(threePhase['current'], 0.0);
          phaseCardsData['threePhase']!['power'] = _getDoubleValue(threePhase['power'], 0.0);
          phaseCardsData['threePhase']!['reactivePower'] = _getDoubleValue(threePhase['reactivePower'], 0.0);
          phaseCardsData['threePhase']!['apparentPower'] = _getDoubleValue(threePhase['apparentPower'], 0.0);
          phaseCardsData['threePhase']!['frequency'] = _getDoubleValue(threePhase['frequency'], 0.0);
          phaseCardsData['threePhase']!['pf'] = _getDoubleValue(threePhase['powerFactor'], 0.0);
        }
      });

      // Debug prints to verify realtime values
      debugPrint("🔴 REALTIME PHASE A - P: ${phaseCardsData['phaseOne']!['power']} kW");
      debugPrint("🟡 REALTIME PHASE B - P: ${phaseCardsData['phaseTwo']!['power']} kW");
      debugPrint("🔵 REALTIME PHASE C - P: ${phaseCardsData['phaseThree']!['power']} kW");
      debugPrint("⚡ REALTIME THREE PHASE - P: ${phaseCardsData['threePhase']!['power']} kW");
    }
  }



  double _getDoubleValue(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }



  Future<void> loadPhaseCardsData() async {
    try {
      final today = DateTime.now();
      final todayStr = dateFormat(today);

      final response =
      await EnergyService.fetchEnergyHourly(date: todayStr);
      print("📡 FULL API RESPONSE: $response");


      final apiData = response['data'];
      print("📦 API DATA: $apiData");


      final p1 = (apiData['phaseOneData'] as List).last;
      final p2 = (apiData['phaseTwoData'] as List).last;
      final p3 = (apiData['phaseThreeData'] as List).last;
      final tp = (apiData['threePhaseData'] as List).last;

      print("⚡ THREE PHASE RAW: $tp");
      if (!mounted) return;

      setState(() {
        phaseCardsData['phaseOne']!['voltage'] = (p1['avgVoltage'] ?? 0).toDouble();
        phaseCardsData['phaseOne']!['current'] = (p1['avgCurrent'] ?? 0).toDouble();
        phaseCardsData['phaseOne']!['power']   = (p1['avgPower'] ?? 0).toDouble();
        phaseCardsData['phaseOne']!['reactivePower'] = (p1['avgReactivePower'] ?? 0).toDouble();
        phaseCardsData['phaseOne']!['apparentPower'] = (p1['avgApparentPower'] ?? 0).toDouble();
        phaseCardsData['phaseOne']!['frequency']     = (p1['avgFrequency'] ?? 0).toDouble();
        phaseCardsData['phaseOne']!['pf']      = (p1['avgPowerFactor'] ?? 0).toDouble();

        phaseCardsData['phaseTwo']!['voltage'] = (p2['avgVoltage'] ?? 0).toDouble();
        phaseCardsData['phaseTwo']!['current'] = (p2['avgCurrent'] ?? 0).toDouble();
        phaseCardsData['phaseTwo']!['power']   = (p2['avgPower'] ?? 0).toDouble();
        phaseCardsData['phaseTwo']!['reactivePower'] = (p2['avgReactivePower'] ?? 0).toDouble();
        phaseCardsData['phaseTwo']!['apparentPower'] = (p2['avgApparentPower'] ?? 0).toDouble();
        phaseCardsData['phaseTwo']!['frequency']     = (p2['avgFrequency'] ?? 0).toDouble();
        phaseCardsData['phaseTwo']!['pf']      = (p2['avgPowerFactor'] ?? 0).toDouble();

        phaseCardsData['phaseThree']!['voltage'] = (p3['avgVoltage'] ?? 0).toDouble();
        phaseCardsData['phaseThree']!['current'] = (p3['avgCurrent'] ?? 0).toDouble();
        phaseCardsData['phaseThree']!['power']   = (p3['avgPower'] ?? 0).toDouble();
        phaseCardsData['phaseThree']!['reactivePower'] = (p3['avgReactivePower'] ?? 0).toDouble();
        phaseCardsData['phaseThree']!['apparentPower'] = (p3['avgApparentPower'] ?? 0).toDouble();
        phaseCardsData['phaseThree']!['frequency']     = (p3['avgFrequency'] ?? 0).toDouble();
        phaseCardsData['phaseThree']!['pf']      = (p3['avgPowerFactor'] ?? 0).toDouble();

        phaseCardsData['threePhase']!['voltage'] = (tp['avgVoltage'] ?? 0).toDouble();
        phaseCardsData['threePhase']!['current'] = (tp['avgCurrent'] ?? 0).toDouble();
        phaseCardsData['threePhase']!['power']   = (tp['avgPower'] ?? 0).toDouble();
        phaseCardsData['threePhase']!['reactivePower'] = (tp['avgReactivePower'] ?? 0).toDouble();
        phaseCardsData['threePhase']!['apparentPower'] = (tp['avgApparentPower'] ?? 0).toDouble();
        phaseCardsData['threePhase']!['frequency']     = (tp['avgFrequency'] ?? 0).toDouble();
        phaseCardsData['threePhase']!['pf']      = (tp['avgPowerFactor'] ?? 0).toDouble();
      });
    } catch (e) {
      debugPrint("Card API Error: $e");
    }
  }



  String dateFormat(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";


  Map<String, String> getDateRange(String dateFilter) {
    DateTime today = DateTime.now();
    DateTime now = DateTime(today.year, today.month, today.day);

    DateTime fromDate, toDate;

    switch (dateFilter) {
      case 'Today':
        fromDate = now;
        toDate = now;
        break;
      case 'Yesterday':
        fromDate = now.subtract(Duration(days: 1));
        toDate = now.subtract(Duration(days: 1));
        break;
      case 'Week':
        fromDate = now.subtract(Duration(days: 6));
        toDate = now;
        break;
      case '30 Days':
        fromDate = now.subtract(Duration(days: 29));
        toDate = now;
        break;
      case '6 Months':
        fromDate = DateTime(now.year, now.month - 6, now.day);
        toDate = now;
        break;
      default:
        fromDate = now;
        toDate = now;
    }

    return {
      'fromDate': dateFormat(fromDate),
      'toDate': dateFormat(toDate),
    };
  }


  Future<void> loadEnergyData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final dates = getDateRange(selectedTimeFilter);

    try {
      Map<String, dynamic> response;

      if (selectedTimeFilter == 'Today' || selectedTimeFilter == 'Yesterday') {
        response = await EnergyService.fetchEnergyHourly(
          date: dates['fromDate']!,
        );
      } else {
        response = await EnergyService.fetchEnergy(
          fromDate: dates['fromDate']!,
          toDate: dates['toDate']!,
        );
      }

      final apiData = response['data'];
      print("========= ENERGY DEBUG =========");
      print("📊 thisMonthEnergyUsage: ${apiData['thisMonthEnergyUsage']}");
      print("📊 totalEnergyConsumption: ${apiData['totalEnegyConsumption']}");
      print("=================================");

      final phase1List = (apiData['phaseOneData'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final phase2List = (apiData['phaseTwoData'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final phase3List = (apiData['phaseThreeData'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final threePhaseList = (apiData['threePhaseData'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      bool isHourly = phase1List.isNotEmpty && phase1List[0].containsKey('hour');

      final maxLength = [
        phase1List.length,
        phase2List.length,
        phase3List.length,
        threePhaseList.length
      ].reduce((a, b) => a > b ? a : b);

      List<ChartData> tempData = [];
      for (int i = 0; i < maxLength; i++) {
        final phase1 = _getEnergyFromList(phase1List, i, isHourly);
        final phase2 = _getEnergyFromList(phase2List, i, isHourly);
        final phase3 = _getEnergyFromList(phase3List, i, isHourly);
        final threePhase = _getEnergyFromList(threePhaseList, i, isHourly);

        String label = "Day ${i + 1}";

        if (isHourly) {
          if (i < phase1List.length) {
            final hour = phase1List[i]['hour'] ?? i;
            label = "$hour-${(hour + 1) % 24}";
          }
        } else {
          if (i < phase1List.length) {
            final dateStr = phase1List[i]['date']?.toString().split('T')[0] ?? "Day ${i + 1}";
            final parts = dateStr.split('-');
            if (parts.length == 3) {
              final month = _getMonthAbbr(int.parse(parts[1]));
              label = "$month-${parts[2]}";
            } else {
              label = dateStr;
            }
          }
        }

        tempData.add(ChartData(label, phase1, phase2, phase3, threePhase));
      }

      chartData = tempData;
      debugPrint(" Chart data loaded: ${chartData.length} entries");
    } catch (e) {
      debugPrint(' API ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    setState(() => isLoading = false);
  }

  double _getEnergyFromList(List<Map<String, dynamic>> list, int index, bool isHourly) {
    try {
      if (index < list.length) {
        final energy = isHourly
            ? list[index]['sumOfEnergyPerHour']
            : list[index]['dailySumOfEnergy'];
        return (energy ?? 0).toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
              children: [

                _buildPhaseButtons(),

                const SizedBox(height: 20),


                _buildCardsSection(),

                const SizedBox(height: 20),


                _buildEnergyChart(),
              ],
            );


  }


  Widget _buildPhaseButtons() {
    final phases = ["3-PHASE", "PHASE A", "PHASE B", "PHASE C"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: phases.map((phase) {
        final isSelected = selectedPhase == phase;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedPhase = phase;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.green : Color(0xFF1A1F2E),
                foregroundColor: isSelected ? Colors.black : Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                phase,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }


  Widget _buildCardsSection() {
    if (selectedPhase == "3-PHASE") {

      return _buildThreePhaseAggregatedCard();
    } else {

      String phaseKey = selectedPhase == "PHASE A"
          ? 'phaseOne'
          : selectedPhase == "PHASE B"
          ? 'phaseTwo'
          : 'phaseThree';

      return _buildPhaseCard(selectedPhase, phaseCardsData[phaseKey]!);
    }
  }


  Widget _buildThreePhaseAggregatedCard() {
    final data = phaseCardsData['threePhase']!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF2A3142), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 5,
                backgroundColor: Color(0xFF00BCD4),
              ),
              const SizedBox(width: 8),
              Text(
                '3-PHASE ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDataRow(
            'VOLTAGE',
            formatNumber(data['voltage']),
            'V',
          ),
          const SizedBox(height: 12),
          _buildDataRow(
            'CURRENT',
            formatNumber(data['current']),
            'A',
          ),
          const SizedBox(height: 12),
          _buildDataRow(
            'POWER',
            formatNumber(data['power']),
            'kW',
          ),
          const SizedBox(height: 12),
          _buildDataRow(
            'APPARENT POWER',
            formatNumber((data['apparentPower'] ?? 0).toDouble()),
            'KVA',
          ),

          const SizedBox(height: 12),
          _buildDataRow(
            'REACTIVE POWER',
            formatNumber(data['reactivePower']),
            'KVAR',
          ),

          const SizedBox(height: 12),
          _buildDataRow(
            'FREQUENCY',
            formatNumber(data['frequency']),
            'Hz',
          ),
          const SizedBox(height: 12),
          _buildDataRow('PF', formatNumber(data['pf'] ?? 0), ''),
        ],
      ),
    );
  }


  Widget _buildPhaseCard(String title, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF2A3142), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 5, backgroundColor: data['color']),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: data['color'],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDataRow(
            'VOLTAGE',
            formatNumber((data['voltage'] ?? 0).toDouble()),
            'V',
          ),
          const SizedBox(height: 12),
          _buildDataRow(
            'CURRENT',
            formatNumber((data['current'] ?? 0).toDouble()),
            'A',
          ),
          const SizedBox(height: 12),
          _buildDataRow(
            'POWER',
            formatNumber((data['power'] ?? 0).toDouble()),
            'KW',
          ),
          const SizedBox(height: 12),
          _buildDataRow(
            'APPARENT POWER',
            formatNumber((data['apparentPower'] ?? 0).toDouble()),
            'KVA',
          ),



          const SizedBox(height: 12),
          _buildDataRow(
            'REACTIVE POWER',
            formatNumber((data['reactivePower'] ?? 0).toDouble()),
            'KVAR',
          ),

          const SizedBox(height: 12),
          _buildDataRow(
            'FREQUENCY',
            formatNumber((data['frequency'] ?? 0).toDouble()),
            'Hz',
          ),
          const SizedBox(height: 12),
          _buildDataRow('PF', formatNumber((data['pf'] ?? 0).toDouble()), ''),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  Widget _buildEnergyChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF2A3142), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children:  [
                  Image.asset(
                    "assets/icons/enrgy.png",
                    width: 18,
                    height: 18,
                    color:  Colors.green,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Energy",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    "(KWh)",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),


              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E1A),
                    border: Border.all(color: Colors.white30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF0A0E1A),
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFF2A3142)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedTimeFilter,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                    onSelected: (value) {
                      setState(() => selectedTimeFilter = value);
                      loadEnergyData();
                    },
                    itemBuilder: (context) {
                      return filterOptions.map((choice) {
                        final isSelected = choice == selectedTimeFilter;
                        return PopupMenuItem<String>(
                          value: choice,
                          padding: EdgeInsets.zero,
                          child: Container(
                            width: double.infinity,
                            padding:
                            const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF161A2A)
                                  : const Color(0xFF0A0E1A),
                            ),
                            child: Text(
                              choice,
                              style: TextStyle(
                                color:
                                isSelected ? Colors.white : Colors.white70,
                                fontSize: 13,
                                fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 300,
            child: isLoading
                ? const Center(
              child:
              CircularProgressIndicator(color: Colors.green),
            )
                : chartData.isEmpty
                ? const Center(
              child: Text(
                "No data available",
                style: TextStyle(color: Colors.white54),
              ),
            )
                : Row(
              children: [
                // Rotated Y-axis label
                const SizedBox(
                  width: 18,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'Energy (kWH)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Chart expands to fill remaining space
                Expanded(
                  child: _buildBarChart(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildChartLegend(),
        ],
      ),
    );
  }


  Widget _buildBarChart() {
    final isHourly =
        selectedTimeFilter == 'Today' || selectedTimeFilter == 'Yesterday';

    List<CartesianSeries<ChartData, String>> seriesList;

    if (selectedPhase == "3-PHASE") {
      seriesList = [
        _barSeries(Colors.green, (d) => d.phase1, "Phase A"),
        _barSeries(const Color(0xFFFFB74D), (d) => d.phase2, "Phase B"),
        _barSeries(Colors.red, (d) => d.phase3, "Phase C"),
        _barSeries(const Color(0xFF00BCD4), (d) => d.phase4, "Three Phase"),
      ];
    } else {
      Color phaseColor = selectedPhase == "PHASE A"
          ? Colors.green
          : selectedPhase == "PHASE B"
          ? const Color(0xFFFFB74D)
          : Colors.red;

      int phaseIndex = selectedPhase == "PHASE A"
          ? 1
          : selectedPhase == "PHASE B"
          ? 2
          : 3;

      seriesList = [
        _barSeries(
          phaseColor,
              (d) => phaseIndex == 1
              ? d.phase1
              : phaseIndex == 2
              ? d.phase2
              : d.phase3,
          selectedPhase,
        ),
      ];
    }


    final allValues = chartData.expand((d) => [
      d.phase1,
      d.phase2,
      d.phase3,
      d.phase4,
    ]).toList();

    final minY = _safeMin(allValues);
    final maxY = _safeMax(allValues);

    final range = (maxY - minY);

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      backgroundColor: Colors.transparent,
      zoomPanBehavior: _zoomPanBehavior,
      tooltipBehavior: _tooltipBehavior,
      primaryXAxis: CategoryAxis(
        labelRotation: -45,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 10),
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 1, color: Colors.white24),
        autoScrollingDelta: 6,
        autoScrollingMode: AutoScrollingMode.start,
      ),
      primaryYAxis: NumericAxis(
        minimum: minY - (range * 0.1),
        maximum: maxY + (range * 0.1),
        interval: _getNiceInterval(range).roundToDouble(),
        numberFormat: NumberFormat('#'),

        labelFormat: '{value}',

        majorTickLines: const MajorTickLines(size: 0),
        minorTicksPerInterval: 0,
        labelStyle:
        const TextStyle(color: Colors.white70, fontSize: 11),
        axisLine: const AxisLine(width: 1, color: Colors.white24),
        majorGridLines: const MajorGridLines(
          width: 1,
          color: Colors.white12,
          dashArray: [5, 5],
        ),
      ),
      series: seriesList,
    );
  }


  ColumnSeries<ChartData, String> _barSeries(
      Color color,
      double Function(ChartData) mapper,
      String name,
      ) {
    return ColumnSeries<ChartData, String>(
      dataSource: chartData,
      xValueMapper: (d, _) => d.month,
      yValueMapper: (d, _) => mapper(d),
      name: name,
      color: color,
      borderRadius: BorderRadius.circular(6),
      width: 0.6,
      spacing: 0.05,
    );
  }


  Widget _buildChartLegend() {
    if (selectedPhase == "3-PHASE") {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _LegendDot("Phase A", Colors.green),
          _LegendDot("Phase B", Color(0xFFFFB74D)),
          _LegendDot("Phase C", Colors.red),
          _LegendDot("Three Phase", Color(0xFF00BCD4)),
        ],
      );
    }

    Color color = selectedPhase == "PHASE A"
        ? Colors.green
        : selectedPhase == "PHASE B"
        ? const Color(0xFFFFB74D)
        : Colors.red;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [_LegendDot(selectedPhase, color)],
    );
  }
}


class _LegendDot extends StatelessWidget {
  final String text;
  final Color color;

  const _LegendDot(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}

double _safeMin(List<double> values) {
  values = values.where((e) => !e.isNaN && e.isFinite).toList();
  return values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
}

double _safeMax(List<double> values) {
  values = values.where((e) => !e.isNaN && e.isFinite).toList();
  return values.isEmpty ? 10 : values.reduce((a, b) => a > b ? a : b);
}

double _getNiceInterval(double range) {
  if (range <= 10) return 2;
  if (range <= 50) return 5;
  if (range <= 100) return 10;
  if (range <= 200) return 20;
  if (range <= 500) return 50;
  return 100;
}


class ChartData {
  ChartData(this.month, this.phase1, this.phase2, this.phase3, this.phase4);

  final String month;
  final double phase1;
  final double phase2;
  final double phase3;
  final double phase4;
}