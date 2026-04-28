import 'package:energy_meter/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wattpro',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}