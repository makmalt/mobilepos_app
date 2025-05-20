import 'package:mobilepos_app/models/barang_transaksi.dart';

class Transaksi {
  final double grandTotal;
  final List<BarangTransaksi> barangTransaksis;

  Transaksi({
    required this.grandTotal,
    required this.barangTransaksis,
  });

  // Factory method untuk membuat Transaksi dari map
  factory Transaksi.fromJson(Map<String, dynamic> json) {
    var list = json['barang_transaksis'] as List;
    List<BarangTransaksi> barangList =
        list.map((i) => BarangTransaksi.fromJson(i)).toList();

    return Transaksi(
      grandTotal: json['grand_total'],
      barangTransaksis: barangList,
    );
  }

  // Method untuk mengubah Transaksi menjadi map
  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> barangList =
        barangTransaksis.map((i) => i.toJson()).toList();

    return {
      'grand_total': grandTotal,
      'barang_transaksis': barangList,
    };
  }
}
