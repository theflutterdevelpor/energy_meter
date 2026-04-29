import 'dart:convert';
import 'package:energy_meter/bottom_nav_bar/home_nav_bar.dart';
import 'package:energy_meter/widgets/add_device.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:energy_meter/services/device_service.dart';
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
      title: 'Wattpro',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), // ✅ LoginScreen nahi
    );
  }
}

// =============================================
// SPLASH SCREEN — Token Check Karta Hai
// =============================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    print("🔍 SPLASH TOKEN: $token");

    if (!mounted) return;

    // ❌ Token nahi → Login
    if (token == null || token.isEmpty) {
      print("❌ Token nahi → Login");
      _goTo(const LoginScreen());
      return;
    }

    // ✅ Token expire check
    if (_isTokenExpired(token)) {
      print("⌛ Token expire ho gaya → Login");
      await prefs.remove('auth_token');
      await prefs.remove('has_devices');
      _goTo(const LoginScreen());
      return;
    }

    // ✅ Token theek hai → Server se devices check karo
    print("✅ Token theek hai → Devices check kar raha hoon");
    try {
      final devices = await DeviceService.getDevices();
      final hasDevices = devices.any((d) => d.name == "Energy Meter");
      await prefs.setBool('has_devices', hasDevices);

      print("📱 Has Devices: $hasDevices");

      if (!mounted) return;

      if (hasDevices) {
        _goTo(HomeScreen());       // ✅ Device hai → Dashboard
      } else {
        _goTo(const DeviceReadingForm(showBackButton: false)); // ✅ Device nahi
      }
    } catch (e) {
      print("❌ Device check error: $e");

      // Network error → local se check karo
      final hasDevices = prefs.getBool('has_devices') ?? false;
      if (!mounted) return;

      if (hasDevices) {
        _goTo(HomeScreen());
      } else {
        _goTo(const DeviceReadingForm(showBackButton: false));
      }
    }
  }

  // Token expire check
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      final decoded = base64Url.decode(base64Url.normalize(payload));
      final data = jsonDecode(utf8.decode(decoded));
      final exp = data['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      print("⏰ Token exp: ${DateTime.fromMillisecondsSinceEpoch(exp * 1000)}");
      return now >= exp;
    } catch (e) {
      return true;
    }
  }

  // Navigate helper
  void _goTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );
  }
}