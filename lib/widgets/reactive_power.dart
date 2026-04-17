import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../services/energy_services.dart';

class ReactiveBarChart extends StatefulWidget {
  final String selectedFilter;
  final String selectedPhase;
  const ReactiveBarChart({Key? key , required this.selectedFilter,required this.selectedPhase,}) : super(key: key);

  @override
  State<ReactiveBarChart> createState() => _ReactiveBarChartState();
}

class _ReactiveBarChartState extends State<ReactiveBarChart> {
  List<ChartData> data = [];
  bool isLoading = false;
  late TooltipBehavior _tooltipBehavior;



  double maxYValue = 50.0;
  late ZoomPanBehavior _zoomPanBehavior;


  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true,activationMode: ActivationMode.singleTap);
    _zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true,
      zoomMode: ZoomMode.x,
    );
    loadReactivePowerData();

  }



  String dateFormat(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  String _getMonthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

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



  Future<void> loadReactivePowerData() async {
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

      final phase1List =
          (apiData['phaseOneData'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final phase2List =
          (apiData['phaseTwoData'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final phase3List =
          (apiData['phaseThreeData'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final threePhaseList =
          (apiData['threePhaseData'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      final maxLength = [
        phase1List.length,
        phase2List.length,
        phase3List.length,
        threePhaseList.length
      ].reduce((a, b) => a > b ? a : b);

      if (maxLength == 0) {
        setState(() {
          data = [];
          isLoading = false;
        });
        return;
      }

      List<ChartData> chartData = [];
      double maxValue = 0;

      bool isHourly =
          phase1List.isNotEmpty && phase1List[0].containsKey('hour');

      for (int i = 0; i < maxLength; i++) {
        final p1 = _getReactivePowerFromList(phase1List, i, isHourly);
        final p2 = _getReactivePowerFromList(phase2List, i, isHourly);
        final p3 = _getReactivePowerFromList(phase3List, i, isHourly);
        final p4 = _getReactivePowerFromList(threePhaseList, i, isHourly);

        maxValue = [maxValue, p1, p2, p3, p4]
            .reduce((a, b) => a > b ? a : b);

        String label = "Day ${i + 1}";

        if (isHourly) {
          if (i < phase1List.length) {
            final hour = phase1List[i]['hour'] ?? i;
            label = "$hour-${(hour + 1) % 24}";
          }
        } else {
          if (i < phase1List.length) {
            final dateStr =
                phase1List[i]['date']?.toString().split('T')[0] ??
                    "Day ${i + 1}";

            final parts = dateStr.split('-');

            if (parts.length == 3) {
              final month = _getMonthAbbr(int.parse(parts[1]));
              label = "$month-${parts[2]}";
            } else {
              label = dateStr;
            }
          }
        }

        chartData.add(ChartData(label, p1, p2, p3, p4));
      }

      maxYValue =
      maxValue > 0 ? ((maxValue / 10).ceil() * 10).toDouble() : 50.0;

      if (maxYValue < 10) maxYValue = 10;

      setState(() {
        data = chartData;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error loading reactive power data"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => isLoading = false);
  }



  double _getReactivePowerFromList(
      List<Map<String, dynamic>> list,
      int index,
      bool isHourly,
      ) {
    if (index < list.length) {
      final item = list[index];

      final value = isHourly
          ? (item['avgReactivePowerPerHour'] ??
          item['avgReactivePower'] ??
          item['reactivePower'] ??
          item['kVAR'])
          : (item['dailyAvgReactivePower'] ??
          item['avgReactivePower'] ??
          item['reactivePower'] ??
          item['kVAR']);

      if (value == null) return 0;

      return (value is num)
          ? value.toDouble()
          : double.tryParse(value.toString()) ?? 0;
    }
    return 0;
  }

  @override
  void didUpdateWidget(covariant ReactiveBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilter != widget.selectedFilter ||
        oldWidget.selectedPhase != widget.selectedPhase) {
      loadReactivePowerData();
    }
  }

  List<ColumnSeries<ChartData, String>> _buildSeries() {
    switch (widget.selectedPhase) {
      case "PHASE A":
        return [_barSeries(const Color(0xFF00E676), (d) => d.phase1, "Phase A")];
      case "PHASE B":
        return [_barSeries(const Color(0xFFFFA726), (d) => d.phase2, "Phase B")];
      case "PHASE C":
        return [_barSeries(const Color(0xFFEF5350), (d) => d.phase3, "Phase C")];
      case "3-PHASE":
      default:
        return [
          _barSeries(const Color(0xFF00E676), (d) => d.phase1, "Phase A"),
          _barSeries(const Color(0xFFFFA726), (d) => d.phase2, "Phase B"),
          _barSeries(const Color(0xFFEF5350), (d) => d.phase3, "Phase C"),
          _barSeries(const Color(0xFFFFEB3B), (d) => d.phase4, "Three Phase"),
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
      xValueMapper: (d, _) => d.month,
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
      margin: EdgeInsets.zero,
      color: Color(0xFF1A1F2E),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding:  EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Reactive Power\n(kVAR)",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),


                ],
              ),

              const SizedBox(height: 16),


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
                        'ReactivePower(KVAR)',
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
      )
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
        maximum: 40,
        interval: 20,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
        axisLine: const AxisLine(width: 1, color: Colors.white24),
        majorGridLines: const MajorGridLines(
            width: 1, color: Colors.white12, dashArray: [5, 5]),
      ),
      series: _buildSeries(),


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
        Text(text, style:  TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}


class ChartData {
  ChartData(this.month, this.phase1, this.phase2, this.phase3, this.phase4);

  final String month;
  final double phase1;
  final double phase2;
  final double phase3;
  final double phase4;
}