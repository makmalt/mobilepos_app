import 'dart:convert';
import 'dart:io';
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
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Koneksi timeout. Silakan coba lagi.');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Gagal memuat detail barang");
      }
    } on SocketException catch (e) {
      print('SocketException: ${e.message}');
      throw Exception('Tidak ada koneksi internet. Mohon periksa koneksi Anda.');
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
      print("Error fetching item details: $error");
      if (error.toString().contains('Failed host lookup')) {
        throw Exception('Tidak dapat menemukan server. Periksa koneksi internet Anda.');
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
