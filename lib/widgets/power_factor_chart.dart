import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../services/energy_services.dart';

class PowerFactorChart extends StatefulWidget {
  final String selectedFilter;
  final String selectedPhase;
  const PowerFactorChart({Key? key, required this.selectedFilter,required this.selectedPhase}) : super(key: key);

  @override
  State<PowerFactorChart> createState() => _PowerFactorChartState();
}

class _PowerFactorChartState extends State<PowerFactorChart> {
  List<ChartData> data = [];
  bool isLoading = false;
  late TooltipBehavior _tooltipBehavior;



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
        fromDate = now.subtract(const Duration(days: 1));
        toDate = now.subtract(const Duration(days: 1));
        break;

      case 'Week':
        fromDate = now.subtract(const Duration(days: 6));
        toDate = now;
        break;

      case '30 Days':
        fromDate = now.subtract(const Duration(days: 29));
        toDate = now;
        break;

      case '6 Months':
        fromDate = DateTime(
          now.year,
          now.month - 6,
          now.day,
        );
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

  Future<void> loadPowerFactorData() async {
    setState(() => isLoading = true);

    final dates = getDateRange(widget.selectedFilter);

    try {
      Map<String, dynamic> response;

      if (widget.selectedFilter == 'Today' || widget.selectedFilter == 'Yesterday') {
        response = await EnergyService.fetchEnergyHourly(
          date: dates['fromDate']!,
        );
      } else {
        response = await EnergyService.fetchEnergy(
          fromDate: dates['fromDate']!,
          toDate: dates['toDate']!,
        );
      }

      if (!mounted) return;

      final apiData = response['data'];


      final phase1List = (apiData['phaseOneData'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final phase2List = (apiData['phaseTwoData'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final phase3List = (apiData['phaseThreeData'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final threePhaseList = (apiData['threePhaseData'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      bool isHourly = phase1List.isNotEmpty && phase1List[0].containsKey('hour');

      debugPrint("Is Hourly: $isHourly");
      debugPrint("Phase 1 length: ${phase1List.length}");
      debugPrint("Phase 2 length: ${phase2List.length}");
      debugPrint("Phase 3 length: ${phase3List.length}");
      debugPrint("Three Phase length: ${threePhaseList.length}");


      if (phase1List.isNotEmpty) debugPrint("Phase 1 sample: ${phase1List[0]}");
      if (phase2List.isNotEmpty) debugPrint("Phase 2 sample: ${phase2List[0]}");
      if (phase3List.isNotEmpty) debugPrint("Phase 3 sample: ${phase3List[0]}");
      if (threePhaseList.isNotEmpty) debugPrint("Three Phase sample: ${threePhaseList[0]}");

      final maxLength = [
        phase1List.length,
        phase2List.length,
        phase3List.length,
        threePhaseList.length
      ].reduce((a, b) => a > b ? a : b);

      List<ChartData> chartData = [];

      for (int i = 0; i < maxLength; i++) {
        final phase1 = _getPowerFactorFromList(phase1List, i, isHourly);
        final phase2 = _getPowerFactorFromList(phase2List, i, isHourly);
        final phase3 = _getPowerFactorFromList(phase3List, i, isHourly);
        final threePhase = _getPowerFactorFromList(threePhaseList, i, isHourly);


        debugPrint("Index $i - P1: $phase1, P2: $phase2, P3: $phase3, ThreePhase: $threePhase");

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

        chartData.add(ChartData(label, phase1, phase2, phase3, threePhase));
      }

      setState(() {
        data = chartData;
      });

      debugPrint(" Power Factor chart data loaded: ${data.length} entries");
    } catch (e, stackTrace) {
      debugPrint(' POWER FACTOR API ERROR: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading power factor data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => isLoading = false);
  }

  double _getPowerFactorFromList(List<Map<String, dynamic>> list, int index, bool isHourly) {
    try {
      if (index < list.length) {
        final item = list[index];


        final powerFactor = isHourly
            ? (item['avgPowerFactorPerHour'] ?? item['avgPowerFactor'] ?? item['powerFactor'] ?? item['pf'])
            : (item['dailyAvgPowerFactor'] ?? item['avgPowerFactor'] ?? item['powerFactor'] ?? item['pf']);

        debugPrint("Power Factor extraction - Index: $index, IsHourly: $isHourly, Raw value: $powerFactor");

        if (powerFactor == null) {
          debugPrint(" NULL power factor at index $index. Item keys: ${item.keys}");
          return 0.0;
        }

        return (powerFactor is num) ? powerFactor.toDouble() : double.tryParse(powerFactor.toString()) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      debugPrint(' Error extracting power factor at index $index: $e');
      return 0.0;
    }
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  late ZoomPanBehavior _zoomPanBehavior;


  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true, activationMode: ActivationMode.singleTap);
    _zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true,
      zoomMode: ZoomMode.x,
    );
    loadPowerFactorData();

  }

  @override
  void didUpdateWidget(covariant PowerFactorChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilter != widget.selectedFilter ||
        oldWidget.selectedPhase != widget.selectedPhase) {
      loadPowerFactorData();
    }
  }

  List<LineSeries<ChartData, String>> _buildSeries() {
    switch (widget.selectedPhase) {
      case "PHASE A":
        return [_lineSeries(const Color(0xFF00E676), (d) => d.phase1, "Phase A")];
      case "PHASE B":
        return [_lineSeries(const Color(0xFFFFA726), (d) => d.phase2, "Phase B")];
      case "PHASE C":
        return [_lineSeries(const Color(0xFFEF5350), (d) => d.phase3, "Phase C")];
      case "3-PHASE":
      default:
        return [
          _lineSeries(const Color(0xFF00E676), (d) => d.phase1, "Phase A"),
          _lineSeries(const Color(0xFFFFA726), (d) => d.phase2, "Phase B"),
          _lineSeries(const Color(0xFFEF5350), (d) => d.phase3, "Phase C"),
          _lineSeries(const Color(0xFFFFEB3B), (d) => d.phase4, "Three Phase"),
        ];
    }
  }

  LineSeries<ChartData, String> _lineSeries(
      Color color,
      double? Function(ChartData) mapper,
      String name,
      ) {
    return LineSeries<ChartData, String>(
      name: name,
      dataSource: data,
      xValueMapper: (d, _) => d.time,
      yValueMapper: (d, _) => mapper(d),
      color: color,
      width: 2.5,
      markerSettings: MarkerSettings(
        isVisible: true,
        height: 7,
        width: 7,
        shape: DataMarkerType.circle,
        color: color,
        borderColor: color,
        borderWidth: 1,
      ),
    );
  }


  Widget _buildLegend() {
    final legendMap = widget.selectedPhase == "3-PHASE"
        ? [
      ["Phase A", const Color(0xFF00E676)],
      ["Phase B", const Color(0xFFFFA726)],
      ["Phase C", const Color(0xFFEF5350)],
      ["Three Phase", const Color(0xFFFFEB3B)],
    ]
        : widget.selectedPhase == "PHASE A"
        ? [["Phase A", const Color(0xFF00E676)]]
        : widget.selectedPhase == "PHASE B"
        ? [["Phase B", const Color(0xFFFFA726)]]
        : [["Phase C", const Color(0xFFEF5350)]];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: legendMap.map((item) {
        return Padding(
          padding: const EdgeInsets.only(right: 15),
          child: _LegendDot(item[0] as String, item[1] as Color),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isHourlyView = widget.selectedFilter == 'Today' || widget.selectedFilter == 'Yesterday';

    return Card(
      color: Color(0xFF1A1F2E),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding:  EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                  "Power Factor\n(0-1)",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ],
            ),
            const SizedBox(height: 16),

            // Chart
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
                  : data.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.inbox, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      "No power factor data available",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
                  : Row(
                children: [
                  // Y-axis label
                  RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'PowerFactor(Hz)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),

                  Expanded(
                    child: _buildChart(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(height: 30, child: _buildLegend()),



          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return SfCartesianChart(
      tooltipBehavior: _tooltipBehavior,
      plotAreaBorderWidth: 0,
      backgroundColor: Colors.transparent,
      zoomPanBehavior: _zoomPanBehavior,
      primaryXAxis: CategoryAxis(
        labelStyle: const TextStyle(fontSize: 11, color: Colors.white70),
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 1, color: Colors.white),
        autoScrollingDelta: 6,
        autoScrollingMode: AutoScrollingMode.start,
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: 1,
        interval: 0.5,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
        axisLine: const AxisLine(width: 1, color: Colors.white24), // Real Y-axis line
        majorGridLines: const MajorGridLines(width: 1, color: Colors.white12, dashArray: [5, 5]),
      ),
      series: _buildSeries(),

      // series: <LineSeries<ChartData, String>>[
      //   LineSeries<ChartData, String>(
      //     name: 'Phase 1',
      //     dataSource: data,
      //     xValueMapper: (d, _) => d.time,
      //     yValueMapper: (d, _) => d.phase1,
      //     color: Color(0xFF00E676), // Green
      //     width: 2.5,
      //     markerSettings: const MarkerSettings(
      //       isVisible: true,
      //       height: 8,
      //       width: 8,
      //       shape: DataMarkerType.circle,
      //       color: Color(0xFF00E676),
      //       borderColor: Color(0xFF00E676),
      //       borderWidth: 1,
      //     ),
      //   ),
      //   LineSeries<ChartData, String>(
      //     name: 'Phase 2',
      //     dataSource: data,
      //     xValueMapper: (d, _) => d.time,
      //     yValueMapper: (d, _) => d.phase2,
      //     color: Color(0xFFFFA726), // Orange
      //     width: 2.5,
      //     markerSettings: const MarkerSettings(
      //       isVisible: true,
      //       height: 8,
      //       width: 8,
      //       shape: DataMarkerType.circle,
      //       color: Color(0xFFFFA726),
      //       borderColor: Color(0xFFFFA726),
      //       borderWidth: 1,
      //     ),
      //   ),
      //   LineSeries<ChartData, String>(
      //     name: 'Phase 3',
      //     dataSource: data,
      //     xValueMapper: (d, _) => d.time,
      //     yValueMapper: (d, _) => d.phase3,
      //     color: Color(0xFFEF5350), // Red
      //     width: 2.5,
      //     markerSettings: const MarkerSettings(
      //       isVisible: true,
      //       height: 8,
      //       width: 8,
      //       shape: DataMarkerType.circle,
      //       color: Color(0xFFEF5350),
      //       borderColor: Color(0xFFEF5350),
      //       borderWidth: 1,
      //     ),
      //   ),
      //   LineSeries<ChartData, String>(
      //     name: 'Three Phase',
      //     dataSource: data,
      //     xValueMapper: (d, _) => d.time,
      //     yValueMapper: (d, _) => d.phase4,
      //     color: Color(0xFFFFEB3B), // Yellow
      //     width: 2.5,
      //     markerSettings: const MarkerSettings(
      //       isVisible: true,
      //       height: 8,
      //       width: 8,
      //       shape: DataMarkerType.circle,
      //       color: Color(0xFFFFEB3B),
      //       borderColor: Color(0xFFFFEB3B),
      //       borderWidth: 1,
      //     ),
      //   ),
      // ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}

class ChartData {
  ChartData(this.time, this.phase1, this.phase2, this.phase3, this.phase4);

  final String time;
  final double? phase1;
  final double? phase2;
  final double? phase3;
  final double? phase4;
}