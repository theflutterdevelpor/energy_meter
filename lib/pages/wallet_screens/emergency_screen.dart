
import 'package:flutter/material.dart';

import '../../widgets/notification.dart';
import '../../widgets/profile_drawer.dart';
import 'control_screen.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  String selectedBuilding = 'Building 01';
  String selectedFloor = 'Select Floor';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const ProfileDrawer(),
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Emergency",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ---------------- Dropdown Row ----------------
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedBuilding,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.grey),
                            items: ['Building 01', 'Building 02', 'Building 03']
                                .map((e) => DropdownMenuItem(
                              value: e,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      'assets/icons/icon2.png',
                                      width: 18,
                                      height: 18,
                                      color: Colors.green,
                                      colorBlendMode: BlendMode.srcIn,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(e),
                                  ],
                                ),
                              ),
                            ))
                                .toList(),
                            onChanged: (v) => setState(() => selectedBuilding = v!),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedFloor,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.grey),
                            items: [
                              'Select Floor',
                              'Ground Floor',
                              'Floor 1',
                              'Floor 2',
                              'Floor 3'
                            ]
                                .map((e) => DropdownMenuItem(
                              value: e,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      'assets/icons/floor.png',
                                      width: 18,
                                      height: 18,
                                      color: Colors.green,
                                      colorBlendMode: BlendMode.srcIn,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(e),
                                  ],
                                ),
                              ),
                            ))
                                .toList(),
                            onChanged: (v) => setState(() => selectedFloor = v!),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ---------------- Buttons Row ----------------
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ControlPage()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.grey,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:  Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/control.png',
                              width: 18,
                              height: 18,
                              color: Colors.grey,
                              colorBlendMode: BlendMode.srcIn,
                            ),
                            SizedBox(width: 8),
                            Text('Control'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),


                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor:
                          Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber, size: 18),
                            SizedBox(width: 8),
                            Text('Emergency'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ---------------- نیا Image Card ----------------
              Card(
                elevation: 6,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Tip: Tap the SOS button to start alarms and alert the users",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.4),
                              blurRadius: 25,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "SOS",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Note: Once tapped nearby & emergency contacts are immediately "
                            "sent an alert call & SMS. You can cancel, if resolved.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }



}