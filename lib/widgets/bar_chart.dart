//
// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';
//
// import '../services/energy_services.dart';
//
// class barchart extends StatefulWidget {
//   const barchart({Key? key}) : super(key: key);
//
//   @override
//   State<barchart> createState() => _BarChartState();
// }
//
// class _BarChartState extends State<barchart> {
//   List<ChartData> data = [];
//   bool isLoading = false;
//   late TooltipBehavior _tooltip;
//   final List<String> filterOptions = [
//     "Today",
//     "Yesterday",
//     "Week",
//     "30 Days",
//     "6 Months",
//   ];
//
//   String selectedValue = "Today";
//
//   String dateFormat(DateTime date) =>
//       "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
//
//   Map<String, String> getDateRange(String dateFilter) {
//     DateTime today = DateTime.now();
//     DateTime now = DateTime(today.year, today.month, today.day);
//
//     DateTime fromDate, toDate;
//
//     switch (dateFilter) {
//       case 'Today':
//         fromDate = now;
//         toDate = now;
//         break;
//
//       case 'Yesterday':
//         fromDate = now.subtract(Duration(days: 1));
//         toDate = now.subtract(Duration(days: 1));
//         break;
//
//       case 'Week':
//         fromDate = now.subtract(Duration(days: 6));
//         toDate = now;
//         break;
//
//       case '30 Days':
//         fromDate = now.subtract(Duration(days: 29));
//         toDate = now;
//         break;
//       case '6 Months':
//         fromDate = DateTime(
//           now.year,
//           now.month - 6,
//           now.day,
//         );
//         toDate = now;
//         break;
//
//       default:
//         fromDate = now;
//         toDate = now;
//     }
//
//     return {
//       'fromDate': dateFormat(fromDate),
//       'toDate': dateFormat(toDate),
//     };
//   }
//
//   Future<void> loadEnergyData() async {
//     setState(() => isLoading = true);
//
//     final dates = getDateRange(selectedValue);
//
//     try {
//       Map<String, dynamic> response;
//
//
//       if (selectedValue == 'Today' || selectedValue == 'Yesterday') {
//         response = await EnergyService.fetchEnergyHourly(
//           date: dates['fromDate']!,
//         );
//       } else {
//         response = await EnergyService.fetchEnergy(
//           fromDate: dates['fromDate']!,
//           toDate: dates['toDate']!,
//         );
//       }
//
//       final apiData = response['data'];
//       debugPrint(" API CALL STARTED");
//       debugPrint("Filter: $selectedValue");
//
//
//       final phase1List = (apiData['phaseOneData'] as List?)?.cast<Map<String, dynamic>>() ?? [];
//       final phase2List = (apiData['phaseTwoData'] as List?)?.cast<Map<String, dynamic>>() ?? [];
//       final phase3List = (apiData['phaseThreeData'] as List?)?.cast<Map<String, dynamic>>() ?? [];
//       final threePhaseList = (apiData['threePhaseData'] as List?)?.cast<Map<String, dynamic>>() ?? [];
//
//
//       bool isHourly = phase1List.isNotEmpty && phase1List[0].containsKey('hour');
//
//       debugPrint("Is Hourly: $isHourly");
//       debugPrint("Phase 1 length: ${phase1List.length}");
//
//
//       final maxLength = [phase1List.length, phase2List.length, phase3List.length, threePhaseList.length]
//           .reduce((a, b) => a > b ? a : b);
//
//
//       List<ChartData> chartData = [];
//       for (int i = 0; i < maxLength; i++) {
//         final phase1 = _getEnergyFromList(phase1List, i, isHourly);
//         final phase2 = _getEnergyFromList(phase2List, i, isHourly);
//         final phase3 = _getEnergyFromList(phase3List, i, isHourly);
//         final threePhase = _getEnergyFromList(threePhaseList, i, isHourly);
//
//         String label = "Day ${i + 1}";
//
//         if (isHourly) {
//
//           if (i < phase1List.length) {
//             final hour = phase1List[i]['hour'] ?? i;
//             label = "$hour-${(hour + 1) % 24}";
//           }
//         } else {
//
//           if (i < phase1List.length) {
//             final dateStr = phase1List[i]['date']?.toString().split('T')[0] ?? "Day ${i + 1}";
//
//             final parts = dateStr.split('-');
//             if (parts.length == 3) {
//               final month = _getMonthAbbr(int.parse(parts[1]));
//               label = "$month-${parts[2]}";
//             } else {
//               label = dateStr;
//             }
//           }
//         }
//
//         chartData.add(ChartData(label, phase1, phase2, phase3, threePhase));
//       }
//
//       data = chartData;
//       debugPrint("✅ Chart data loaded: ${data.length} entries");
//     } catch (e) {
//       debugPrint('❌ API ERROR: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//
//     setState(() => isLoading = false);
//   }
//
//
//   double _getEnergyFromList(List<Map<String, dynamic>> list, int index, bool isHourly) {
//     try {
//       if (index < list.length) {
//         final energy = isHourly
//             ? list[index]['sumOfEnergyPerHour']  // Hourly
//             : list[index]['dailySumOfEnergy'];    // Daily
//         return (energy ?? 0).toDouble();
//       }
//       return 0.0;
//     } catch (e) {
//       debugPrint('Error extracting energy at index $index: $e');
//       return 0.0;
//     }
//   }
//
//   // ✅ Month abbreviation helper
//   String _getMonthAbbr(int month) {
//     const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
//     return months[month - 1];
//   }
//
//   @override
//   void initState() {
//     _tooltip = TooltipBehavior(enable: true);
//     loadEnergyData();
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: SizedBox(
//           width: screenWidth * 0.95,
//           height: screenHeight * 0.55,
//           child: Card(
//             color: Colors.white,
//             elevation: 6,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   ///  TITLE + DROPDOWN
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Row(
//                         children: const [
//                           Icon(Icons.bolt, color: Colors.green),
//                           SizedBox(width: 6),
//                           Text(
//                             "Energy",
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           SizedBox(width: 6),
//                           Text(
//                             "(KWh)",
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       /// DROPDOWN
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.black12),
//                           borderRadius: BorderRadius.circular(10),
//                           color: Colors.white,
//                         ),
//                         child: PopupMenuButton<String>(
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 selectedValue,
//                                 style: const TextStyle(
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               const Icon(Icons.keyboard_arrow_down, size: 20),
//                             ],
//                           ),
//                           onSelected: (String value) {
//                             setState(() {
//                               selectedValue = value;
//                             });
//                             loadEnergyData();
//                           },
//                           itemBuilder: (BuildContext context) {
//                             return filterOptions.map((String choice) {
//                               return PopupMenuItem<String>(
//                                 value: choice,
//                                 child: Text(
//                                   choice,
//                                   style: const TextStyle(
//                                     fontSize: 13,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               );
//                             }).toList();
//                           },
//                           padding: EdgeInsets.zero,
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 20),
//
//
//                   Expanded(
//                     child: isLoading
//                         ? const Center(child: CircularProgressIndicator())
//                         : data.isEmpty
//                         ? const Center(child: Text("No data available"))
//                         : Stack(
//                       children: [
//                         // Fixed Y-Axis background
//                         Positioned(
//                           left: 0,
//                           top: 0,
//                           bottom: 0,
//                           width: 50,
//                           child: Container(
//                             color: Colors.white,
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: List.generate(
//                                 6,
//                                     (index) {
//                                   final isHourly = selectedValue == 'Today' || selectedValue == 'Yesterday';
//                                   final maxValue = isHourly ? 25 : 250;
//                                   final interval = isHourly ? 5 : 50;
//                                   final value = maxValue - (index * interval);
//                                   return Padding(
//                                     padding: const EdgeInsets.only(right: 8.0),
//                                     child: Text(
//                                       value.toStringAsFixed(0),
//                                       style: const TextStyle(
//                                         fontSize: 11,
//                                         color: Colors.black,
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                           ),
//                         ),
//                         // Scrollable chart with transparent Y-axis
//                         Padding(
//                           padding: const EdgeInsets.only(left: 10),
//                           child: SingleChildScrollView(
//                             scrollDirection: Axis.horizontal,
//                             child: SizedBox(
//                               width: data.length * 50.0,
//                               child: SfCartesianChart(
//                                 tooltipBehavior: _tooltip,
//                                 primaryXAxis: CategoryAxis(
//                                   labelRotation: -45,
//                                 ),
//                                 primaryYAxis: NumericAxis(
//                                   minimum: 0,
//                                   maximum: selectedValue == 'Today' || selectedValue == 'Yesterday' ? 25 : 250,
//                                   interval: selectedValue == 'Today' || selectedValue == 'Yesterday' ? 5 : 50,
//                                   majorGridLines: const MajorGridLines(
//                                     dashArray: [5, 5],
//                                     color: Colors.grey,
//                                   ),
//                                   axisLine: const AxisLine(width: 0),
//                                   labelStyle: const TextStyle(
//                                     color: Colors.transparent,
//                                   ),
//                                 ),
//                                 series: <CartesianSeries>[
//                                   _barSeries(Colors.teal, (d) => d.phase1, "Phase 1"),
//                                   _barSeries(Color(0xFF4169E1), (d) => d.phase2, "Phase 2"),
//                                   _barSeries(Colors.green, (d) => d.phase3, "Phase 3"),
//                                   _barSeries(Color(0xFFff8c42), (d) => d.phase4, "Three Phase"),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 12),
//
//                   ///  FIXED LEGEND
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: const [
//                       _LegendDot("Phase 1", Colors.teal),
//                       _LegendDot("Phase 2", Color(0xFF4169E1)),
//                       _LegendDot("Phase 3", Colors.green),
//                       _LegendDot("Three Phase", Color(0xFFff8c42)),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   ColumnSeries<ChartData, String> _barSeries(
//       Color color,
//       double Function(ChartData) mapper,
//       String name,
//       ) {
//     return ColumnSeries<ChartData, String>(
//       dataSource: data,
//       xValueMapper: (d, _) => d.month,
//       yValueMapper: (d, _) => mapper(d),
//       name: name,
//       color: color,
//       borderRadius: BorderRadius.circular(4),
//     );
//   }
// }
//
// ///  LEGEND DOT
// class _LegendDot extends StatelessWidget {
//   final String text;
//   final Color color;
//
//   const _LegendDot(this.text, this.color);
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         CircleAvatar(radius: 5, backgroundColor: color),
//         const SizedBox(width: 6),
//         Text(text, style: const TextStyle(fontSize: 12)),
//       ],
//     );
//   }
// }
//
//
// class ChartData {
//   ChartData(this.month, this.phase1, this.phase2, this.phase3, this.phase4);
//
//   final String month;
//   final double phase1;
//   final double phase2;
//   final double phase3;
//   final double phase4;
// }

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../services/energy_services.dart';

class PhaseEnergyWidget extends StatefulWidget {
  final Map<String, dynamic>? realtimeData;
  const PhaseEnergyWidget({Key? key, this.realtimeData}) : super(key: key);

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
      'pf': 0.0,
      'color': Colors.green,
    },
    'phaseTwo': {
      'voltage': 0.0,
      'current': 0.0,
      'power': 0.0,
      'pf': 0.0,
      'color': Color(0xFFFFB74D),
    },
    'phaseThree': {
      'voltage': 0.0,
      'current': 0.0,
      'power': 0.0,
      'pf': 0.0,
      'color': Colors.red,
    },
    'threePhase': {
      'voltage': 0.0,
      'current': 0.0,
      'power': 0.0,
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

    if (widget.realtimeData != null &&
        widget.realtimeData != oldWidget.realtimeData) {

      debugPrint("⚡ PhaseEnergyWidget REALTIME UPDATE");
      debugPrint("📦 SOCKET DATA => ${widget.realtimeData}");

      final data = widget.realtimeData!;

      setState(() {

        phaseCardsData['phaseOne']!['voltage'] =
            _toDouble(data['v1'], phaseCardsData['phaseOne']!['voltage']);

        phaseCardsData['phaseTwo']!['voltage'] =
            _toDouble(data['v2'], phaseCardsData['phaseTwo']!['voltage']);

        phaseCardsData['phaseThree']!['voltage'] =
            _toDouble(data['v3'], phaseCardsData['phaseThree']!['voltage']);

        phaseCardsData['phaseOne']!['current'] =
            _toDouble(data['i1'], phaseCardsData['phaseOne']!['current']);

        phaseCardsData['phaseTwo']!['current'] =
            _toDouble(data['i2'], phaseCardsData['phaseTwo']!['current']);

        phaseCardsData['phaseThree']!['current'] =
            _toDouble(data['i3'], phaseCardsData['phaseThree']!['current']);

      });

      debugPrint("🔌 V1 => ${phaseCardsData['phaseOne']!['voltage']}");
      debugPrint("🔌 V2 => ${phaseCardsData['phaseTwo']!['voltage']}");
      debugPrint("🔌 V3 => ${phaseCardsData['phaseThree']!['voltage']}");

      debugPrint("⚡ I1 => ${phaseCardsData['phaseOne']!['current']}");
      debugPrint("⚡ I2 => ${phaseCardsData['phaseTwo']!['current']}");
      debugPrint("⚡ I3 => ${phaseCardsData['phaseThree']!['current']}");

    }
  }



  double _toDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;

    if (value is int) return value.toDouble();

    if (value is double) return value;

    if (value is String) return double.tryParse(value) ?? defaultValue;

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

      setState(() {
        phaseCardsData['phaseOne']!['voltage'] = p1['avgVoltage'] ?? 0.0;
        phaseCardsData['phaseOne']!['current'] = p1['avgCurrent'] ?? 0.0;
        phaseCardsData['phaseOne']!['power']   = p1['avgPower'] ?? 0.0;
        phaseCardsData['phaseOne']!['pf']      = p1['avgPowerFactor'] ?? 0.0;

        phaseCardsData['phaseTwo']!['voltage'] = p2['avgVoltage'] ?? 0.0;
        phaseCardsData['phaseTwo']!['current'] = p2['avgCurrent'] ?? 0.0;
        phaseCardsData['phaseTwo']!['power']   = p2['avgPower'] ?? 0.0;
        phaseCardsData['phaseTwo']!['pf']      = p2['avgPowerFactor'] ?? 0.0;

        phaseCardsData['phaseThree']!['voltage'] = p3['avgVoltage'] ?? 0.0;
        phaseCardsData['phaseThree']!['current'] = p3['avgCurrent'] ?? 0.0;
        phaseCardsData['phaseThree']!['power']   = p3['avgPower'] ?? 0.0;
        phaseCardsData['phaseThree']!['pf']      = p3['avgPowerFactor'] ?? 0.0;


        phaseCardsData['threePhase']!['voltage'] = tp['avgVoltage'] ?? 0.0;
        phaseCardsData['threePhase']!['current'] = tp['avgCurrent'] ?? 0.0;
        phaseCardsData['threePhase']!['power']   = tp['avgPower'] ?? 0.0;
        phaseCardsData['threePhase']!['pf']      = tp['avgPowerFactor'] ?? 0.0;

        print("✅ FINAL UI DATA:");
        print("Voltage: ${phaseCardsData['threePhase']!['voltage']}");
        print("Current: ${phaseCardsData['threePhase']!['current']}");
        print("Power: ${phaseCardsData['threePhase']!['power']}");
        print("PF: ${phaseCardsData['threePhase']!['pf']}");
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
            'W',
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
            'W',
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