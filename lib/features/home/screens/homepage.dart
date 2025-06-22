import 'package:flutter/material.dart';
import 'package:mobilepos_app/core/config/app_config.dart';
import 'package:mobilepos_app/shared/components/app_bar.dart';
import 'package:mobilepos_app/data/models/items.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobilepos_app/data/repository/item_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobilepos_app/features/home/screens/detailpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mobilepos_app/shared/providers/cart_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late ItemRepository itemRepository;
  List<Item> items = [];
  List<dynamic> filteredItems = [];
  final TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  bool isNull = false;
  String baseUrl = AppConfig.baseUrl;
  String baseUrlGambar =
      'https://karyahutamaoxy.cloud'; // Ganti dengan URL gambar yang sesuai
  int currentPage = 1;
  late ScrollController scrollController;
  bool hasMoreData = true;

  //Ambil data pertama kali
  Future<void> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    try {
      final newItems = await itemRepository.fetchDataFromApi(token, page: 1);
      setState(() {
        items = newItems;
        filteredItems = newItems;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Kesalahan saat menampilkan barang, Harap login ulang')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      print("Error loading items: $error");
    }
  }

  Future<void> loadMoreItems() async {
    if (!hasMoreData) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    try {
      currentPage++; // ⏭️ Tambah halaman
      final newItems =
          await itemRepository.fetchDataFromApi(token, page: currentPage);

      if (newItems.isEmpty) {
        hasMoreData = false;
      } else {
        setState(() {
          items.addAll(newItems);
          filteredItems = items;
        });
      }
    } catch (error) {
      print('Error loading more items: $error');
    }
  }

  // Fungsi filter item berdasarkan input pencarian
  void filterItems(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredItems =
            List.from(items); // ✅ Jika query kosong, kembalikan semua item
      });
      return;
    }

    searchItems(query).then((searchResults) {
      setState(() {
        filteredItems = searchResults;
      });
    }).catchError((error) {
      print('Error searching items: $error');
    });
  }

  Future<List<Item>> searchItems(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    final String apiUrl = '$baseUrl/api/barang/search?q=$query';
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'];
      return data.map<Item>((itemJson) => Item.fromJson(itemJson)).toList();
    } else {
      throw Exception('Failed to search items');
    }
  }

  void onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 100) {
      loadMoreItems();
    }
  }

  Future<void> initializeRepository() async {
    final prefs = await SharedPreferences.getInstance();
    itemRepository = ItemRepository(prefs);
    loadItems(); // Commented for testing
  }

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(onScroll);
    initializeRepository();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FBFF), // Light blue background
        appBar: const CustomAppbar(title: 'Home'),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00A3FF),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search field with modern styling
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00A3FF).withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: "Cari barang...",
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: const Color(0xFF00A3FF),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        onChanged: (value) => filterItems(value),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Expanded(
                      child: GridView.builder(
                        controller: scrollController,
                        shrinkWrap: true,
                        itemCount: filteredItems.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          childAspectRatio: 0.7,
                        ),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Color(0xFFF0F8FF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF00A3FF).withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Image with modern styling
                                  Container(
                                    height: 130,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: '$baseUrlGambar${item.image}',
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                          color: const Color(0xFF00A3FF)
                                              .withOpacity(0.1),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF00A3FF),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: Icon(
                                              Icons.error,
                                              color: Color(0xFF00A3FF),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),

                                  // Product Name
                                  Text(
                                    item.namaBarang,
                                    style: const TextStyle(
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3.0),

                                  // Price with accent
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00A3FF)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF00A3FF)
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      "Rp. ${item.harga}",
                                      style: const TextStyle(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF00A3FF),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),

                                  // Stock information
                                  Text(
                                    "Stok: ${item.stokTersedia}",
                                    style: TextStyle(
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const Spacer(),

                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailPage(id: item.id),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF00A3FF),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6.0),
                                            ),
                                            elevation: 1,
                                          ),
                                          child: const Text(
                                            "Detail",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            cartProvider.addToCart(item);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6.0),
                                            ),
                                            elevation: 1,
                                          ),
                                          child: const Text(
                                            "+",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00A3FF),
                Color(0xFF0088CC),
              ],
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00A3FF).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home',
                  arguments: {'selectedIndex': 2});
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.white),
                  if (cartProvider.cartItems.isNotEmpty)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${cartProvider.cartItems.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
