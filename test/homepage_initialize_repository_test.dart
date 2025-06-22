import 'package:flutter_test/flutter_test.dart';
import 'package:mobilepos_app/features/home/screens/homepage.dart';
import 'package:mobilepos_app/data/repository/item_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Panggil method initializeRepository', () async {
    // Setup mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Buat instance state
    final state = HomePageState();

    // Panggil fungsi
    await state.initializeRepository();

    // Verifikasi
    expect(state.itemRepository, isA<ItemRepository>());
    print('Repository berhasil diinisialisasi');
  });
}
