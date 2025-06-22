import 'package:flutter_test/flutter_test.dart';
import 'package:mobilepos_app/data/models/items.dart';

void main() {
  group('Item Model Tests', () {
    test('Item.fromJson should create Item object correctly', () {
      // Arrange
      final json = {
        'id': 1,
        'nama_barang': 'Test Item',
        'harga': 10000,
        'deskripsi': 'Test Description',
        'stok_tersedia': 10,
        'kategori': {'nama_kategori': 'Test Category'},
        'image': 'test.jpg'
      };

      // Act
      final item = Item.fromJson(json);

      // Assert
      expect(item.id, 1);
      expect(item.namaBarang, 'Test Item');
      expect(item.harga, 10000.0);
      expect(item.deskripsi, 'Test Description');
      expect(item.stokTersedia, 10);
      expect(item.namaKategori, 'Test Category');
      expect(item.image, 'test.jpg');
    });

    test('Item.fromJson should handle null values', () {
      // Arrange
      final json = {
        'id': 1,
        'nama_barang': null,
        'harga': null,
        'deskripsi': null,
        'stok_tersedia': null,
        'kategori': null,
        'image': null
      };

      // Act
      final item = Item.fromJson(json);

      // Assert
      expect(item.id, 1);
      expect(item.namaBarang, '');
      expect(item.harga, 0.0);
      expect(item.deskripsi, 'Deskripsi tidak tersedia');
      expect(item.stokTersedia, 0);
      expect(item.namaKategori, 'N/A');
      expect(item.image, 'N/A');
    });

    test('Item.fromJson should handle string numbers', () {
      // Arrange
      final json = {
        'id': '1',
        'nama_barang': 'Test Item',
        'harga': '10000',
        'deskripsi': 'Test Description',
        'stok_tersedia': '10',
        'kategori': {'nama_kategori': 'Test Category'},
        'image': 'test.jpg'
      };

      // Act
      final item = Item.fromJson(json);

      // Assert
      expect(item.id, 1);
      expect(item.harga, 10000.0);
      expect(item.stokTersedia, 10);
    });

    test('Item.fromJson should handle missing kategori', () {
      // Arrange
      final json = {
        'id': 1,
        'nama_barang': 'Test Item',
        'harga': 10000,
        'deskripsi': 'Test Description',
        'stok_tersedia': 10,
        'image': 'test.jpg'
      };

      // Act
      final item = Item.fromJson(json);

      // Assert
      expect(item.namaKategori, 'N/A');
    });
  });
}
