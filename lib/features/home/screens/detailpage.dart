import 'package:flutter/material.dart';
import 'package:mobilepos_app/core/config/app_config.dart';
import 'package:mobilepos_app/shared/components/app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobilepos_app/data/repository/detail_item_repository.dart';

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
  String baseUrlGambar = 'https://karyahutamaoxy.cloud';

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
      backgroundColor: const Color(0xFFF8FBFF), // Light blue background
      appBar: const CustomAppbar(title: ("Detail"), showBackButton: true),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00A3FF),
              ),
            )
          : item == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Data Barang Tidak Ditemukan",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Main Product Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Color(0xFFF0F8FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00A3FF).withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Image with decorative elements
                              Container(
                                height: 250,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Stack(
                                    children: [
                                      // Product Image
                                      Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: NetworkImage(
                                                '$baseUrlGambar${item?['data']?['image'] ?? ''}'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      // Gradient overlay for better text visibility
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.3),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16.0),

                              // Product Name with accent
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00A3FF),
                                      Color(0xFF0088CC),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Text(
                                  item!['data']['nama_barang'],
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10.0),

                              // Price with special styling
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF00A3FF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF00A3FF)
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.attach_money,
                                      color: const Color(0xFF00A3FF),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Rp. ${item!['data']['harga']}",
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF00A3FF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12.0),

                              // Description
                              _buildInfoSection(
                                icon: Icons.description,
                                title: "Deskripsi",
                                content: item!['data']['deskripsi'] ??
                                    "Deskripsi tidak tersedia",
                              ),
                              const SizedBox(height: 8.0),

                              // Stock Info
                              _buildInfoSection(
                                icon: Icons.inventory,
                                title: "Stok Tersedia",
                                content:
                                    "${item!['data']['stok_tersedia']} unit",
                              ),
                              const SizedBox(height: 8.0),

                              // Category Info
                              _buildInfoSection(
                                icon: Icons.category,
                                title: "Kategori",
                                content: item!['data']['kategori']
                                    ['nama_kategori'],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00A3FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00A3FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
