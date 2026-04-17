
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../services/auth_services.dart';
import '../../widgets/EnergyUsageRow.dart';
import '../../widgets/IndoorClimateCard.dart';
import '../../widgets/aqi_sensor_card.dart';
import '../../widgets/motion_screen.dart';
import '../../widgets/notification.dart';
import '../../widgets/profile_drawer.dart';
import '../../widgets/weather_card.dart';
import 'control_screen.dart';
import 'emergency_screen.dart';


class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  List<Map<String, dynamic>> buildings = [];
  List<Map<String, dynamic>> floors = [];

  String? selectedBuildingId;
  String selectedBuildingName = 'Select Building';

  String? selectedFloorId;
  String selectedFloorLabel = 'Select Floor';
  bool isLoading = false;

  String currentModel = 'assets/models/Plot_Complete.glb';


  @override
  void initState() {
    super.initState();
    fetchBuildings();
  }



  Future<void> fetchBuildings() async {
    setState(() => isLoading = true);

    try {
      debugPrint("🚀 HIT: /org/buildings API");
      final response = await ApiService.getRequest('/org/buildings');
      debugPrint("✅ SUCCESS: /org/buildings Module ki API HIT HO GAYI hai ");


      if (response['success'] == true && response['data'] != null) {
        final List data = response['data'];

        buildings = List<Map<String, dynamic>>.from(data);

        if (buildings.isNotEmpty) {
          final firstBuilding = buildings.first;

          selectedBuildingId = firstBuilding['_id'];
          selectedBuildingName = firstBuilding['name'];

          floors =
          List<Map<String, dynamic>>.from(firstBuilding['floors'] ?? []);

          if (floors.isNotEmpty) {
            selectedFloorId = floors.first['_id'];
            selectedFloorLabel = floors.first['label'];
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Building API Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const ProfileDrawer(),
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Buildings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationScreen()),
              );
            },
            icon: const Icon(Icons.notifications_none),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  Scaffold.of(context).openEndDrawer();
                },
                child: const CircleAvatar(
                  backgroundImage:
                  AssetImage("assets/images/profile.png"),
                ),
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:  EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        
               WeatherCard(),
               SizedBox(height: 10),
        
              // ---------------- Dropdown Row ----------------
              Row(
                children: [
                  /// ---------- BUILDING DROPDOWN ----------
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
                            value: selectedBuildingId,
                            isExpanded: true,
                            icon:  Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                            items: buildings.map((b) {
                              return DropdownMenuItem<String>(
                                value: b['_id'],
                                child: Padding(
                                  padding:  EdgeInsets.symmetric(horizontal: 6),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        'assets/icons/icon2.png',
                                        width: 18,
                                        height: 18,
                                        color: Colors.green,
                                        colorBlendMode: BlendMode.srcIn,
                                      ),
                                       SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          b['name'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              final building =
                              buildings.firstWhere((b) => b['_id'] == value);

                              setState(() {
                                selectedBuildingId = value;
                                selectedBuildingName = building['name'];

                                floors =
                                List<Map<String, dynamic>>.from(building['floors'] ?? []);

                                if (floors.isNotEmpty) {
                                  selectedFloorId = floors.first['_id'];
                                  selectedFloorLabel = floors.first['label'];
                                } else {
                                  selectedFloorId = null;
                                  selectedFloorLabel = 'Select Floor';
                                }
                                currentModel = 'assets/models/Plot_Complete.glb';
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                   SizedBox(width: 16),

                  /// ---------- FLOOR DROPDOWN ----------
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
                            value: selectedFloorId,
                            isExpanded: true,
                            icon:  Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                            items: floors.map((f) {
                              return DropdownMenuItem<String>(
                                value: f['_id'],
                                child: Padding(
                                  padding:  EdgeInsets.symmetric(horizontal: 6),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        'assets/icons/floor.png',
                                        width: 18,
                                        height: 18,
                                        color: Colors.green,
                                        colorBlendMode: BlendMode.srcIn,
                                      ),
                                       SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          f['label'],
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedFloorId = value;
                                selectedFloorLabel =
                                floors.firstWhere((f) => f['_id'] == value)['label'];

                                currentModel = 'assets/models/groudfloor.glb';
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),


              SizedBox(height: 16),
        
              // ---------------- Buttons Row ----------------
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context){
                            return ControlPage();
                          }));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.grey,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            // side: BorderSide(color: Colors.grey),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:[
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
        
                  SizedBox(width: 16),
        
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EmergencyPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            // side: BorderSide(color: Colors.grey),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
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
        
               SizedBox(height: 20),
        
              // ---------------- Indoor Climate Card (ADDED HERE) ----------------
               IndoorClimateMini(),
               SizedBox(height: 10),
        

              SizedBox(
                height: 300,
                width: double.infinity,
                child: ModelViewer(
                  key: ValueKey(currentModel), // 🔥 IMPORTANT
                  src: currentModel,
                  cameraControls: true,
                  autoRotate: false,
                  animationName: null,
                  shadowIntensity: 1,
                  exposure: 1,
                  ar: false,
                ),
              ),
        
             const  SizedBox(height: 15),
        
               EnergyUsageRow(),

              const SizedBox(height: 15),

              // const EventScreen()
               AirQualityScreen(),

              const  SizedBox(height: 20),

              // FIXED HEIGHT motion screen to stop layout error
              SizedBox(
                height: 350,
                child:  MotionScreen(),
              ),











        
        
        
        
        
        
        
            ],
          ),
        ),
      ),
    );
  }


  /// ===== REUSABLE DROPDOWN =====
  Widget _dropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String icon,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items
              .map(
                (e) => DropdownMenuItem(
              value: e,
              child: Row(
                children: [
                  Image.asset(
                    icon,
                    width: 18,
                    height: 18,
                    color: Colors.green,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  const SizedBox(width: 8),
                  Text(e),
                ],
              ),
            ),
          )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
