import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import '../../models/response/dashboard_response.dart';
import '../../models/response/device_model.dart';
import '../../models/response/profile_response.dart';
import '../../services/device_service.dart';
import '../../services/energy_socket.dart';
import '../../services/profile_services.dart';
import '../../widgets/Energy-Maintenance-Card.dart';
import '../../widgets/bar_chart.dart';
import '../../widgets/configration_screen.dart';
import '../../widgets/energystate_grid.dart';
import '../../widgets/notification.dart';
import '../../widgets/profile_drawer.dart';



class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final SocketService socketService = SocketService();

  Timer? _reconnectTimer;

  DashboardData? dashboardData;
  Map<String, dynamic>? realtimeData;
  String? _selectedDeviceId;
  List<String> _deviceIds = [];
  Map<String, String> _deviceIdToObjectId = {};
  List<Device> devices = [];
  Device? device;
  bool isLoading = true;
  bool _isSocketConnected = false;
  final String baseUrl = 'http://3.231.62.206:5000/api/v1';

  String? _currentEventName;






  @override
  void initState() {
    super.initState();
    _loadDeviceIds();
    _loadDashboardData();
    _startReconnectTimer();
  }

  Future<void> _loadDeviceIds() async {
    try {
      final devices = await DeviceService.getDevices();

      final filtered = devices
          .where((d) => d.name == "Energy Meter")
          .toList();

      final ids = filtered.map((d) => d.deviceId).toList();

      if (!mounted) return;

      setState(() {
        _deviceIds = ids;

        _deviceIdToObjectId = {
          for (var d in filtered) d.deviceId: d.id
        };

        if (ids.isNotEmpty) {
          _selectedDeviceId = ids.first;
        }
      });

      debugPrint("📱 Device IDs => $_deviceIds");
      debugPrint("📌 Default Device => $_selectedDeviceId");

      // ✅ socket connect AFTER device selected
      if (_selectedDeviceId != null) {
        await _connectAndJoinSocket();
      }

    } catch (e) {
      debugPrint("❌ Error loading devices: $e");
    }
  }


  Future<void> _connectAndJoinSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      debugPrint("❌ No token found");
      return;
    }

    debugPrint("🔑 Token found, connecting socket");

    // ✅ Disconnect existing socket if any
    if (socketService.socket?.connected ?? false) {
      socketService.disconnect();
    }

    socketService.connect(token);

    // ✅ Remove all existing listeners
    socketService.socket?.offAny();

    socketService.socket?.onConnect((_) {
      debugPrint("🟢 SOCKET CONNECTED");
      _isSocketConnected = true;
      if (_selectedDeviceId != null) {
        _joinDeviceRoom(_selectedDeviceId!);
        _listenRealtime();
      }
    });

    socketService.socket?.onDisconnect((_) {
      debugPrint("🔴 SOCKET DISCONNECTED");
      _isSocketConnected = false;
    });

    socketService.socket?.onConnectError((err) {
      debugPrint("❌ SOCKET ERROR: $err");
    });

    if (socketService.socket?.connected ?? false) {
      _isSocketConnected = true;
      if (_selectedDeviceId != null) {
        _joinDeviceRoom(_selectedDeviceId!);
        _listenRealtime();
      }
    }
  }

  void _listenRealtime() {
    if (_selectedDeviceId == null) return;

    final eventName = "ESensor-$_selectedDeviceId";
    _currentEventName = eventName;

    debugPrint("🎧 Setting up listener for: $eventName");

    socketService.socket?.off(eventName);

    socketService.socket?.on(eventName, (data) {
      debugPrint("📡 RAW SOCKET DATA RECEIVED");
      debugPrint("📦 Data: $data");

      Map<String, dynamic> parsed = {};

      try {
        if (data is Map) {
          parsed = Map<String, dynamic>.from(data);

          double powerValue = 0.0;

          if (parsed.containsKey('threePhase') && parsed['threePhase'] is Map) {
            final threePhase = parsed['threePhase'] as Map;
            if (threePhase.containsKey('power')) {
              powerValue = (threePhase['power'] as num).toDouble();

              // 🔥 FIX: Agar value 100 se zyada hai to Watts hai, KW mein convert
              if (powerValue > 100) {
                powerValue = powerValue / 1000;
                debugPrint("⚡ Converted Watts to KW: ${powerValue}KW");
              } else {
                debugPrint("⚡ Power from threePhase: ${powerValue}KW");
              }

              // 🔥 Update threePhase map with KW value
              threePhase['power'] = powerValue;
            }
          }

          // Same fix for other power fields
          if (powerValue == 0.0 && parsed.containsKey('power_w')) {
            powerValue = (parsed['power_w'] as num).toDouble();
            if (powerValue > 100) {
              powerValue = powerValue / 1000;
            }
            debugPrint("⚡ Power from power_w: ${powerValue}KW");
          }

          if (powerValue == 0.0 && parsed.containsKey('power')) {
            powerValue = (parsed['power'] as num).toDouble();
            if (powerValue > 100) {
              powerValue = powerValue / 1000;
            }
            debugPrint("⚡ Power from power: ${powerValue}KW");
          }

          double freqValue = 50.0;
          if (parsed.containsKey('threePhase') && parsed['threePhase'] is Map) {
            final threePhase = parsed['threePhase'] as Map;
            if (threePhase.containsKey('frequency')) {
              freqValue = (threePhase['frequency'] as num).toDouble();
            }
          } else if (parsed.containsKey('frequency')) {
            freqValue = (parsed['frequency'] as num).toDouble();
          }

          debugPrint("⚡ FINAL Total Power: ${powerValue}KW");
          debugPrint("📊 Frequency: ${freqValue}Hz");

          double todayEng = 0.0;
          double monthEng = 0.0;
          if (parsed.containsKey('today_energy')) {
            todayEng = (parsed['today_energy'] as num).toDouble();
          }
          if (parsed.containsKey('month_energy')) {
            monthEng = (parsed['month_energy'] as num).toDouble();
          }

          // 🔥 Store as KW already
          parsed['power_w'] = powerValue * 1000; // Store Watts for other widgets
          parsed['frequency'] = freqValue;
          parsed['today_energy'] = todayEng;
          parsed['month_energy'] = monthEng;

          // 🔥 Ensure threePhase has KW value
          if (parsed.containsKey('threePhase') && parsed['threePhase'] is Map) {
            (parsed['threePhase'] as Map)['power'] = powerValue;
          }
        }

        parsed['deviceId'] ??= parsed['deviceId'] ?? _selectedDeviceId;

      } catch (e) {
        debugPrint("❌ Parse error: $e");
      }

      if (!mounted) return;

      setState(() {
        realtimeData = Map.from(parsed);
      });

      debugPrint("✅ FINAL realtimeData => $realtimeData");
    });
  }

  void _joinDeviceRoom(String deviceId) {
    if (socketService.socket?.connected ?? false) {
      debugPrint("📡 EMIT join-device for: $deviceId");
      socketService.socket?.emit("join-device", {"deviceId": deviceId});

      Future.delayed(Duration(milliseconds: 500), () {
        socketService.socket?.emit("get-realtime", {"deviceId": deviceId});
      });
    } else {
      debugPrint("⚠️ Socket not connected. Cannot join device room.");
    }
  }

  void _startReconnectTimer() {
    _reconnectTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkSocketConnection();
    });
  }

  void _checkSocketConnection() {
    if (!_isSocketConnected && _selectedDeviceId != null) {
      debugPrint("?? Socket disconnected, attempting reconnect...");
      _connectAndJoinSocket();
    }
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  @override
  void dispose() {
    debugPrint("?? Dashboard dispose - Cleaning up socket");
    _stopReconnectTimer();
    if (_currentEventName != null) {
      socketService.socket?.off(_currentEventName!);
    }
    socketService.disconnect();
    super.dispose();
  }



  Future<void> fetchDeviceData(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      debugPrint("🔐 Token: $token");

      if (token == null) {
        debugPrint("❌ No token found");
        return;
      }

      final url = '$baseUrl/org/devices?deviceId=$deviceId';
      debugPrint("🌐 API URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('Timeout'),
      );

      debugPrint("📡 Status Code: ${response.statusCode}");
      debugPrint("📦 Raw Response: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        debugPrint("✅ Parsed JSON: $jsonData");

        final result = DeviceResponse.fromJson(jsonData);

        debugPrint("📊 Total Devices: ${result.data.length}");

        if (result.data.isNotEmpty) {
          final device = result.data.first;

          debugPrint("🔌 Device Name: ${device.name}");
          debugPrint("🆔 Device ID: ${device.deviceId}");
          debugPrint("📶 Status: ${device.status}");

          debugPrint("📡 Sensors List:");
          for (var sensor in device.sensors) {
            debugPrint("➡️ ${sensor.name} (${sensor.unit})");
          }

          setState(() {
            this.device = device;
          });
        } else {
          debugPrint("⚠️ No device found");
        }
      } else {
        debugPrint("❌ API Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
    }
  }







  Future<void> _loadDashboardData() async {
    try {

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (!mounted) return;

      if (token == null) {

        setState(() => isLoading = false);
        return;
      }




      final response = await http.get(
        Uri.parse('$baseUrl/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final dashboardResponse = DashboardResponse.fromJson(jsonDecode(response.body));





        if (dashboardResponse.success && dashboardResponse.data != null) {
          setState(() {
            dashboardData = dashboardResponse.data;
            isLoading = false;
          });





        } else {

          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {

      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const ProfileDrawer(),
      backgroundColor:  Color(0xFF121821),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
        ),
        actions: [
          if (_deviceIds.length > 1)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 0),
              constraints: const BoxConstraints(maxWidth: 90,maxHeight: 36),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 0.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDeviceId,
                  isExpanded: true,
                  isDense: true,
                  dropdownColor: const Color(0xFF2C2C2E),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white54,
                    size: 16,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (value) {
                    if (value == null) return;
                    debugPrint(" Device Changed => $value");

                    setState(() {
                      _selectedDeviceId = value;
                      realtimeData=null;
                    });
                    socketService.socket?.off(_currentEventName!);

                    _joinDeviceRoom(value);
                    // _listenRealtime();
                    fetchDeviceData(value);
                    _loadDashboardData();
                    setState(() {});
                  },
                  items: _deviceIds
                      .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                      .toList(),
                ),
              ),
            ),

          // IconButton(
          //   icon: const Icon(
          //     Icons.edit,
          //     size: 20,
          //     color: Colors.white70,
          //   ),
          //   onPressed: ()async {
          //     debugPrint("✏️ Edit Device Clicked");
          //
          //     Map<String, dynamic> deviceData = await _getDeviceData();
          //
          //
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => DeviceConfigForm(
          //         showBackButton: true,
          //         selectedDeviceId: _selectedDeviceId,
          //       )),
          //     );
          //   },
          // ),

          IconButton(onPressed: () {

            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            Navigator.push(context, MaterialPageRoute(builder: (context){
              return  NotificationScreen();
            }));

          }, icon: const Icon(Icons.notifications_none, color: Colors.white70,)),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              child: FutureBuilder<ProfileModel?>(
                future: ProfileApiService.getProfile(),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  return CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    backgroundImage: (profile?.image?.url != null &&
                        profile!.image!.url!.isNotEmpty)
                        ? NetworkImage(profile.image!.url!)
                        : null,
                    child: (profile?.image?.url == null ||
                        profile?.image?.url?.isEmpty == true)
                        ? Text(
                      profile?.name.isNotEmpty == true
                          ? profile!.name[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    )
                        : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(
          color: Colors.green,
        ))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [


               EnergyMeterCard(realtimeData: realtimeData,),
              const SizedBox(height: 17),


               PhaseEnergyWidget(realtimeData: realtimeData,),


               SizedBox(height: 12,),

              EnergyStatsGrid(realtimeData: realtimeData?? {},),



            ],
          ),
        ),
      ),
    );
  }
}