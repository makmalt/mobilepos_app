import 'package:mobilepos_app/core/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

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
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Koneksi timeout. Silakan coba lagi.');
        },
      );

      if (response.statusCode == 200) {
        await prefs.remove('access_token'); // 🔥 HAPUS TOKEN
        if (!context.mounted) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        // Jika API gagal, tetap logout dari local storage
        await prefs.remove('access_token');
        if (!context.mounted) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } on SocketException catch (e) {
      print('SocketException in logout: ${e.message}');
      // Tetap logout dari local storage meski tidak ada koneksi
      await prefs.remove('access_token');
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } on HttpException catch (e) {
      print('HttpException in logout: ${e.message}');
      // Tetap logout dari local storage
      await prefs.remove('access_token');
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } on TimeoutException catch (e) {
      print('TimeoutException in logout: ${e.message}');
      // Tetap logout dari local storage
      await prefs.remove('access_token');
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      print('Error in logout: $e');
      // Tetap logout dari local storage
      await prefs.remove('access_token');
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.help_outline,
                  size: 48,
                  color: const Color(0xFF00A3FF).withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Apakah Anda yakin ingin keluar?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
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
                      logout(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Logout',
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

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}
