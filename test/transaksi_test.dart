import 'package:flutter_test/flutter_test.dart';
import 'package:mobilepos_app/data/models/barang_transaksi.dart';

class TransaksiCalculator {
  List<BarangTransaksi> transactionItems = [];

  double calculateTotal() {
    return transactionItems.fold(
        0, (total, item) => total + (item.hargaBarang * item.quantity));
  }
}

void main() {
  group('Transaksi Tests', () {
    late TransaksiCalculator calculator;

    setUp(() {
      calculator = TransaksiCalculator();
    });

    test('Hitung total harga (banyak barang)', () {
      calculator.transactionItems = [
        BarangTransaksi(
          barangId: 1,
          namaBarang: 'Item 1',
          hargaBarang: 10000,
          quantity: 2,
          totalHarga: 20000,
        ),
        BarangTransaksi(
          barangId: 2,
          namaBarang: 'Item 2',
          hargaBarang: 15000,
          quantity: 3,
          totalHarga: 45000,
        ),
      ];
      expect(calculator.calculateTotal(), 65000);
      print('Total harga: ${calculator.calculateTotal()}');
    });
  });
}
