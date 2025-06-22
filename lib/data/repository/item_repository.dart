import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobilepos_app/core/config/app_config.dart';
import 'package:mobilepos_app/data/models/items.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ItemRepository {
  final SharedPreferences prefs;

  ItemRepository(this.prefs);

  String baseUrl = AppConfig.baseUrl;
  Future<List<Item>> fetchDataFromApi(String token, {int page = 1}) async {
    try {
      String apiUrl = '$baseUrl/api/barang?page=$page';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];

        return data.map<Item>((itemJson) => Item.fromJson(itemJson)).toList();
      } else {
        throw Exception('Failed to load data from API');
      }
    } catch (error) {
      print('Error fetching data from API: $error');
      rethrow;
    }
  }
}
