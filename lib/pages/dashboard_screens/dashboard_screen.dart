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
import '../../services/notification_service.dart';
import '../../services/profile_services.dart';
import '../../widgets/Energy-Maintenance-Card.dart';
import '../../widgets/bar_chart.dart';
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
  Timer? _autoRefreshTimer;
  Device? device;
  bool isLoading = true;
  int _unreadCount=0;
  bool _isSocketConnected = false;
  final String baseUrl = 'http://3.231.62.206:5000/api/v1';
  int _refreshTrigger = 0;
  String? _currentEventName;
  Future<ProfileModel?>? _profileFuture;






  @override
  void initState() {
    super.initState();
    debugPrint("🔵 DashboardPage INIT");
    _profileFuture = ProfileApiService.getProfile();
    _loadDeviceIds();
    _loadDashboardData();
    _startReconnectTimer();
    _fetchUnreadCount();
    _startAutoRefresh();

  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;
      _loadDashboardData();
      if (_isSocketConnected && _selectedDeviceId != null) {
        socketService.socket?.emit("get-realtime", {"deviceId": _selectedDeviceId});
      }
    });
  }


  Future<void> _fetchUnreadCount() async {
    try {
      final response = await NotificationApi.getMyNotifications();

      final filteredUnread = response.data.where((n) {
        return n.type == 'electricity_alert' && !n.read;
      }).length;

      if (mounted) {
        setState(() {
          _unreadCount = filteredUnread;
        });
      }
    } catch (e) {
      debugPrint("Error fetching unread count: $e");
    }
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

      if (_selectedDeviceId != null) {
        await _connectAndJoinSocket();
      }

    } catch (e) {
      debugPrint("❌ Error loading devices: $e");
      setState(() {
        isLoading = false;
      });
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

    if (socketService.socket?.connected ?? false) {
      socketService.disconnect();
    }

    socketService.connect(token);

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

  // void _listenRealtime() {
  //   if (_selectedDeviceId == null) return;
  //
  //   final eventName = "ESensor-$_selectedDeviceId";
  //   _currentEventName = eventName;
  //
  //   debugPrint("🎧 Setting up listener for: $eventName");
  //
  //   socketService.socket?.off(eventName);
  //
  //   socketService.socket?.on(eventName, (data) {
  //     debugPrint("📡 RAW SOCKET DATA RECEIVED");
  //     debugPrint("📦 Data: $data");
  //     debugPrint("📦 COMPLETE SOCKET DATA: $data");
  //     if (data is Map) {
  //       debugPrint("🔑 ALL KEYS: ${data.keys}");
  //     }
  //
  //     Map<String, dynamic> parsed = {};
  //
  //     try {
  //       if (data is Map) {
  //         parsed = Map<String, dynamic>.from(data);
  //
  //         double powerValue = 0.0;
  //
  //         if (parsed.containsKey('threePhase') && parsed['threePhase'] is Map) {
  //           final threePhase = parsed['threePhase'] as Map;
  //           if (threePhase.containsKey('power')) {
  //             powerValue = (threePhase['power'] as num).toDouble();
  //
  //             if (powerValue > 100) {
  //               powerValue = powerValue / 1000;
  //               debugPrint("⚡ Converted Watts to KW: ${powerValue}KW");
  //             } else {
  //               debugPrint("⚡ Power from threePhase: ${powerValue}KW");
  //             }
  //
  //             threePhase['power'] = powerValue;
  //           }
  //         }
  //
  //         if (powerValue == 0.0 && parsed.containsKey('power_w')) {
  //           powerValue = (parsed['power_w'] as num).toDouble();
  //           if (powerValue > 100) {
  //             powerValue = powerValue / 1000;
  //           }
  //           debugPrint("⚡ Power from power_w: ${powerValue}KW");
  //         }
  //
  //         if (powerValue == 0.0 && parsed.containsKey('power')) {
  //           powerValue = (parsed['power'] as num).toDouble();
  //           if (powerValue > 100) {
  //             powerValue = powerValue / 1000;
  //           }
  //           debugPrint("⚡ Power from power: ${powerValue}KW");
  //         }
  //
  //         double freqValue = 50.0;
  //         if (parsed.containsKey('threePhase') && parsed['threePhase'] is Map) {
  //           final threePhase = parsed['threePhase'] as Map;
  //           if (threePhase.containsKey('frequency')) {
  //             freqValue = (threePhase['frequency'] as num).toDouble();
  //           }
  //         } else if (parsed.containsKey('frequency')) {
  //           freqValue = (parsed['frequency'] as num).toDouble();
  //         }
  //
  //         debugPrint("⚡ FINAL Total Power: ${powerValue}KW");
  //         debugPrint("📊 Frequency: ${freqValue}Hz");
  //
  //         double todayEng = 0.0;
  //         double monthEng = 0.0;
  //         if (parsed.containsKey('today_energy')) {
  //           todayEng = (parsed['today_energy'] as num).toDouble();
  //         }
  //         if (parsed.containsKey('month_energy')) {
  //           monthEng = (parsed['month_energy'] as num).toDouble();
  //         }
  //
  //         parsed['power_w'] = powerValue * 1000;
  //         parsed['frequency'] = freqValue;
  //         parsed['today_energy'] = todayEng;
  //         parsed['month_energy'] = monthEng;
  //
  //         if (parsed.containsKey('threePhase') && parsed['threePhase'] is Map) {
  //           (parsed['threePhase'] as Map)['power'] = powerValue;
  //         }
  //       }
  //
  //       parsed['deviceId'] = _selectedDeviceId;
  //
  //     } catch (e) {
  //       debugPrint("❌ Parse error: $e");
  //     }
  //
  //     if (!mounted) return;
  //
  //     setState(() {
  //       realtimeData = Map.from(parsed);
  //     });
  //
  //     debugPrint("✅ FINAL realtimeData => $realtimeData");
  //   });
  // }

  void _listenRealtime() {
    if (_selectedDeviceId == null) return;

    final eventName = "ESensor-$_selectedDeviceId";
    _currentEventName = eventName;

    debugPrint("🎧 Setting up listener for: $eventName");

    socketService.socket?.off(eventName);
    socketService.socket?.onAny((event, data) {
      debugPrint("🔍 ANY EVENT RECEIVED: '$event'");
      debugPrint("🔍 DATA: $data");
    });

    socketService.socket?.on(eventName, (data) {
      debugPrint("📡 RAW SOCKET DATA RECEIVED");
      debugPrint("📦 Data: $data");

      Map<String, dynamic> parsed = {};

      try {
        if (data is Map) {
          parsed = Map<String, dynamic>.from(data);

          // Check for threePhase data and convert power if needed
          if (parsed.containsKey('threePhase') && parsed['threePhase'] is Map) {
            final threePhase = parsed['threePhase'] as Map;
            if (threePhase.containsKey('power')) {
              double powerValue = (threePhase['power'] as num).toDouble();
              // Convert to kW if value is in Watts (value > 100)
              if (powerValue > 100) {
                powerValue = powerValue / 1000;
                debugPrint("⚡ Converted Watts to KW: ${powerValue}KW");
              } else {
                debugPrint("⚡ Power from threePhase: ${powerValue}KW");
              }
              threePhase['power'] = powerValue;
            }

            // Also extract frequency
            if (threePhase.containsKey('frequency')) {
              double freqValue = (threePhase['frequency'] as num).toDouble();
              debugPrint("📊 Frequency: ${freqValue}Hz");
            }
          }

          // Extract individual phase data (Phase A, B, C)
          // Phase 1 (A) - voltage, current, power
          if (parsed.containsKey('phaseOne') && parsed['phaseOne'] is Map) {
            final phase1 = parsed['phaseOne'] as Map;

            // Convert power if in Watts
            if (phase1.containsKey('power')) {
              double powerValue = (phase1['power'] as num).toDouble();
              if (powerValue > 100) {
                powerValue = powerValue / 1000;
                phase1['power'] = powerValue;
              }
            }
            debugPrint("🔴 PHASE A - Power: ${phase1['power']} kW");
          }

          // Phase 2 (B)
          if (parsed.containsKey('phaseTwo') && parsed['phaseTwo'] is Map) {
            final phase2 = parsed['phaseTwo'] as Map;
            if (phase2.containsKey('power')) {
              double powerValue = (phase2['power'] as num).toDouble();
              if (powerValue > 100) {
                powerValue = powerValue / 1000;
                phase2['power'] = powerValue;
              }
            }
            debugPrint("🟡 PHASE B - Power: ${phase2['power']} kW");
          }

          // Phase 3 (C)
          if (parsed.containsKey('phaseThree') && parsed['phaseThree'] is Map) {
            final phase3 = parsed['phaseThree'] as Map;
            if (phase3.containsKey('power')) {
              double powerValue = (phase3['power'] as num).toDouble();
              if (powerValue > 100) {
                powerValue = powerValue / 1000;
                phase3['power'] = powerValue;
              }
            }
            debugPrint("🔵 PHASE C - Power: ${phase3['power']} kW");
          }

          // Also check for direct power_w (total power)
          if (parsed.containsKey('power_w')) {
            double totalPower = (parsed['power_w'] as num).toDouble();
            if (totalPower > 100) {
              totalPower = totalPower / 1000;
              parsed['power_w'] = totalPower;
            }
            debugPrint("⚡ Total Power from power_w: ${totalPower}KW");
          }

          // Preserve frequency for backward compatibility
          if (parsed.containsKey('frequency')) {
            double freqValue = (parsed['frequency'] as num).toDouble();
            debugPrint("📊 Top-level Frequency: ${freqValue}Hz");
          }

          parsed['deviceId'] = _selectedDeviceId;
        }

        debugPrint("✅ FINAL realtimeData => $parsed");

        if (!mounted) return;

        setState(() {
          realtimeData = Map.from(parsed);
          _refreshTrigger++;
        });

      } catch (e) {
        debugPrint("❌ Parse error: $e");
      }
    });

    // Request initial realtime data after setting up listener
    if (socketService.socket?.connected ?? false) {
      Future.delayed(Duration(milliseconds: 500), () {
        socketService.socket?.emit("get-realtime", {"deviceId": _selectedDeviceId});
      });
    }
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
    _reconnectTimer?.cancel();
    _autoRefreshTimer?.cancel();
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


  void _refreshAfterConfig() {
    debugPrint("🔄 Config updated → refreshing bill & UI");

    if (_selectedDeviceId != null && _selectedDeviceId!.isNotEmpty) {


      setState(() {
        realtimeData = {...?realtimeData};
        _refreshTrigger++;
      });


      socketService.socket?.emit("get-realtime", {
        "deviceId": _selectedDeviceId
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer:  ProfileDrawer(
        onConfigUpdated: _refreshAfterConfig,
      ),
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

                    if (_currentEventName != null) {
                      socketService.socket?.off(_currentEventName!);
                    }

                    setState(() {
                      _selectedDeviceId = value;
                      realtimeData = null;
                    });

                    _joinDeviceRoom(value);
                    _listenRealtime();
                    fetchDeviceData(value);
                    _loadDashboardData();

                  },
                  items: _deviceIds
                      .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                      .toList(),
                ),
              ),
            ),

          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationScreen()),
                  ).then((_) {
                    _fetchUnreadCount();
                  });
                },
                icon: const Icon(Icons.notifications_none),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadCount > 9 ? '9+' : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              child: FutureBuilder<ProfileModel?>(
                future: _profileFuture,
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
        child: isLoading || _selectedDeviceId == null
            ? const Center(
          child: CircularProgressIndicator(color: Colors.green),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [


               EnergyMeterCard(realtimeData: realtimeData,deviceId: _selectedDeviceId ??"", refreshTrigger: _refreshTrigger,),
              const SizedBox(height: 17),


               PhaseEnergyWidget(realtimeData: realtimeData,
                 key: ValueKey(_selectedDeviceId),),


               SizedBox(height: 12,),

              EnergyStatsGrid(realtimeData: realtimeData?? {},
                deviceId: _selectedDeviceId,
                refreshTrigger: _refreshTrigger,
              ),



            ],
          ),
        ),
      ),
    );
  }
}