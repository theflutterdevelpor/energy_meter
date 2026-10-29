import 'package:flutter/material.dart';
import '../pages/chart_screens/chart_Pages.dart';
import '../pages/dashboard_screens/dashboard_screen.dart';
// import '../pages/favrouite_screens/favrouite_screen.dart';
// import '../pages/favrouite_screens/maintenance_add.dart';
// import '../pages/profile_screens/profile_screen.dart';
// import '../pages/report_screens/report_screen.dart';
// import '../pages/setting_screens/setting_screen.dart';
// import '../pages/setting_screens/user_add.dart';
// import '../pages/wallet_screens/wallet_screen.dart';
import 'my_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentPageIndex = 0;

  final List<Widget> _pages = [
    DashboardPage(),
    chartPage(),
    // WalletPage(),
    // FavoritesPage(),
    // CreateUserRoleScreen(),
    // UserManagementPage(),
    // ReportsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_currentPageIndex],

      // floatingActionButton: _currentPageIndex == 2 || _currentPageIndex == 4
      //     ? FloatingActionButton(
      //   backgroundColor: Colors.green,
      //   elevation: 4,
      //   shape: const CircleBorder(),
      //   onPressed: () {
      //
      //     if (_currentPageIndex == 2) {
      //
      //       Navigator.push(
      //         context,
      //         MaterialPageRoute(builder: (context) => addnew()),
      //       );
      //     } else if (_currentPageIndex == 4) {
      //       Navigator.push(
      //         context,
      //         MaterialPageRoute(builder: (context) => useradd()),
      //       );
      //     }
      //   },
      //   child: Image.asset(
      //     "assets/icons/add.png",
      //     width: 30,
      //     height: 24,
      //     color: Colors.white,
      //   ),
      // )
      //     : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: MyBottomNavBar(
        onItemTapped: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
      ),
    );
  }
}