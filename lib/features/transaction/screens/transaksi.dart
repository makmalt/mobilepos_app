// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mobilepos_app/shared/components/app_bar.dart';
import 'package:mobilepos_app/data/models/barang_transaksi.dart';
import 'package:mobilepos_app/data/repository/transaksi_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mobilepos_app/shared/providers/cart_provider.dart';
import 'package:mobilepos_app/data/services/printer_service.dart';
import 'package:mobilepos_app/screens/printer_settings_screen.dart';

class Transaksi extends StatefulWidget {
  const Transaksi({super.key});

  @override
  State<Transaksi> createState() => _TransaksiState();
}

class _TransaksiState extends State<Transaksi> {
  List<BarangTransaksi> transactionItems = [];
  bool isLoading = true;
  bool isSubmitting = false;
  int currentPage = 1;
  double nominalPembayaran = 0;
  double kembalian = 0;
  final PrinterService _printerService = PrinterService();
  late TransaksiRepository _transaksiRepository;

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF00A3FF),
                  Color(0xFF0088CC),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              'Transaksi Berhasil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          content: Text(
            'Kembalian: ${formatCurrency(kembalian)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A3FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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
              child: const Text('Cetak Struk',
                  style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                clearTransaction();
              },
              child: const Text('Selesai',
                  style: TextStyle(color: Color(0xFF00A3FF))),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Gagal menyimpan transaksi';
      
      // Cek apakah error terkait koneksi internet
      if (e.toString().contains('Tidak ada koneksi internet')) {
        errorMessage = 'Tidak ada koneksi internet. Mohon periksa koneksi Anda.';
      } else if (e.toString().contains('Gagal terhubung ke server')) {
        errorMessage = 'Gagal terhubung ke server. Silakan coba lagi.';
      } else if (e.toString().contains('Koneksi timeout')) {
        errorMessage = 'Koneksi timeout. Silakan coba lagi.';
      } else if (e.toString().contains('Token tidak ditemukan') || 
                 e.toString().contains('401')) {
        errorMessage = 'Sesi Anda telah berakhir. Silakan login ulang.';
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Coba Lagi',
            textColor: Colors.white,
            onPressed: () {
              completeTransaction();
            },
          ),
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF00A3FF),
                  Color(0xFF0088CC),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              'Konfirmasi Transaksi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          content: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A3FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00A3FF).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payment,
                        color: const Color(0xFF00A3FF),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Total: ${formatCurrency(_transaksiRepository.calculateTotal(transactionItems))}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00A3FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00A3FF).withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: bayarController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Nominal Pembayaran',
                      labelStyle: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: const Color(0xFF00A3FF),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF00A3FF),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Validasi input
                      nominalPembayaran =
                          double.tryParse(bayarController.text) ?? 0;
                      kembalian = nominalPembayaran -
                          _transaksiRepository.calculateTotal(transactionItems);

                      if (nominalPembayaran <
                          _transaksiRepository
                              .calculateTotal(transactionItems)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Nominal pembayaran kurang!')),
                        );
                        Navigator.of(context).pop();
                        return;
                      }

                      Navigator.of(context).pop();
                      completeTransaction();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A3FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 3,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
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
      backgroundColor: const Color(0xFFF8FBFF), // Light blue background
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
                const EdgeInsets.only(bottom: 120.0), // Ruang untuk total harga
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactionItems.length,
              itemBuilder: (context, index) {
                final item = transactionItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Color(0xFFF0F8FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00A3FF).withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Product info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaBarang,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF00A3FF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF00A3FF)
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${item.quantity} x Rp ${item.hargaBarang.toString()}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00A3FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A3FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add,
                                  color: Color(0xFF00A3FF),
                                ),
                                onPressed: () {
                                  setState(() {
                                    item.quantity++;
                                    item.totalHarga =
                                        item.quantity * item.hargaBarang;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A3FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.remove,
                                  color: Color(0xFF00A3FF),
                                ),
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
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    // Get the item to be deleted
                                    final deletedItem = transactionItems[index];
                                    // Remove from transaction items
                                    transactionItems.removeAt(index);

                                    // Remove all instances of this item from CartProvider
                                    final cartProvider =
                                        Provider.of<CartProvider>(context,
                                            listen: false);
                                    cartProvider.removeAllItemsWithId(
                                        deletedItem.barangId);
                                  });
                                },
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
          // Bagian bawah: Total harga dan tombol
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xFFF8FBFF),
                  ],
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
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
                      color: const Color(0xFF00A3FF).withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Total Harga
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.payment,
                              color: const Color(0xFF00A3FF),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A3FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF00A3FF).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            formatCurrency(calculateTotal()),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00A3FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tombol Selesaikan Transaksi
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () => _showConfirmationDialog(context),
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(
                          isSubmitting
                              ? 'Memproses...'
                              : 'Selesaikan Transaksi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A3FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
