import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/request/billing_request.dart';
import '../models/response/billing_response.dart';

class BillingService {
  static const String baseUrl = 'http://3.231.62.206:5000/api/v1';

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

  static Future<BillingResponse> createBilling(BillingRequest request) async {
    final uri = Uri.parse('$baseUrl/em-billing/');
    final headers = await getHeaders();

    print("📤 REQUEST URL: $uri");
    print("📤 HEADERS: $headers");
    print("📤 REQUEST BODY: ${jsonEncode(request.toJson())}");

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(request.toJson()),
    );

    print("📥 STATUS CODE: ${response.statusCode}");
    print("📥 RESPONSE BODY: ${response.body}");

    final body = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) && body['success'] == true) {
      return BillingResponse.fromJson(body);
    } else {
      throw Exception(body['message'] ?? "Failed to create billing");
    }
  }


  static Future<BillingResponse> updateBilling(String id, BillingRequest request) async {
    final uri = Uri.parse('$baseUrl/em-billing/$id');
    final headers = await getHeaders();

    print("📤 UPDATE BILLING URL: $uri");
    print("📤 REQUEST BODY: ${jsonEncode(request.toJson())}");

    final response = await http.put(
      uri,
      headers: headers,
      body: jsonEncode(request.toJson()),
    );

    print("📥 STATUS CODE: ${response.statusCode}");
    print("📥 RESPONSE BODY: ${response.body}");

    final body = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['success'] == true) {
      return BillingResponse.fromJson(body);
    } else {
      throw Exception(body['message'] ?? "Failed to update billing");
    }
  }

  // static Future<BillingResponse> getBilling() async {
  //   final uri = Uri.parse('$baseUrl/em-billing');
  //   final headers = await getHeaders();
  //
  //   print("📤 GET BILLING URL: $uri");
  //
  //   final response = await http.get(uri, headers: headers);
  //
  //   print("📥 STATUS CODE: ${response.statusCode}");
  //   print("📥 RESPONSE BODY: ${response.body}");
  //
  //   final body = jsonDecode(response.body);
  //
  //   if (response.statusCode == 200 && body['success'] == true) {
  //     return BillingResponse.fromJson(body);
  //   } else {
  //     throw Exception(body['message'] ?? "Failed to get billing");
  //   }
  // }


  static Future<BillingResponse> getBillingById(String id) async {
    final uri = Uri.parse('$baseUrl/em-billing/$id');
    final headers = await getHeaders();

    final response = await http.get(uri, headers: headers);

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return BillingResponse.fromJson(body); // ✅ FULL BODY PASS
    } else {
      throw Exception(body['message'] ?? "Billing not found");
    }
  }

  static Future<List<BillingResponse>> getAllBillings() async {
    final uri = Uri.parse('$baseUrl/em-billing/');
    final headers = await getHeaders();

    final response = await http.get(uri, headers: headers);

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      final List list = body['data'];

      return list.map((e) {
        return BillingResponse.fromJson({
          "success": body['success'],
          "code": body['code'] ?? 0,
          "message": body['message'],
          "data": e
        });
      }).toList();
    } else {
      throw Exception(body['message'] ?? "Failed to get billings");
    }
  }


}