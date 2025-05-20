import 'package:mobilepos_app/models/items.dart';

class BarangTransaksi {
  final int barangId;
  final String namaBarang;
  final double hargaBarang;
  int quantity;
  double totalHarga;

  BarangTransaksi({
    required this.barangId,
    required this.namaBarang,
    required this.hargaBarang,
    required this.quantity,
    required this.totalHarga,
  });

  // Factory method untuk membuat BarangTransaksi dari map
  factory BarangTransaksi.fromJson(Map<String, dynamic> json) {
    return BarangTransaksi(
      barangId: json['barang_id'],
      namaBarang: json['nama_barang'],
      hargaBarang: json['harga_barang'],
      quantity: json['quantity'],
      totalHarga: json['total_harga'],
    );
  }

  // Method untuk mengubah BarangTransaksi menjadi map
  Map<String, dynamic> toJson() {
    return {
      'barang_id': barangId,
      'harga_barang': hargaBarang,
      'quantity': quantity,
      'total_harga': totalHarga,
    };
  }

  factory BarangTransaksi.fromItem(Item item, int quantity) {
    return BarangTransaksi(
      barangId: item.id, // Assuming Item has an 'id' field
      namaBarang: item.namaBarang, // Assuming Item has a 'namaBarang' field
      hargaBarang: item.harga, // Assuming Item has a 'harga' field
      quantity: quantity,
      totalHarga: item.harga * quantity, // Calculate total price
    );
  }
}
