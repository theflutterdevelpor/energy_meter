
import 'package:energy_meter/pages/report_screens/report_screen.dart';
import 'package:flutter/material.dart';
import '../../widgets/date_picker.dart';
import '../../widgets/notification.dart';
import '../../widgets/profile_drawer.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  String selectedBuilding = 'Building 01';
  String selectedFloor = 'Select Floor';
  String selectedSpace = 'Space';
  String selectedType = 'Type';
  String selectedDevice = 'Select Device';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


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
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context){
                  return ReportsPage();
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
              child:
              const Text("Configuration", style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 8),
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
              child: const Text("Schedule", style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => NotificationScreen()));
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            /// Row 1: Building + Floor
            Row(
              children: [
                Expanded(
                  child: buildDropdown(
                    value: selectedBuilding,
                    items: ['Building 01', 'Building 02', 'Building 03'],
                    onChanged: (v) =>
                        setState(() => selectedBuilding = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: buildDropdown(
                    value: selectedFloor,
                    items: [
                      'Select Floor',
                      'Ground Floor',
                      'Floor 1',
                      'Floor 2',
                      'Floor 3'
                    ],
                    onChanged: (v) =>
                        setState(() => selectedFloor = v!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// Row 2: Space + Type
            Row(
              children: [
                Expanded(
                  child: buildDropdown(
                    value: selectedSpace,
                    items: ['Space', 'Space 01', 'Space 02'],
                    onChanged: (v) =>
                        setState(() => selectedSpace = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: buildDropdown(
                    value: selectedType,
                    items: ['Type', 'Type A', 'Type B', 'Type C'],
                    onChanged: (v) =>
                        setState(() => selectedType = v!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// Row 3: Device
            buildDropdown(
              value: selectedDevice,
              items: ['Select Device', 'Device A', 'Device B', 'Device C'],
              onChanged: (v) =>
                  setState(() => selectedDevice = v!),
            ),

            const SizedBox(height: 10),

            /// Calendar
            SizedBox(
              height: 350,
              child: DatePicker(),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------- Dropdown Widget ----------
  Widget buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return SizedBox(
      height: 36,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            items: items
                .map(
                  (e) => DropdownMenuItem(
                value: e,
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(e),
                ),
              ),
            )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
