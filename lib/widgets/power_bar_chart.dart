import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../services/energy_services.dart';

class ActivePowerChart extends StatefulWidget {
  final String selectedFilter;
  final String selectedPhase;
  const ActivePowerChart({super.key , required this.selectedFilter,
    required this.selectedPhase,});

  @override
  State<ActivePowerChart> createState() => _ActivePowerChartState();
}

class _ActivePowerChartState extends State<ActivePowerChart> {
  List<ChartData> data = [];
  bool isLoading = false;
  late TooltipBehavior _tooltipBehavior;


  double maxYValue = 20.0;

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

  Future<void> loadActivePowerData() async {



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




      final maxLength = [
        phase1List.length,
        phase2List.length,
        phase3List.length,
        threePhaseList.length
      ].reduce((a, b) => a > b ? a : b);

      debugPrint("Max length across all phases: $maxLength");

      if (maxLength == 0) {
        debugPrint(" NO DATA - All phase lists are empty!");
        setState(() {
          data = [];
          isLoading = false;
        });
        return;
      }

      List<ChartData> chartData = [];
      double maxValue = 0.0;

      for (int i = 0; i < maxLength; i++) {
        final phase1 = _getActivePowerFromList(phase1List, i, isHourly);
        final phase2 = _getActivePowerFromList(phase2List, i, isHourly);
        final phase3 = _getActivePowerFromList(phase3List, i, isHourly);
        final threePhase = _getActivePowerFromList(threePhaseList, i, isHourly);


        maxValue = [maxValue, phase1, phase2, phase3, threePhase].reduce((a, b) => a > b ? a : b);



        String label = "Day ${i + 1}";

        if (isHourly) {
          if (i < phase1List.length) {
            final hour = phase1List[i]['hour'] ?? i;
            label = "$hour-${(hour + 1) % 24}";
          } else if (i < threePhaseList.length) {
            final hour = threePhaseList[i]['hour'] ?? i;
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
          } else if (i < threePhaseList.length) {
            final dateStr = threePhaseList[i]['date']?.toString().split('T')[0] ?? "Day ${i + 1}";
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

      maxYValue = maxValue > 0 ? ((maxValue / 10).ceil() * 10).toDouble() : 20.0;
      if (maxYValue < 10) maxYValue = 10;


      setState(() {
        data = chartData;
      });

      debugPrint(" Active Power chart data loaded: ${data.length} entries");
    } catch (e, stackTrace) {
      debugPrint(' ACTIVE POWER API ERROR: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading active power data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => isLoading = false);
  }

  double _getActivePowerFromList(List<Map<String, dynamic>> list, int index, bool isHourly) {
    try {
      if (index < list.length) {
        final item = list[index];

        final activePower = isHourly
            ? (item['avgActivePowerPerHour'] ??
            item['avgActivePower'] ??
            item['activePower'] ??
            item['power'] ??
            item['kW'] ??
            item['avgPowerPerHour'] ??
            item['avgPower'])
            : (item['dailyAvgActivePower'] ??
            item['avgActivePower'] ??
            item['activePower'] ??
            item['power'] ??
            item['kW'] ??
            item['dailyAvgPower'] ??
            item['avgPower']);

        if (activePower == null) {
          debugPrint(" NULL active power at index $index. Available keys: ${item.keys.toList()}");
          return 0.0;
        }

        final value = (activePower is num) ? activePower.toDouble() : double.tryParse(activePower.toString()) ?? 0.0;
        debugPrint(" Extracted value at index $index: $value (from field with value: $activePower)");
        return value;
      }
      return 0.0;
    } catch (e) {
      debugPrint(' Error extracting active power at index $index: $e');
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
    _tooltipBehavior = TooltipBehavior(enable: true,activationMode: ActivationMode.singleTap);
    _zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true,
      zoomMode: ZoomMode.x,
    );
    loadActivePowerData();

  }


  @override
  void didUpdateWidget(covariant ActivePowerChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilter != widget.selectedFilter ||
        oldWidget.selectedPhase != widget.selectedPhase) {
      loadActivePowerData();
    }
  }


  List<ColumnSeries<ChartData, String>> _buildSeries() {
    switch (widget.selectedPhase) {
      case "PHASE A":
        return [_barSeries(const Color(0xFF00E676), (d) => d.phase1 ?? 0, "Phase A")];
      case "PHASE B":
        return [_barSeries(const Color(0xFFFFA726), (d) => d.phase2 ?? 0, "Phase B")];
      case "PHASE C":
        return [_barSeries(const Color(0xFFEF5350), (d) => d.phase3 ?? 0, "Phase C")];
      case "3-PHASE":
      default:
        return [
          _barSeries(const Color(0xFF00E676), (d) => d.phase1 ?? 0, "Phase A"),
          _barSeries(const Color(0xFFFFA726), (d) => d.phase2 ?? 0, "Phase B"),
          _barSeries(const Color(0xFFEF5350), (d) => d.phase3 ?? 0, "Phase C"),
          _barSeries(const Color(0xFFFFEB3B), (d) => d.phase4 ?? 0, "Three Phase"),
        ];
    }
  }

  ColumnSeries<ChartData, String> _barSeries(
      Color color,
      double Function(ChartData) mapper,
      String name,
      ) {
    return ColumnSeries<ChartData, String>(
      dataSource: data,
      xValueMapper: (d, _) => d.label,
      yValueMapper: (d, _) => mapper(d),
      name: name,
      color: color,
      borderRadius: BorderRadius.circular(6),
      width: 0.6,
      spacing: 0.05,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE + DROPDOWN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Active Power\n(kW)",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),


              ],
            ),

            const SizedBox(height: 16),

            /// CHART
            Expanded(
              child: isLoading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF00E676)))
                  : data.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.inbox, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      "No active power data available",
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey),
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
                      'ActivePower(KW)',
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
        maximum: 15,
        interval: 5,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
        axisLine: const AxisLine(width: 1, color: Colors.white24),
        majorGridLines: const MajorGridLines(
            width: 1, color: Colors.white12, dashArray: [5, 5]),
      ),
      series: _buildSeries(),
      // series: <ColumnSeries<ChartData, String>>[
      //   _barSeries(const Color(0xFF00E676), (d) => d.phase1 ?? 0, "Phase 1"),
      //   _barSeries(const Color(0xFFFFA726), (d) => d.phase2 ?? 0, "Phase 2"),
      //   _barSeries(const Color(0xFFEF5350), (d) => d.phase3 ?? 0, "Phase 3"),
      //   _barSeries(const Color(0xFFFFEB3B), (d) => d.phase4 ?? 0, "Three Phase"),
      // ],
    );
  }
}

/// LEGEND DOT
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

/// DATA MODEL
class ChartData {
  ChartData(this.label, this.phase1, this.phase2, this.phase3, this.phase4);

  final String label;
  final double? phase1;
  final double? phase2;
  final double? phase3;
  final double? phase4;
}