import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/response/aqi_response.dart';

class ApiService {
  static const String baseUrl = 'http://3.231.62.206:5000/api/v1';

  // ==================== GET TOKEN ====================
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print(' No auth_token found in SharedPreferences');
      } else {
        print(' Token retrieved successfully');
      }

      return token;
    } catch (e) {
      print(' Error getting token: $e');
      return null;
    }
  }

  // ==================== GET HEADERS ====================
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ""}',
    };
  }

  // ==================== FETCH DEVICE LIST (FOR DROPDOWN) ====================
  static Future<List<Map<String, dynamic>>> fetchAqiDevicesList() async {
    try {
      print('═══════════════════════════════════════');
      print(' FETCHING AQI DEVICES LIST');
      print('═══════════════════════════════════════');

      final token = await getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }


      final url = '$baseUrl/org/devices';
      final uri = Uri.parse(url).replace(
        queryParameters: {'name': 'Aqi Sensor'},
      );

      print(' REQUEST URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(' STATUS CODE: ${response.statusCode}');
      print(' RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> devicesJson = jsonData['data'];

          List<Map<String, dynamic>> devices = devicesJson.map((device) {
            return {
              'deviceId': device['deviceId'] ?? '',
              'name': device['name'] ?? device['deviceId'] ?? 'Unknown Device',
              '_id': device['_id'] ?? '',
              'status': device['status'] ?? 'unknown',
            };
          }).toList();

          print(' Found ${devices.length} AQI devices');
          for (var device in devices) {
            print('   - ${device['name']} (${device['deviceId']}) - ${device['status']}');
          }

          return devices;
        } else {
          print(' No devices found in response');
          throw Exception('No AQI devices found');
        }
      } else {
        print(' Failed to fetch devices: ${response.statusCode}');
        throw Exception('Failed to fetch AQI devices list');
      }
    } catch (e, stackTrace) {
      print(' EXCEPTION IN fetchAqiDevicesList');
      print('Error: $e');
      print('Stack Trace: $stackTrace');
      rethrow;
    }
  }

  // ==================== FETCH SENSOR DATA FOR SPECIFIC DEVICE ====================
  static Future<AqiData?> fetchAqiDevice(String deviceId, {String? toDate}) async {
    try {
      print('═══════════════════════════════════════');
      print(' AQI API REQUEST');
      print('═══════════════════════════════════════');
      print(' Device ID: $deviceId');

      final token = await getToken();
      if (token == null) {
        print(' Cannot proceed - No authentication token');
        throw Exception('Authentication token not found');
      }

      final url = '$baseUrl/aqi-latest/$deviceId';
      final uri = Uri.parse(url).replace(
        queryParameters: toDate != null ? {'toDate': toDate} : null,
      );

      print(' REQUEST URL: $uri');
      print('Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('═══════════════════════════════════════');
      print('AQI API RESPONSE');
      print('═══════════════════════════════════════');
      print(' STATUS CODE: ${response.statusCode}');
      print('RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final aqiData = AqiData.fromJson(jsonData['data']);

          print('  AQI DATA PARSED SUCCESSFULLY');
          print('   Device ID: ${aqiData.deviceId}');
          print('   PM1.0: ${aqiData.pm1} μg/m³');
          print('   PM2.5: ${aqiData.pm2_5} μg/m³');
          print('   PM10: ${aqiData.pm10} μg/m³');
          print('   Temperature: ${aqiData.temperature}°C');
          print('   Humidity: ${aqiData.humidity}%');
          print('   TVOC: ${aqiData.tvoc} ppb');
          print('   CO2: ${aqiData.co2} ppm');
          print('   IAQ: ${aqiData.iaq}');
          print('   Type: ${aqiData.type}');
          print('   Reading Time: ${aqiData.readingTime}');
          print('═══════════════════════════════════════');

          return aqiData;
        } else {
          print('No AQI data found in response');
          print('Response keys: ${jsonData.keys.toList()}');
          return null;
        }
      } else {
        print('AQI API FAILED');
        print('Status Code: ${response.statusCode}');
        print('Error Body: ${response.body}');
        throw Exception('Failed to load AQI data: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('EXCEPTION IN fetchAqiDevice');
      print('Error: $e');
      print('Stack Trace: $stackTrace');
      rethrow;
    }
  }

  // ==================== FETCH ALL AQI DEVICES WITH SENSOR DATA ====================
  static Future<List<AqiData>> fetchAllAqiDevices({String? toDate}) async {
    try {
      print('═══════════════════════════════════════');
      print('FETCHING ALL AQI DEVICES');
      print('═══════════════════════════════════════');

      final token = await getToken();
      if (token == null) {
        print(' No token available - cannot fetch devices');
        throw Exception('Authentication token not found. Please login again.');
      }


      print('Step 1: Fetching device list from API...');
      List<Map<String, dynamic>> devicesList = await fetchAqiDevicesList();

      if (devicesList.isEmpty) {
        print('No devices found in the list');
        throw Exception('No AQI devices available');
      }


      List<String> deviceIds = devicesList
          .map((device) => device['deviceId'] as String)
          .toList();

      print('Found ${deviceIds.length} devices to fetch sensor data for');
      print('Devices: $deviceIds');

      if (toDate != null) {
        print('Date filter: $toDate');
      }


      print('Step 2: Fetching AQI sensor data for each device...');

      List<AqiData> aqiDataList = [];
      int successCount = 0;
      int failCount = 0;

      for (int i = 0; i < deviceIds.length; i++) {
        final deviceId = deviceIds[i];
        print('');
        print('[${i + 1}/${deviceIds.length}] Processing: $deviceId');

        try {
          final data = await fetchAqiDevice(deviceId, toDate: toDate);

          if (data != null) {
            aqiDataList.add(data);
            successCount++;
            print('SUCCESS: ${data.deviceId} loaded');
          } else {
            failCount++;
            print('WARNING: $deviceId returned null');
          }
        } catch (e) {
          failCount++;
          print('FAILED: $deviceId - $e');
          continue;
        }
      }

      print('');
      print('═══════════════════════════════════════');
      print('SUMMARY');
      print('═══════════════════════════════════════');
      print('Success: $successCount devices');
      print('Failed: $failCount devices');
      print('Total loaded: ${aqiDataList.length} devices');
      print('═══════════════════════════════════════');

      if (aqiDataList.isEmpty) {
        print('No devices loaded - throwing exception');
        throw Exception('Failed to load any device sensor data');
      }

      return aqiDataList;
    } catch (e, stackTrace) {
      print('EXCEPTION IN fetchAllAqiDevices');
      print('Error: $e');
      print('Stack Trace: $stackTrace');
      rethrow;
    }
  }

  // ==================== FETCH MULTIPLE SPECIFIC DEVICES ====================
  static Future<List<AqiData>> fetchMultipleAqiDevices({
    required List<String> deviceIds,
    String? toDate,
  }) async {
    try {
      print('═══════════════════════════════════════');
      print('FETCHING MULTIPLE SPECIFIC DEVICES');
      print('═══════════════════════════════════════');
      print('Devices to fetch: ${deviceIds.length}');
      print('Device IDs: $deviceIds');

      List<AqiData> aqiDataList = [];
      int successCount = 0;
      int failCount = 0;

      for (int i = 0; i < deviceIds.length; i++) {
        final deviceId = deviceIds[i];
        print('');
        print('[${i + 1}/${deviceIds.length}] Processing: $deviceId');

        try {
          final data = await fetchAqiDevice(deviceId, toDate: toDate);

          if (data != null) {
            aqiDataList.add(data);
            successCount++;
            print('SUCCESS: Loaded');
          } else {
            failCount++;
            print('WARNING: Returned null');
          }
        } catch (e) {
          failCount++;
          print('FAILED: $e');
          continue;
        }
      }

      print('');
      print('═══════════════════════════════════════');
      print('SUMMARY');
      print('Success: $successCount');
      print('Failed: $failCount');
      print('Total: ${aqiDataList.length} devices');
      print('═══════════════════════════════════════');

      return aqiDataList;
    } catch (e, stackTrace) {
      print('EXCEPTION IN fetchMultipleAqiDevices');
      print('Error: $e');
      print('Stack Trace: $stackTrace');
      return [];
    }
  }

  // ==================== FETCH FULL RESPONSE ====================
  static Future<AqiResponse?> fetchAqiResponse(String deviceId, {String? toDate}) async {
    try {
      print('Fetching full AQI response for: $deviceId');

      final token = await getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '$baseUrl/aqi-latest/$deviceId';
      final uri = Uri.parse(url).replace(
        queryParameters: toDate != null ? {'toDate': toDate} : null,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final aqiResponse = AqiResponse.fromJson(jsonData);

        print('Full AQI Response loaded');
        print('Success: ${aqiResponse.success}');
        print('Code: ${aqiResponse.code}');
        print('Device: ${aqiResponse.data.deviceId}');

        return aqiResponse;
      } else {
        print('Failed to load AQI response: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Exception in fetchAqiResponse: $e');
      print('Stack Trace: $stackTrace');
      return null;
    }
  }
}