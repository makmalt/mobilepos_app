import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mobilepos_app/core/config/app_config.dart';
import 'package:mobilepos_app/data/models/barang_transaksi.dart';
import 'package:mobilepos_app/data/services/printer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransaksiRepository {
  final SharedPreferences prefs;
  final PrinterService _printerService = PrinterService();
  String baseUrl = AppConfig.baseUrl;

  TransaksiRepository(this.prefs);

  double calculateTotal(List<BarangTransaksi> transactionItems) {
    return transactionItems.fold(
        0, (total, item) => total + (item.hargaBarang * item.quantity));
  }

  Future<Map<String, dynamic>> completeTransaction({
    required List<BarangTransaksi> transactionItems,
    required double nominalPembayaran,
    required double kembalian,
  }) async {
    if (transactionItems.isEmpty) {
      throw Exception('Tambahkan barang terlebih dahulu!');
    }

    final token = prefs.getString('access_token');
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    double grandTotal = calculateTotal(transactionItems);

    final List<Map<String, dynamic>> itemsData = transactionItems.map((item) {
      return {
        'barang_id': item.barangId,
        'harga_barang': item.hargaBarang,
        'quantity': item.quantity,
        'total_harga': item.quantity * item.hargaBarang,
      };
    }).toList();

    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/api/transaksi'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'no_transaksi': _printerService.generateNoTransaksi(),
          'barang_transaksis': itemsData,
          'grand_total': grandTotal,
          'uang_pembayaran': nominalPembayaran,
          'uang_kembalian': kembalian,
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Koneksi timeout. Silakan coba lagi.');
        },
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'grandTotal': grandTotal,
        };
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Gagal menyimpan transaksi: ${errorData['message']}');
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
      print('Error completing transaction: $error');
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
