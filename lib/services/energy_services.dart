import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EnergyService {
  static const String baseUrl = 'http://3.231.62.206:5000/api/v1';


  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }


  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }


  static Future<Map<String, dynamic>> fetchEnergy({
    required String fromDate,
    required String toDate,
  }) async {
    debugPrint(" POST HIT => $baseUrl/org/energy-meter");

    try {
      final headers = await getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/org/energy-meter'),
        headers: headers,
        body: jsonEncode({
          "fromDate": fromDate,
          "toDate": toDate,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      debugPrint(" STATUS CODE: ${response.statusCode}");
      debugPrint(" RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "Failed to load data: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint(' API ERROR: $e');
      rethrow;
    }
  }


  static Future<Map<String, dynamic>> fetchEnergyHourly({
    required String date,
  }) async {
    debugPrint(" POST HIT => $baseUrl/org/energy-meter/$date");

    try {
      final headers = await getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/org/energy-meter/$date'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      debugPrint(" STATUS CODE: ${response.statusCode}");
      debugPrint(" RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "Failed to load hourly data: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint(' API ERROR: $e');
      rethrow;
    }
  }
}