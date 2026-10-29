import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ContactSensorChart extends StatefulWidget {
  const ContactSensorChart({super.key});

  @override
  State<ContactSensorChart> createState() => _ContactSensorChartState();
}

class _ContactSensorChartState extends State<ContactSensorChart> {
  late List<ChartData> data;
  late TooltipBehavior _tooltip;

  final List<String> filterOptions = [
    "Today",
    "Yesterday",
    "This Week",
    "This Month",
  ];

  String selectedValue = "Today";

  @override
  void initState() {
    super.initState();

    data = [
      ChartData("0", 0),
      ChartData("1", 1),
      ChartData("2", 1),
      ChartData("3", 0),
      ChartData("4", 0),
    ];

    _tooltip = TooltipBehavior(enable: true);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: screenWidth * 0.95,
          height: screenHeight * 0.45,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// TITLE + DROPDOWN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Contact Sensor\n(0-1)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      /// DROPDOWN
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selectedValue,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                              ),
                            ],
                          ),
                          onSelected: (value) {
                            setState(() => selectedValue = value);
                          },
                          itemBuilder: (context) {
                            return filterOptions.map((choice) {
                              return PopupMenuItem<String>(
                                value: choice,
                                child: Text(
                                  choice,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  /// CHART
                  Expanded(
                    child: Row(
                      children: [
                        /// Y-AXIS LABEL (VERTICAL TEXT)
                        SizedBox(
                          width: 35,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RotatedBox(
                                quarterTurns: 3,
                                child: const Text(
                                  "Contact",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// CHART WITH Y AXIS
                        Expanded(
                          child: SfCartesianChart(
                            tooltipBehavior: _tooltip,
                            plotAreaBorderWidth: 0,
                            margin: const EdgeInsets.only(right: 10),
                            primaryXAxis: CategoryAxis(
                              majorGridLines: const MajorGridLines(width: 0),
                              axisLine: const AxisLine(width: 1, color: Colors.black26),
                              labelStyle: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                            primaryYAxis: NumericAxis(
                              minimum: 0,
                              maximum: 1,
                              interval: 1,
                              labelStyle: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                              majorGridLines: const MajorGridLines(
                                width: 1,
                                color: Colors.black12,
                              ),
                              axisLine: const AxisLine(width: 1, color: Colors.black26),
                            ),
                            series: [
                              ColumnSeries<ChartData, String>(
                                dataSource: data,
                                xValueMapper: (d, _) => d.category,
                                yValueMapper: (d, _) => d.value,
                                name: "Contact",
                                color: const Color(0xFF6EBE93),
                                width: 0.6,
                                spacing: 0.2,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// LEGEND
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6EBE93),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "Contact",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// DATA MODEL
class ChartData {
  ChartData(this.category, this.value);

  final String category;
  final double value;
}