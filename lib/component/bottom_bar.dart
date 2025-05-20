import 'package:flutter/material.dart';
import 'package:mobilepos_app/homepage/homepage.dart';
import 'package:mobilepos_app/scanbarcode/scanbarcode.dart';
import 'package:mobilepos_app/transaksi/transaksi.dart';

class CustomBottomBar extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const CustomBottomBar({super.key, this.arguments});

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  late int _selectedIndex;
  final List<Widget?> _pages = [const HomePage(), null, const Transaksi()];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.arguments?['selectedIndex'] ?? 0;
  }

  void _onItemTapped(int index) {
    if (index == 1 && _pages[1] == null) {
      // Render ScanBarcode hanya saat pertama kali dipilih
      _pages[1] = const Scanbarcode();
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.qr_code), label: 'Scan'),
          NavigationDestination(
              icon: Icon(Icons.payment_outlined), label: 'Transaksi'),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages.map((page) => page ?? const SizedBox()).toList(),
        ),
      ),
    );
  }
}
