import 'package:mobilepos_app/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final String baseUrl = AppConfig.baseUrl;
  final bool showBackButton;

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        await prefs.remove('access_token'); // 🔥 HAPUS TOKEN
        if (!context.mounted) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        // Jika API gagal, bisa menunjukkan pesan error atau melakukan tindakan lain
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi Kesalahan')),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Menutup dialog
              },
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () {
                logout(context); // Menjalankan logout
              },
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  const CustomAppbar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(150),
          child: Container(
            width: screenWidth,
            height: screenHeight,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -7,
                  right: -7,
                  top: -15,
                  child: Container(
                    width: screenWidth,
                    height: 100,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF00A3FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                ),
                if (showBackButton)
                  Positioned(
                    left: 15,
                    top: 18,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                Positioned(
                  left: showBackButton ? 60 : 15,
                  top: 18,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ),
                Positioned(
                  left: 330,
                  top: 18,
                  child: IconButton(
                    icon: const Icon(
                      Icons.logout,
                      size: 30,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _showLogoutDialog(context);
                    },
                  ),
                ),
                if (actions != null)
                  Positioned(
                    right: 60,
                    top: 18,
                    child: Row(
                      children: actions!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
