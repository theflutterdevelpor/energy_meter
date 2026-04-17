import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/response/tempreture_response.dart';


class TemperatureService {
  static const String baseUrl = "http://3.231.62.206:5000/api/v1";

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }


  static Future<TemperatureLatestResponse?> getLatest() async {
    final uri = Uri.parse(
      "$baseUrl/org/temperature-sensor/GHT-N_0005",
    ).replace(
      queryParameters: {
        'details': 'true',
        'timeAgo': '12h',
      },
    );

    final headers = await getHeaders();

    print("️ TEMP REQUEST URL: $uri");
    print(" TEMP HEADERS: $headers");

    final response = await http.get(uri, headers: headers);

    print(" TEMP STATUS CODE: ${response.statusCode}");
    print(" TEMP RESPONSE BODY: ${response.body}");

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      if (body['success'] == true) {
        return TemperatureLatestResponse.fromJson(body);
      }
    }

    return null;
  }
}
