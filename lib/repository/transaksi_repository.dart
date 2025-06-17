import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobilepos_app/app_config.dart';
import 'package:mobilepos_app/models/barang_transaksi.dart';
import 'package:mobilepos_app/services/printer_service.dart';
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

    final response = await http.post(
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
  }
}
