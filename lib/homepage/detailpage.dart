import 'package:flutter/material.dart';
import 'package:mobilepos_app/app_config.dart';
import 'package:mobilepos_app/component/app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobilepos_app/repository/detail_item_repository.dart';

class DetailPage extends StatefulWidget {
  final int? id;
  final String? barcode;

  const DetailPage({super.key, this.id, this.barcode});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Map<String, dynamic>? item;
  bool isLoading = true;
  late DetailItemRepository _repository;
  String baseUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    final prefs = await SharedPreferences.getInstance();
    _repository = DetailItemRepository(prefs);
    showDetail();
  }

  Future<void> showDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    try {
      final data = await _repository.fetchDetail(
        id: widget.id,
        barcode: widget.barcode,
        token: token,
      );

      if (mounted) {
        setState(() {
          item = data;
          isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print("Error fetching item details: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppbar(title: ("Detail"), showBackButton: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : item == null
              ? const Center(child: Text("Data Barang Tidak Ditemukan"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: SizedBox(
                        width: 250,
                        height: 500,
                        child: Card(
                            color: Colors.white70,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Gambar
                                  Container(
                                    height: 200,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                            '$baseUrl/storage/${item!['data']['image']}'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  // Nama barang
                                  Text(
                                    item!['data']['nama_barang'],
                                    style: const TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  // Harga barang
                                  Text(
                                    "Rp. ${item!['data']['harga']}",
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  // Deskripsi
                                  Text(
                                    item!['data']['deskripsi'] ??
                                        "Deskripsi tidak tersedia",
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                  const SizedBox(height: 8.0),
                                  // Stok barang
                                  Text(
                                    "Stok: ${item!['data']['stok_tersedia']}",
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                  const SizedBox(height: 8.0),
                                  // Stok barang
                                  Text(
                                    "Kategori: ${item!['data']['kategori']['nama_kategori']}",
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                ],
                              ),
                            ))),
                  )),
    );
  }
}
