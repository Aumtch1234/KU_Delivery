import 'package:delivery/APIs/Users/models/address.dart';
import 'package:delivery/APIs/api_config.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeliveryAddressAPI {
  static Future<Map<String, dynamic>> addAddress(
    DeliveryAddress address,
  ) async {
    final token = await AuthService().getToken(); // 🔑 ต้องมี method ดึง JWT

    print("📌 ใช้ Token: $token");

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/add/address"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // ✅ ส่ง token มาด้วย
      },
      body: json.encode({
        "name": address.name,
        "phone": address.phone,
        "address": address.address,
        "district": address.district,
        "city": address.city,
        "postalCode": address.postalCode,
        "notes": address.notes,
        "latitude": address.latitude,
        "longitude": address.longitude,
        "locationText": address.address,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {
        "success": false,
        "message": "Error ${response.statusCode}: ${response.body}",
      };
    }
  }

  static Future<Map<String, dynamic>> GetAddress() async {
    final token = await AuthService().getToken();
    print("📌 ใช้ Token: $token");

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/address"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {
        "success": false,
        "message": "Error ${response.statusCode}: ${response.body}",
      };
    }
  }

  static Future<Map<String, dynamic>> updateAddress(
    int id,
    DeliveryAddress address,
  ) async {
    final token = await AuthService().getToken(); // 🔑 ดึง JWT

    print("📌 ใช้ Token: $token");

    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/update/address/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode({
        "name": address.name,
        "phone": address.phone,
        "address": address.address,
        "district": address.district,
        "city": address.city,
        "postalCode": address.postalCode,
        "notes": address.notes,
        "latitude": address.latitude,
        "longitude": address.longitude,
        "locationText": address.address,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {
        "success": false,
        "message": "Error ${response.statusCode}: ${response.body}",
      };
    }
  }

  static Future<Map<String, dynamic>> deleteAddress(int id) async {
    final token = await AuthService().getToken();

    final response = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/delete/address/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {
        "success": false,
        "message": "Error ${response.statusCode}: ${response.body}",
      };
    }
  }
}
