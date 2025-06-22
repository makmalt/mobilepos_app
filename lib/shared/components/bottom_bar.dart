import 'package:flutter/material.dart';
import 'package:mobilepos_app/features/home/screens/homepage.dart';
import 'package:mobilepos_app/features/barcode/screens/scanbarcode.dart';
import 'package:mobilepos_app/features/transaction/screens/transaksi.dart';

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
      backgroundColor: const Color(0xFFF8FBFF), // Light blue background
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF0F8FF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00A3FF).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          onDestinationSelected: _onItemTapped,
          selectedIndex: _selectedIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: const Color(0xFF00A3FF).withOpacity(0.2),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: _selectedIndex == 0
                    ? const Color(0xFF00A3FF)
                    : Colors.grey[600],
              ),
              selectedIcon: Icon(
                Icons.home,
                color: const Color(0xFF00A3FF),
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.qr_code_scanner_outlined,
                color: _selectedIndex == 1
                    ? const Color(0xFF00A3FF)
                    : Colors.grey[600],
              ),
              selectedIcon: Icon(
                Icons.qr_code_scanner,
                color: const Color(0xFF00A3FF),
              ),
              label: 'Scan',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.payment_outlined,
                color: _selectedIndex == 2
                    ? const Color(0xFF00A3FF)
                    : Colors.grey[600],
              ),
              selectedIcon: Icon(
                Icons.payment,
                color: const Color(0xFF00A3FF),
              ),
              label: 'Transaksi',
            ),
          ],
        ),
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
