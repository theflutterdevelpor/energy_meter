import 'package:flutter/material.dart';
import '../../models/response/profile_response.dart';
import '../../services/notification_service.dart';
import '../../services/profile_services.dart';
import '../../widgets/apparent_power.dart';
import '../../widgets/current_chart.dart';
import '../../widgets/energy_power_chart.dart';
import '../../widgets/frequency_chart.dart';
import '../../widgets/notification.dart';
import '../../widgets/power_bar_chart.dart';
import '../../widgets/power_factor_chart.dart';
import '../../widgets/profile_drawer.dart';
import '../../widgets/reactive_power.dart';
import '../../widgets/voltage_chart.dart';

class chartPage extends StatefulWidget {
  const chartPage({super.key});

  @override
  State<chartPage> createState() => _chartPageState();
}

class _chartPageState extends State<chartPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String selectedFilter = "Today";
  String selectedPhase = "3-PHASE";
  int _unreadCount=0;


  final List<String> filterOptions = [
    "Today",
    "Yesterday",
    "Week",
    "30 Days",
    "6 Months",
  ];
  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
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

  Widget _buildGlobalDropdown() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E1A),
          border: Border.all(color: Colors.white30),
          borderRadius: BorderRadius.circular(10),
        ),
        child: PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          color: const Color(0xFF0A0E1A),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF2A3142)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedFilter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Colors.white70,
              ),
            ],
          ),
          onSelected: (value) {
            setState(() => selectedFilter = value);
          },
          itemBuilder: (context) {
            return filterOptions.map((choice) {
              final isSelected = choice == selectedFilter;
              return PopupMenuItem<String>(
                value: choice,
                padding: EdgeInsets.zero,
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF161A2A)
                        : const Color(0xFF0A0E1A),
                  ),
                  child: Text(
                    choice,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }


  Widget _buildPhaseButtons() {
    final phases = ["3-PHASE", "PHASE A", "PHASE B", "PHASE C"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: phases.map((phase) {
        final isSelected = selectedPhase == phase;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedPhase = phase;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.green : Color(0xFF1A1F2E),
                foregroundColor: isSelected ? Colors.black : Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                phase,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        endDrawer: const ProfileDrawer(),
        backgroundColor:  Color(0xFF121821),
      key: _scaffoldKey,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 1,
        title: const Text(
          "Analytics",
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
        ),
        actions: [
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
                future: ProfileApiService.getProfile(),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  return CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    backgroundImage: (profile?.image?.url != null &&
                        profile!.image!.url.isNotEmpty)
                        ? NetworkImage(profile.image!.url)
                        : null,
                    child: (profile?.image?.url == null ||
                        profile?.image?.url.isEmpty == true)
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
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Monitoring Dashboard",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500,color: Colors.white70),
                  ),

                  const SizedBox(height: 16),


                  _buildPhaseButtons(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [_buildGlobalDropdown()],
                  ),

                  const SizedBox(height: 10),

                  Column(
                    children: [
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Electrical Parameters",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Divider(thickness: 1, color: Colors.grey),
                          const SizedBox(height: 8),

                          SizedBox(height: 330, child: VoltageChart(selectedFilter: selectedFilter,selectedPhase: selectedPhase,)),
                          const SizedBox(height: 10),

                          SizedBox(height: 330, child: CurrentChart(selectedFilter: selectedFilter, selectedPhase: selectedPhase)),
                          const SizedBox(height: 10),

                          SizedBox(height: 330, child: FrequencyChart(selectedFilter: selectedFilter, selectedPhase: selectedPhase)),
                          const SizedBox(height: 10),

                          SizedBox(height: 330, child: PowerFactorChart(selectedFilter: selectedFilter, selectedPhase: selectedPhase)),
                          const SizedBox(height: 10),

                          SizedBox(height: 330, child: ActivePowerChart(selectedFilter: selectedFilter , selectedPhase: selectedPhase)),
                          const SizedBox(height: 10),

                          SizedBox(height: 330, child: ReactiveBarChart(selectedFilter: selectedFilter, selectedPhase: selectedPhase)),
                          const SizedBox(height: 10),

                          SizedBox(height: 330, child: ApparentPowerChart(selectedFilter: selectedFilter, selectedPhase: selectedPhase)),
                          const SizedBox(height: 10),

                          SizedBox(height: 330, child: EnergyPowerChart(selectedFilter: selectedFilter ,selectedPhase: selectedPhase)),
                        ],
                      ),


                    ],
                          ),
    ]
    )
    )
    ]
        )
      )
    );
  }
}
