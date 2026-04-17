
import 'package:energy_meter/pages/report_screens/schedule.dart';
import 'package:energy_meter/pages/report_screens/sensor_detail_screen.dart';
import 'package:flutter/material.dart';


import '../../models/response/device_response.dart';
import '../../services/auth_services.dart';
import '../../services/device_service.dart';
import '../../widgets/notification.dart';
import '../../widgets/profile_drawer.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Map<String, dynamic>> buildings = [];
  List<Map<String, dynamic>> floors = [];
  List<DeviceModel> allDevices = [];

  String? selectedBuildingId;
  String? selectedFloorId;
  String selectedSensorLabel = 'All';
  bool isLoading = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Map<String, String?> sensorMap = {
    'All': null,
    'Energy': 'Energy Meter',
    'Temperature': 'Temperature Sensor',
    'Gas': 'Gas Sensor',
    'Motion': 'Motion Sensor',
  };

  @override
  void initState() {
    super.initState();
    fetchBuildingsAndDevices();
  }

  Future<void> fetchBuildingsAndDevices() async {
    setState(() => isLoading = true);

    try {
      debugPrint("🔄 Fetching buildings...");
      final buildingResponse = await ApiService.getRequest('/org/buildings');

      debugPrint("🔄 Fetching devices...");
      allDevices = await DeviceService.getDevices();

      if (buildingResponse['success'] == true &&
          buildingResponse['data'] != null) {
        setState(() {
          buildings = List<Map<String, dynamic>>.from(buildingResponse['data']);
          selectedBuildingId = null;
          selectedFloorId = null;
          floors = [];
          isLoading = false;
        });

        debugPrint("✅ Buildings loaded: ${buildings.length}");
        debugPrint("✅ Total Devices loaded: ${allDevices.length}");
      }
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      setState(() => isLoading = false);
    }
  }

  void updateFloorsForBuilding(String buildingId) {

    final floorsMap = <String, Map<String, dynamic>>{};

    for (var device in allDevices) {
      if (device.building?.id == buildingId && device.floor != null) {
        floorsMap[device.floor!.id] = {
          '_id': device.floor!.id,
          'label': device.floor!.label,
        };
      }
    }


    floors = floorsMap.values.toList();

    debugPrint("🏛️ Available floors for building:");
    for (var f in floors) {
      debugPrint("   - ${f['label']} (${f['_id']})");
    }
  }

  bool get hasFiltersSelected {
    return selectedBuildingId != null &&
        selectedFloorId != null &&
        selectedSensorLabel != 'All';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const ProfileDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child:
              const Text("Configuration", style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return SchedulePage();
                }));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white70,
                foregroundColor: Colors.black,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text("Schedule", style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) {
                return NotificationScreen();
              }));
            },
            icon: const Icon(Icons.notifications_none, color: Colors.black),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
              child: const CircleAvatar(
                backgroundImage: AssetImage("assets/images/profile.png"),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else
              Column(
                children: [
                  // 🏢 BUILDING DROPDOWN
                  buildDropdown(
                    value: selectedBuildingId,
                    hint: 'Select Building',
                    items: buildings.map((b) => b['_id']).toList(),
                    labelMap: {for (var b in buildings) b['_id']: b['name']},
                    onChanged: (value) {
                      setState(() {
                        selectedBuildingId = value;
                        selectedFloorId = null;
                        updateFloorsForBuilding(value);

                        final building =
                        buildings.firstWhere((b) => b['_id'] == value);
                        debugPrint("🏢 Selected: ${building['name']}");
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // 🧱 FLOOR DROPDOWN
                  buildDropdown(
                    value: selectedFloorId,
                    hint: 'Select Floor',
                    items: floors.map((f) => f['_id']).toList(),
                    labelMap: {for (var f in floors) f['_id']: f['label']},
                    onChanged: (value) {
                      setState(() {
                        selectedFloorId = value;
                        debugPrint("🏛️ Selected Floor: $value");
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // 📊 SENSOR TYPE
                  buildDropdown(
                    value: selectedSensorLabel,
                    hint: "Select Sensor",
                    items: sensorMap.keys.toList(),
                    onChanged: (v) {
                      setState(() => selectedSensorLabel = v);
                      debugPrint("🔧 Selected Sensor: $v");
                    },
                  ),
                ],
              ),

            const SizedBox(height: 16),

            Expanded(
              child: hasFiltersSelected
                  ? SensorDetailScreen(
                buildingId: selectedBuildingId,
                floorId: selectedFloorId == 'all'
                    ? null
                    : selectedFloorId, // Pass null for "All Floors"
                deviceName: sensorMap[selectedSensorLabel],
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please select filters',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose building, floor, and sensor type to view data',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDropdown({
    String? value,
    required String hint,
    required List items,
    required Function(dynamic) onChanged,
    Map<dynamic, String>? labelMap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          value: value,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(hint),
          ),
          isExpanded: true,
          items: items.map((id) {
            final text = labelMap?[id] ?? id.toString();
            return DropdownMenuItem(
              value: id,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(text),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}