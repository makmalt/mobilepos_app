// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mobilepos_app/app_config.dart';
import 'package:mobilepos_app/component/app_bar.dart';
import 'package:mobilepos_app/models/items.dart';
import 'package:mobilepos_app/models/barang_transaksi.dart';
import 'package:http/http.dart' as http;
import 'package:mobilepos_app/repository/item_repository.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mobilepos_app/providers/cart_provider.dart';
// import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class Transaksi extends StatefulWidget {
  const Transaksi({super.key});

  @override
  State<Transaksi> createState() => _TransaksiState();
}

class _TransaksiState extends State<Transaksi> {
  List<Item> availableItems = [];
  List<BarangTransaksi> transactionItems = [];
  bool isLoading = true;
  bool isSubmitting = false;
  List<dynamic> filteredItems = [];
  TextEditingController searchController = TextEditingController();
  int currentPage = 1;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  late ScrollController modalScrollController = ScrollController();
  double nominalPembayaran = 0;
  double kembalian = 0;
  // final BlueThermalPrinter printer = BlueThermalPrinter.instance;
  // Flag untuk mencegah multiple requests
  bool _isSearching = false;

  String baseUrl = AppConfig.baseUrl;
//service
  Future<void> _loadItems() async {
    if (isLoading == false) return; // Prevent duplicate calls

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final ItemRepository itemRepository;
    itemRepository = ItemRepository(await SharedPreferences.getInstance());

    try {
      final newItems = await itemRepository.fetchDataFromApi(token);
      // Cek apakah widget masih mounted sebelum setState
      if (!mounted) return;

      setState(() {
        availableItems = newItems;
        filteredItems = newItems;
        isLoading = false;
      });
    } catch (error) {
      // Cek apakah widget masih mounted sebelum setState
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
      print("Error loading items: $error");
    }
  }

  Future<void> _loadMoreItems() async {
    if (!hasMoreData || isLoadingMore) return; // Prevent duplicate calls

    setState(() {
      isLoadingMore = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final ItemRepository itemRepository;
    itemRepository = ItemRepository(await SharedPreferences.getInstance());

    try {
      currentPage++; // ⏭️ Tambah halaman
      final newItems =
          await itemRepository.fetchDataFromApi(token, page: currentPage);

      // Cek apakah widget masih mounted sebelum setState
      if (!mounted) return;

      setState(() {
        isLoadingMore = false;
        if (newItems.isEmpty) {
          hasMoreData = false; // ⛔ Set false kalau nggak ada data lagi
        } else {
          availableItems.addAll(newItems);
          filteredItems =
              List.from(availableItems); // Ensure a new copy is created
        }
      });
    } catch (error) {
      // Cek apakah widget masih mounted sebelum setState
      if (!mounted) return;

      setState(() {
        isLoadingMore = false;
      });
      print('Error loading more items: $error');
    }
  }

  void _onScroll() {
    if (modalScrollController.position.pixels >=
        modalScrollController.position.maxScrollExtent - 100) {
      _loadMoreItems();
    }
  }

  @override
  void initState() {
    super.initState();
    modalScrollController = ScrollController();
    modalScrollController.addListener(_onScroll);
    _loadItems();

    // Initialize transaction items from cart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      setState(() {
        transactionItems = cartProvider.getTransactionItems();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to cart changes
    final cartProvider = Provider.of<CartProvider>(context);
    setState(() {
      transactionItems = cartProvider.getTransactionItems();
    });
  }

  @override
  void dispose() {
    modalScrollController.dispose(); // Pastikan controller dibersihkan
    searchController.dispose(); // Bersihkan controller pencarian
    super.dispose();
  }

  double calculateTotal() {
    return transactionItems.fold(
        0, (total, item) => total + (item.hargaBarang * item.quantity));
  }

  // void cetakStruk(int transaksiId) async {
  //   // lanjut seperti yang udah kita bahas sebelumnya
  //   void cetakStruk(int transaksiId) async {
  //     try {
  //       // 1. Get list printer
  //       List<BluetoothDevice> devices = await printer.getBondedDevices();

  //       if (devices.isEmpty) {
  //         print("No printer connected.");
  //         return;
  //       }

  //       // 2. Pilih printer pertama (kalau mau langsung, atau bisa show pilihan kayak sebelumnya)
  //       BluetoothDevice selectedPrinter = devices.first;

  //       // 3. Connect ke printer
  //       await printer.connect(selectedPrinter);

  //       // 4. Fetch struk dari backend (format TEXT, bukan HTML/PDF)
  //       final response = await http.get(
  //         Uri.parse("https://domainmu.com/api/struk/$transaksiId"),
  //       );

  //       if (response.statusCode == 200) {
  //         String struk = response.body;

  //         // 5. Print ke thermal printer
  //         printer.printNewLine();
  //         printer.printCustom(struk, 1, 0); // ukuran normal, kiri
  //         printer.printNewLine();
  //         printer.paperCut();
  //       } else {
  //         print("Gagal ambil struk dari server.");
  //       }
  //     } catch (e) {
  //       print("Error saat cetak struk: $e");
  //     }
  //   }
  // }

  Future<void> completeTransaction() async {
    if (transactionItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan barang terlebih dahulu!')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    // Cek apakah widget masih mounted sebelum setState
    if (!mounted) return;

    setState(() {
      isSubmitting = true;
    });

    double grandTotal = calculateTotal();

    try {
      final List<Map<String, dynamic>> itemsData = transactionItems.map((item) {
        return {
          'barang_id': item.barangId,
          'harga_barang': item.hargaBarang,
          'quantity': item.quantity,
          'total_harga': item.quantity * item.hargaBarang,
        };
      }).toList();

      final response = await http.post(
        Uri.parse('$baseUrl/api/transaksi'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'barang_transaksis': itemsData,
          'grand_total': grandTotal,
          'uang_pembayaran': nominalPembayaran,
          'uang_kembalian': kembalian,
        }),
      );

      // Cek apakah widget masih mounted sebelum interaksi UI
      if (!mounted) return;

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final transaksiId = data['transaksi_id'];
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Transaksi Berhasil'),
            content: Text('Kembalian: ${formatCurrency(kembalian)}'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Tutup dialog
                    clearTransaction(); // Reset semua data transaksi
                  },
                  // onPressed: () => cetakStruk(transaksiId),
                  child: const Text('Cetak Struk')),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  clearTransaction(); // Reset semua data transaksi
                },
                child: const Text('Selesai'),
              ),
            ],
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Gagal menyimpan transaksi: ${errorData['message']}');
      }
    } catch (e) {
      // Cek apakah widget masih mounted sebelum interaksi UI
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
      );
    } finally {
      // Cek apakah widget masih mounted sebelum setState
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });
    }
  }

  void clearTransaction() {
    if (!mounted) return;

    setState(() {
      transactionItems.clear();
      nominalPembayaran = 0;
      kembalian = 0;
    });

    // Clear the cart in CartProvider
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.clearCart();
  }

//ui
  void addItemToTransaction(Item item) {
    // Cek apakah widget masih mounted sebelum setState
    if (!mounted) return;

    final existingTransaction = transactionItems.firstWhere(
      (trans) => trans.barangId == item.id,
      orElse: () => BarangTransaksi(
        barangId: 0,
        namaBarang: "",
        hargaBarang: 0,
        quantity: 0,
        totalHarga: 0,
      ),
    );

    setState(() {
      if (existingTransaction.barangId != 0) {
        existingTransaction.quantity++;
        existingTransaction.totalHarga =
            existingTransaction.quantity * existingTransaction.hargaBarang;
      } else {
        transactionItems.add(BarangTransaksi.fromItem(item, 1));
      }
    });
  }

  void filterItems(String query) {
    // Mencegah multiple search requests yang berjalan bersamaan
    if (_isSearching) return;

    if (query.isEmpty) {
      setState(() {
        filteredItems = List.from(
            availableItems); // ✅ Jika query kosong, kembalikan semua item
      });
      return;
    }

    _isSearching = true;

    searchItems(query).then((searchResults) {
      // Cek apakah widget masih mounted sebelum setState
      if (!mounted) return;

      setState(() {
        filteredItems = searchResults;
        _isSearching = false;
      });
    }).catchError((error) {
      // Cek apakah widget masih mounted
      if (!mounted) return;

      setState(() {
        _isSearching = false;
      });
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

  void _showConfirmationDialog(BuildContext context) {
    TextEditingController bayarController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Transaksi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total: ${formatCurrency(calculateTotal())}'),
              TextField(
                controller: bayarController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Nominal Pembayaran'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                // Validasi input
                nominalPembayaran = double.tryParse(bayarController.text) ?? 0;
                kembalian = nominalPembayaran - calculateTotal();

                if (nominalPembayaran < calculateTotal()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nominal pembayaran kurang!')),
                  );
                  Navigator.of(context).pop();
                  return;
                }

                Navigator.of(context).pop();
                completeTransaction(); // tetap panggil ini setelah dialog ditutup
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> showAddItemModal() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final ItemRepository itemRepository = ItemRepository(prefs);

    List<Item> modalItems = [];
    List<Item> modalFilteredItems = [];
    int modalCurrentPage = 1;
    bool modalIsLoading = true;
    bool modalIsLoadingMore = false;
    bool modalHasMoreData = true;
    bool modalIsSearching =
        false; // Flag untuk mencegah multiple search requests

    // Cek apakah widget masih mounted sebelum menampilkan modal
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true, // Penting untuk memberikan lebih banyak ruang
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final ScrollController modalScrollController = ScrollController();

            // Load first page inside modal
            Future<void> fetchInitialData() async {
              try {
                final fetchedItems =
                    await itemRepository.fetchDataFromApi(token, page: 1);
                // Cek apakah modal masih aktif sebelum update state
                setModalState(() {
                  modalItems = fetchedItems;
                  modalFilteredItems = List.from(fetchedItems);
                  modalHasMoreData = fetchedItems.isNotEmpty;
                  modalIsLoading = false;
                });
              } catch (e) {
                // Cek apakah modal masih aktif sebelum update state
                setModalState(() {
                  modalIsLoading = false;
                });
                print("Failed to fetch initial items in modal: $e");
              }
            }

            if (modalIsLoading) fetchInitialData();

            modalScrollController.addListener(() {
              if (modalScrollController.position.pixels >=
                      modalScrollController.position.maxScrollExtent - 100 &&
                  !modalIsLoadingMore &&
                  modalHasMoreData) {
                setModalState(() => modalIsLoadingMore = true);
                modalCurrentPage++;
                itemRepository
                    .fetchDataFromApi(token, page: modalCurrentPage)
                    .then((newItems) {
                  // Cek apakah ada duplikasi item sebelum menambahkan ke list
                  final Set<int> existingIds =
                      modalItems.map((item) => item.id).toSet();
                  final List<Item> uniqueNewItems = newItems
                      .where((item) => !existingIds.contains(item.id))
                      .toList();

                  // Cek apakah modal masih aktif sebelum update state
                  setModalState(() {
                    if (uniqueNewItems.isEmpty) {
                      modalHasMoreData = false;
                    } else {
                      modalItems.addAll(uniqueNewItems);
                      // Hanya update modalFilteredItems jika tidak sedang melakukan pencarian
                      if (!modalIsSearching) {
                        modalFilteredItems = List.from(modalItems);
                      }
                    }
                    modalIsLoadingMore = false;
                  });
                }).catchError((e) {
                  // Cek apakah modal masih aktif sebelum update state
                  setModalState(() => modalIsLoadingMore = false);
                  print("Failed to load more in modal: $e");
                });
              }
            });

            void filterModalItems(String query) {
              if (modalIsSearching) return; // Prevent multiple searches

              if (query.isEmpty) {
                setModalState(() {
                  modalFilteredItems = List.from(modalItems);
                });
                return;
              }

              setModalState(() => modalIsSearching = true);

              searchItems(query).then((results) {
                // Cek apakah modal masih aktif sebelum update state
                setModalState(() {
                  modalFilteredItems = results;
                  modalIsSearching = false;
                });
              }).catchError((e) {
                // Cek apakah modal masih aktif sebelum update state
                setModalState(() => modalIsSearching = false);
                print("Search error: $e");
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height *
                  0.75, // Set height untuk modal lebih besar
              child: modalIsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Cari Barang',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(Icons.search),
                            ),
                            onChanged: filterModalItems,
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: modalScrollController,
                            itemCount: modalFilteredItems.length +
                                (modalIsLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == modalFilteredItems.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }

                              final item = modalFilteredItems[index];
                              return ListTile(
                                title: Text(item.namaBarang),
                                subtitle: Text(
                                    'Rp ${item.harga} - Stok: ${item.stokTersedia}'),
                                onTap: () {
                                  if (item.stokTersedia > 0) {
                                    addItemToTransaction(item);
                                    Navigator.pop(context);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Stok tidak cukup')),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  String formatCurrency(double amount) {
    // Mengubah angka menjadi format yang lebih mudah dibaca
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.');
    return 'Rp. $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppbar(
        title: 'Transaksi',
      ),
      body: Stack(
        children: [
          // Bagian atas: Daftar barang
          Padding(
            padding:
                const EdgeInsets.only(bottom: 100.0), // Ruang untuk total harga
            child: ListView.builder(
              itemCount: transactionItems.length,
              itemBuilder: (context, index) {
                final item = transactionItems[index];
                return ListTile(
                  title: Text(item.namaBarang),
                  subtitle: Text(
                      '${item.quantity} x Rp ${item.hargaBarang.toString()}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            item.quantity++;
                            item.totalHarga = item.quantity * item.hargaBarang;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (item.quantity > 1) {
                              item.quantity--;
                              item.totalHarga =
                                  item.quantity * item.hargaBarang;
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            // Get the item to be deleted
                            final deletedItem = transactionItems[index];
                            // Remove from transaction items
                            transactionItems.removeAt(index);

                            // Remove all instances of this item from CartProvider
                            final cartProvider = Provider.of<CartProvider>(
                                context,
                                listen: false);
                            cartProvider
                                .removeAllItemsWithId(deletedItem.barangId);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 310.0, right: 20),
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF00A3FF),
                onPressed: showAddItemModal,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Bagian bawah: Total harga dan tombol
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Total Harga
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatCurrency(calculateTotal()),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Tombol Selesaikan Transaksi
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () => _showConfirmationDialog(context),
                    // ignore: sort_child_properties_last
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Selesaikan Transaksi',
                            style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
