import 'dart:convert';
import 'dart:io';

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
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Koneksi timeout. Silakan coba lagi.');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        return data.map<Item>((itemJson) => Item.fromJson(itemJson)).toList();
      } else {
        throw Exception('Gagal memuat data dari server');
      }
    } on SocketException catch (e) {
      print('SocketException: ${e.message}');
      throw Exception(
          'Tidak ada koneksi internet. Mohon periksa koneksi Anda.');
    } on HttpException catch (e) {
      print('HttpException: ${e.message}');
      throw Exception('Gagal terhubung ke server. Silakan coba lagi.');
    } on FormatException catch (e) {
      print('FormatException: ${e.message}');
      throw Exception('Data yang diterima tidak valid.');
    } on TimeoutException catch (e) {
      print('TimeoutException: ${e.message}');
      throw Exception(e.message);
    } catch (error) {
      print('Error fetching data from API: $error');
      if (error.toString().contains('Failed host lookup')) {
        throw Exception(
            'Tidak dapat menemukan server. Periksa koneksi internet Anda.');
      } else if (error.toString().contains('Connection refused')) {
        throw Exception('Server tidak dapat diakses. Silakan coba lagi nanti.');
      } else {
        throw Exception('Terjadi kesalahan. Silakan coba lagi.');
      }
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
