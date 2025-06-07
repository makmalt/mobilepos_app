// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mobilepos_app/app_config.dart';
import 'package:mobilepos_app/component/app_bar.dart';
import 'package:mobilepos_app/models/items.dart';
import 'package:mobilepos_app/models/barang_transaksi.dart';
import 'package:mobilepos_app/repository/transaksi_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mobilepos_app/providers/cart_provider.dart';
import 'package:mobilepos_app/services/printer_service.dart';
import 'package:mobilepos_app/screens/printer_settings_screen.dart';


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
  int currentPage = 1;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  double nominalPembayaran = 0;
  double kembalian = 0;
  final PrinterService _printerService = PrinterService();
  late TransaksiRepository _transaksiRepository;

  String baseUrl = AppConfig.baseUrl;
//service

  @override
  void initState() {
    super.initState();
    initializeRepositories();

    // Initialize transaction items from cart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      setState(() {
        transactionItems = cartProvider.getTransactionItems();
      });
    });
  }

  Future<void> initializeRepositories() async {
    final prefs = await SharedPreferences.getInstance();
    _transaksiRepository = TransaksiRepository(prefs);
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
    super.dispose();
  }

  double calculateTotal() {
    return transactionItems.fold(
        0, (total, item) => total + (item.hargaBarang * item.quantity));
  }

  Future<void> completeTransaction() async {
    if (transactionItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan barang terlebih dahulu!')),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final result = await _transaksiRepository.completeTransaction(
        transactionItems: transactionItems,
        nominalPembayaran: nominalPembayaran,
        kembalian: kembalian,
      );

      if (!mounted) return;

      final noTransaksi = result['data']['no_transaksi'];
      final grandTotal = result['grandTotal'];

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Transaksi Berhasil'),
          content: Text('Kembalian: ${formatCurrency(kembalian)}'),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await _printerService.printReceipt(
                    items: transactionItems,
                    total: grandTotal,
                    payment: nominalPembayaran,
                    change: kembalian,
                    noTransaksi: noTransaksi,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Struk berhasil dicetak')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mencetak struk: $e')),
                  );
                }
              },
              child: const Text('Cetak Struk'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                clearTransaction();
              },
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
      );
    } finally {
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
              Text(
                  'Total: ${formatCurrency(_transaksiRepository.calculateTotal(transactionItems))}'),
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
                kembalian = nominalPembayaran -
                    _transaksiRepository.calculateTotal(transactionItems);

                if (nominalPembayaran <
                    _transaksiRepository.calculateTotal(transactionItems)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nominal pembayaran kurang!')),
                  );
                  Navigator.of(context).pop();
                  return;
                }

                Navigator.of(context).pop();
                completeTransaction();
              },
              child: const Text('OK'),
            ),
          ],
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
      appBar: CustomAppbar(
        title: 'Transaksi',
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrinterSettingsScreen(),
                ),
              );
            },
          ),
        ],
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
