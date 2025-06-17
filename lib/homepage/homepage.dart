import 'package:flutter/material.dart';
import 'package:mobilepos_app/app_config.dart';
import 'package:mobilepos_app/component/app_bar.dart';
import 'package:mobilepos_app/models/items.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobilepos_app/repository/item_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobilepos_app/homepage/detailpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mobilepos_app/providers/cart_provider.dart';

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
        backgroundColor: Colors.white,
        appBar: const CustomAppbar(title: 'Home'),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Cari barang...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onChanged: (value) => filterItems(value),
                    ),
                    const SizedBox(height: 8.0),
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
                          childAspectRatio: 3 / 4,
                        ),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 4.0,
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 100,
                                    width: double.infinity,
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          '$baseUrl/storage/${item.image}',
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) =>
                                          const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          const Center(
                                              child: Icon(Icons.error)),
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    item.namaBarang,
                                    style: const TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "Rp. ${item.harga}",
                                    style: const TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
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
                                            backgroundColor: Colors.blue,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                          child: const Text(
                                            "Details",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
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
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6, horizontal: 5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                          child: const Text(
                                            "+",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home',
                arguments: {'selectedIndex': 2});
          },
          backgroundColor: Colors.blue,
          child: SizedBox(
            width: 40, // Ukuran cukup buat ikon + badge
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.shopping_cart),
                if (cartProvider.cartItems.isNotEmpty)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cartProvider.cartItems.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
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
    );
  }
}
