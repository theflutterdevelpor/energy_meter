import 'package:energy_meter/signup_screen.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeterPro',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}