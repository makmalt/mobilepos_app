import 'package:flutter_test/flutter_test.dart';
import 'package:mobilepos_app/data/models/items.dart';
import 'package:mobilepos_app/data/repository/item_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([ItemRepository, SharedPreferences])
import 'homepage_load_test.mocks.dart';

void main() {
  late MockItemRepository mockItemRepository;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockItemRepository = MockItemRepository();
    mockPrefs = MockSharedPreferences();
  });

  group('Memuat Data Barang Tests', () {
    test('Memuat Data Barang Berhasil', () async {
      // Arrange
      const token = 'test_token';
      final mockItems = [
        Item(
          id: 1,
          namaBarang: 'Cat Avian Putih',
          harga: 10000000,
          deskripsi: 'Cat Avian Putih',
          stokTersedia: 10,
          namaKategori: 'Cat',
          image: 'catavianputih.jpg',
        ),
        Item(
          id: 2,
          namaBarang: 'Cat Avian Merah',
          harga: 200000,
          deskripsi: 'Cat Avian Merah',
          stokTersedia: 20,
          namaKategori: 'Cat',
          image: 'catavianmerah.jpg',
        ),
      ];

      when(mockPrefs.getString('access_token')).thenReturn(token);
      when(mockItemRepository.fetchDataFromApi(token, page: 1))
          .thenAnswer((_) async => mockItems);

      // Act
      final result = await mockItemRepository.fetchDataFromApi(token);

      // Assert
      expect(result.length, 2);
      expect(result[0].namaBarang, 'Cat Avian Putih');
      expect(result[1].namaBarang, 'Cat Avian Merah');
      print('Data barang berhasil dimuat');
      for (var item in result) {
        print('Nama Barang: ${item.namaBarang}, Harga: ${item.harga}');
      }
      verify(mockItemRepository.fetchDataFromApi(token, page: 1)).called(1);
    });

    test('Memuat Data Barang Kosong', () async {
      // Arrange
      const token = 'test_token';
      when(mockPrefs.getString('access_token')).thenReturn(token);
      when(mockItemRepository.fetchDataFromApi(token, page: 1))
          .thenAnswer((_) async => []);

      // Act
      final result = await mockItemRepository.fetchDataFromApi(token);

      // Assert
      if (result.isEmpty) {
        print('Tidak ada barang');
      }
      expect(result, isEmpty);
      verify(mockItemRepository.fetchDataFromApi(token, page: 1)).called(1);
    });

    test('Memuat Data Barang Gagal', () async {
      // Arrange
      const token = 'test_token';
      when(mockPrefs.getString('access_token')).thenReturn(token);
      when(mockItemRepository.fetchDataFromApi(token, page: 1))
          .thenThrow(Exception('Terjadi kesalahan saat memuat data barang'));

      // Act & Assert
      expect(
        () => mockItemRepository.fetchDataFromApi(token),
        throwsException,
      );
      print('Terjadi kesalahan saat memuat data barang');
      verify(mockItemRepository.fetchDataFromApi(token, page: 1)).called(1);
    });
  });
}
