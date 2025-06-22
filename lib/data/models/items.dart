class Item {
  final int id;
  final String namaBarang;
  final double harga;
  final String deskripsi;
  final int stokTersedia;
  final String namaKategori;
  final String image;

  Item({
    required this.id,
    required this.namaBarang,
    required this.harga,
    required this.deskripsi,
    required this.stokTersedia,
    required this.namaKategori,
    required this.image,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: _parseToInt(json['id']),
      namaBarang: json['nama_barang'] ?? '',
      harga: _parseToDouble(json['harga']),
      deskripsi: json['deskripsi'] ?? 'Deskripsi tidak tersedia',
      stokTersedia: _parseToInt(json['stok_tersedia']),
      namaKategori: json['kategori']?['nama_kategori'] ?? 'N/A',
      image: json['image'] ?? 'N/A',
    );
  }

// Helper method to safely parse to int
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) {
      return value.toInt();
    }
    return 0;
  }

// Helper method to safely parse to double
  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
