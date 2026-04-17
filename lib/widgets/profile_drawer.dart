import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_screen.dart';
import '../models/response/profile_response.dart';
import '../services/profile_services.dart';
import 'add_device.dart';
import 'configration_screen.dart';
import 'edit_profile.dart';


class ProfileDrawer extends StatefulWidget {
  const ProfileDrawer({super.key});

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {

  // String? _selectedDeviceId;


  ProfileModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final profile = await ProfileApiService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  // Future<Map<String, dynamic>> _getDeviceData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //
  //   final deviceId = _selectedDeviceId ?? prefs.getString('device_id') ?? '';
  //
  //
  //   final deviceType  = prefs.getString('device_type_$deviceId')  ?? prefs.getString('device_type')  ?? '';
  //   final readingDate = prefs.getString('reading_date_$deviceId') ?? prefs.getString('reading_date') ?? '';
  //   final maxLoad     = prefs.getString('max_load_$deviceId')     ?? prefs.getString('max_load')     ?? '';
  //   final tax         = prefs.getString('tax_$deviceId')          ?? prefs.getString('tax')          ?? '';
  //
  //   final slabsJson = prefs.getString('unit_slabs_$deviceId') ?? prefs.getString('unit_slabs') ?? '[]';
  //   List<dynamic> unitSlabs = [];
  //   try { unitSlabs = jsonDecode(slabsJson); } catch (_) {}
  //
  //   return {
  //     "deviceType"  : deviceType,
  //     "deviceId"    : deviceId,
  //     "readingDate" : readingDate,
  //     "maxLoad"     : maxLoad,
  //     "tax"         : tax,
  //     "unitSlabs"   : unitSlabs,
  //   };
  // }



  @override
  Widget build(BuildContext context) {
    return Drawer(
        width: 280,
        backgroundColor: Colors.black,
        child: SafeArea(
            child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                /// PROFILE SECTION
                                if (_isLoading)
                                  const SizedBox(
                                    height: 60,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.green,
                                      ),
                                    ),
                                  )
              else
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.green.shade100,
                      backgroundImage: (_profile?.image?.url != null &&
                          _profile!.image!.url!.isNotEmpty)
                          ? NetworkImage(_profile!.image!.url!)
                          : null,
                      child: (_profile?.image?.url == null ||
                          _profile!.image!.url!.isEmpty)
                          ? Text(
                        _profile?.name.isNotEmpty == true
                            ? _profile!.name[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _profile?.name ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _profile?.email ?? '-',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 15),
              const Divider(),
              const SizedBox(height: 15),

              // Drawer Items with Navigation
              _item(
                context,
                Icons.person_outline,
                "Profile Settings",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  ProfileCardScreen(),
                    ),
                  );
                },
              ),
              _item(context, Icons.add, "Add Device", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  DeviceReadingForm(showBackButton: true,),
                  ),
                );
              }),
              _item(context, Icons.settings_input_component, "Device Configuration", () async {


                // Map<String, dynamic> deviceData = await _getDeviceData();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeviceConfigForm(
                      showBackButton: true,
                      // selectedDeviceId: _selectedDeviceId,
                    ),
                  ),
                );
              }),
              _item(context, Icons.report_problem_outlined, "Report a problem", () {
                // Navigate to Report Screen
              }),
              _item(context, Icons.info_outline, "About Digital Twin", () {
                // Navigate to About Screen
              }),

              const Spacer(),

              /// LOGOUT
              GestureDetector(
                onTap: () {
                  _handleLogout(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
                      );
        }
      ),
    )
    );

  }

  // Updated _item with onTap
  Widget _item(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.green),
              const SizedBox(width: 12),
              Text(title,style: TextStyle(color: Colors.white),),
            ],
          ),
        ),
      ),
    );
  }

  // Handle Logout Logic
  void _handleLogout(BuildContext context) async{
    // TODO: Yaha aap SharedPreferences se data clear kar sakte ho
    // TODO: API call karke logout kar sakte ho
    // TODO: Local storage se token delete kar sakte ho






    // Example: SharedPreferences clear
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.clear();

    // Navigate to Login Screen - Replace all routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }
}
