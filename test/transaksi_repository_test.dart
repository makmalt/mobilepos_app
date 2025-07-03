import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobilepos_app/data/models/barang_transaksi.dart';
import 'package:mobilepos_app/data/repository/transaksi_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobilepos_app/data/services/printer_service.dart';

// Generate mock classes
@GenerateMocks([SharedPreferences, http.Client, PrinterService])
import 'transaksi_repository_test.mocks.dart';

// Test wrapper class that extends TransaksiRepository
class TestTransaksiRepository extends TransaksiRepository {
  final http.Client testClient;
  final PrinterService testPrinterService;

  TestTransaksiRepository(
    SharedPreferences prefs, {
    required this.testClient,
    required this.testPrinterService,
  }) : super(prefs);

  @override
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

    final response = await testClient.post(
      Uri.parse('$baseUrl/api/transaksi'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'no_transaksi': testPrinterService.generateNoTransaksi(),
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

void main() {
  late MockSharedPreferences mockPrefs;
  late TestTransaksiRepository repository;
  late List<BarangTransaksi> testItems;
  late MockClient mockClient;
  late MockPrinterService mockPrinterService;

  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    mockPrefs = MockSharedPreferences();
    mockClient = MockClient();
    mockPrinterService = MockPrinterService();

    repository = TestTransaksiRepository(
      mockPrefs,
      testClient: mockClient,
      testPrinterService: mockPrinterService,
    );

    // Setup test data
    testItems = [
      BarangTransaksi(
        barangId: 1,
        namaBarang: 'Test Item 1',
        hargaBarang: 10000,
        quantity: 2,
        totalHarga: 20000,
      ),
      BarangTransaksi(
        barangId: 2,
        namaBarang: 'Test Item 2',
        hargaBarang: 15000,
        quantity: 3,
        totalHarga: 45000,
      ),
    ];

    // Mock token
    when(mockPrefs.getString('access_token')).thenReturn('test_token');

    // Mock printer service
    when(mockPrinterService.generateNoTransaksi()).thenReturn('TRX-TEST-123');
  });

  group('TransaksiRepository Tests', () {
    test('completeTransaction dengan item kosong', () async {
      print('\nTest Case: completeTransaction dengan items kosong');
      try {
        await repository.completeTransaction(
          transactionItems: [],
          nominalPembayaran: 0,
          kembalian: 0,
        );
      } catch (e) {
        print('Exception yang didapat: $e');
      }
      expect(
        () => repository.completeTransaction(
          transactionItems: [],
          nominalPembayaran: 0,
          kembalian: 0,
        ),
        throwsException,
      );
    });

    test('completeTransaction dengan response sukses', () async {
      print('\nTest Case: completeTransaction dengan response sukses');
      // Mock successful API response
      final mockResponse = {
        'data': {
          'no_transaksi': 'TRX-123456',
          'barang_transaksis': testItems.map((item) => item.toJson()).toList(),
          'grand_total': 65000,
          'uang_pembayaran': 100000,
          'uang_kembalian': 35000,
        }
      };

      // Mock http client
      when(mockClient.post(
        Uri.parse('${repository.baseUrl}/api/transaksi'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            json.encode(mockResponse),
            201,
          ));

      final result = await repository.completeTransaction(
        transactionItems: testItems,
        nominalPembayaran: 100000,
        kembalian: 35000,
      );

      print('\nResponse:');
      print('- success: ${result['success']}');
      print('- no_transaksi: ${result['data']['no_transaksi']}');
      print('- grandTotal: ${result['grandTotal']}');

      expect(result['success'], true);
      expect(result['data']['no_transaksi'], 'TRX-123456');
      expect(result['grandTotal'], 65000);
    });

    test('completeTransaction dengan response error', () async {
      print('\nTest Case: completeTransaction dengan response error');
      // Mock error API response
      final mockErrorResponse = {'message': 'Failed to process transaction'};

      // Mock http client
      when(mockClient.post(
        Uri.parse('${repository.baseUrl}/api/transaksi'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            json.encode(mockErrorResponse),
            400,
          ));

      try {
        await repository.completeTransaction(
          transactionItems: testItems,
          nominalPembayaran: 100000,
          kembalian: 35000,
        );
      } catch (e) {
        print('Exception yang didapat: $e');
      }

      expect(
        () => repository.completeTransaction(
          transactionItems: testItems,
          nominalPembayaran: 100000,
          kembalian: 35000,
        ),
        throwsException,
      );
    });
  });
}
