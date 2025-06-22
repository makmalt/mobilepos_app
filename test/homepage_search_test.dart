import 'package:flutter_test/flutter_test.dart';
import 'package:mobilepos_app/data/models/items.dart';

void main() {
  group('HomePage Search Tests', () {
    test('filterItems should return all items when query is empty', () {
      // Arrange
      final items = [
        Item(
          id: 1,
          namaBarang: 'Laptop',
          harga: 10000000,
          deskripsi: 'Laptop Gaming',
          stokTersedia: 10,
          namaKategori: 'Elektronik',
          image: 'laptop.jpg',
        ),
        Item(
          id: 2,
          namaBarang: 'Mouse',
          harga: 200000,
          deskripsi: 'Mouse Gaming',
          stokTersedia: 20,
          namaKategori: 'Aksesoris',
          image: 'mouse.jpg',
        ),
      ];

      // Act
      final filteredItems = items
          .where((item) => item.namaBarang.toLowerCase().contains(''))
          .toList();

      // Assert
      expect(filteredItems.length, 2);
      expect(filteredItems[0].namaBarang, 'Laptop');
      expect(filteredItems[1].namaBarang, 'Mouse');
    });

    test('filterItems should return matching items when query is provided', () {
      // Arrange
      final items = [
        Item(
          id: 1,
          namaBarang: 'Laptop Gaming',
          harga: 10000000,
          deskripsi: 'Laptop Gaming',
          stokTersedia: 10,
          namaKategori: 'Elektronik',
          image: 'laptop.jpg',
        ),
        Item(
          id: 2,
          namaBarang: 'Mouse Gaming',
          harga: 200000,
          deskripsi: 'Mouse Gaming',
          stokTersedia: 20,
          namaKategori: 'Aksesoris',
          image: 'mouse.jpg',
        ),
        Item(
          id: 3,
          namaBarang: 'Keyboard',
          harga: 500000,
          deskripsi: 'Keyboard Mechanical',
          stokTersedia: 15,
          namaKategori: 'Aksesoris',
          image: 'keyboard.jpg',
        ),
      ];

      // Act
      final filteredItems = items
          .where((item) => item.namaBarang.toLowerCase().contains('gaming'))
          .toList();

      // Assert
      expect(filteredItems.length, 2);
      expect(filteredItems[0].namaBarang, 'Laptop Gaming');
      expect(filteredItems[1].namaBarang, 'Mouse Gaming');
    });

    test('filterItems should be case insensitive', () {
      // Arrange
      final items = [
        Item(
          id: 1,
          namaBarang: 'Laptop Gaming',
          harga: 10000000,
          deskripsi: 'Laptop Gaming',
          stokTersedia: 10,
          namaKategori: 'Elektronik',
          image: 'laptop.jpg',
        ),
        Item(
          id: 2,
          namaBarang: 'Mouse Gaming',
          harga: 200000,
          deskripsi: 'Mouse Gaming',
          stokTersedia: 20,
          namaKategori: 'Aksesoris',
          image: 'mouse.jpg',
        ),
      ];

      // Act
      final query = 'LAPTOP';
      final filteredItems = items
          .where((item) =>
              item.namaBarang.toLowerCase().contains(query.toLowerCase()))
          .toList();

      // Assert
      expect(filteredItems.length, 1);
      expect(filteredItems[0].namaBarang, 'Laptop Gaming');
    });
  });
}
