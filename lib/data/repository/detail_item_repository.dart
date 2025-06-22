import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobilepos_app/core/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailItemRepository {
  final SharedPreferences prefs;

  DetailItemRepository(this.prefs);

  String baseUrl = AppConfig.baseUrl;

  Future<Map<String, dynamic>> fetchDetail(
      {int? id, String? barcode, String? token}) async {
    String apiUrl;

    if (barcode != null) {
      apiUrl = "$baseUrl/api/barang/barcode/$barcode";
    } else if (id != null) {
      apiUrl = "$baseUrl/api/barang/show/$id";
    } else {
      throw Exception("ID atau Barcode diperlukan.");
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Failed to load item details");
      }
    } catch (error) {
      print("Error fetching item details: $error");
      rethrow;
    }
  }
}
