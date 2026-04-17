import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MotionSensorChart extends StatefulWidget {
  const MotionSensorChart({Key? key}) : super(key: key);

  @override
  State<MotionSensorChart> createState() => _MotionSensorChartState();
}

class _MotionSensorChartState extends State<MotionSensorChart> {
  late List<ChartData> data;
  late TooltipBehavior _tooltip;

  final List<String> filterOptions = ["Today", "Week", "Month", "Year"];
  String selectedValue = "Today";

  @override
  void initState() {
    super.initState();
    _tooltip = TooltipBehavior(enable: true);

    data = [
      ChartData('00:00', 0),
      ChartData('04:00', 0),
      ChartData('08:00', 0),
      ChartData('12:00', 1),
      ChartData('16:00', 0),
      ChartData('20:00', 1),
      ChartData('23:59', 0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: screenWidth * 0.95,
          height: screenHeight * 0.55,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Dropdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Motion Sensor\n(0-1)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // DROPDOWN
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
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 20),
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Chart with Fixed Y-Axis
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double chartWidth = constraints.maxWidth;

                        if (data.length > 12) {
                          chartWidth = data.length * 60.0;
                        }

                        return Row(
                          children: [
                            // Y-Axis Label
                            const SizedBox(
                              width: 40,
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Text(
                                  'Motion',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Fixed Y-Axis
                            SizedBox(
                              width: 40,
                              child: Stack(
                                children: [
                                  CustomPaint(
                                    painter: YAxisPainter(),
                                    size: const Size(40, double.infinity),
                                  ),
                                  const Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('1', style: TextStyle(fontSize: 11)),
                                      Text('0', style: TextStyle(fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Scrollable Chart
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: chartWidth,
                                  child: SfCartesianChart(
                                    plotAreaBorderWidth: 0,
                                    tooltipBehavior: _tooltip,
                                    primaryXAxis: CategoryAxis(
                                      labelStyle: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black87,
                                      ),
                                      majorGridLines: const MajorGridLines(width: 0),
                                      labelRotation: 0,
                                      isVisible: true,
                                      interval: 1,
                                    ),
                                    primaryYAxis: NumericAxis(
                                      minimum: 0,
                                      maximum: 1,
                                      interval: 1,
                                      labelFormat: '{value}',
                                      isVisible: false,
                                      majorGridLines: const MajorGridLines(width: 1, color: Color(0xFFE8E8E8)),
                                    ),
                                    series: <ScatterSeries<ChartData, String>>[
                                      ScatterSeries<ChartData, String>(
                                        name: 'Motion',
                                        dataSource: data,
                                        xValueMapper: (d, _) => d.time,
                                        yValueMapper: (d, _) => d.motion,
                                        markerSettings: const MarkerSettings(
                                          isVisible: true,
                                          height: 10,
                                          width: 10,
                                          shape: DataMarkerType.circle,
                                          color: Color(0xFF6B5FFF),
                                          borderColor: Color(0xFF6B5FFF),
                                          borderWidth: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Legend
                  SizedBox(
                    height: 30,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _LegendDot("Motion", Color(0xFF6B5FFF)),
                      ],
                    ),
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

class YAxisPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(size.width - 2, 0), Offset(size.width - 2, size.height), paint);
  }

  @override
  bool shouldRepaint(YAxisPainter oldDelegate) => false;
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
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class ChartData {
  ChartData(this.time, this.motion);
  final String time;
  final int motion;
}