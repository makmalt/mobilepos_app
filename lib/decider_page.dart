import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeciderPage extends StatefulWidget {
  const DeciderPage({super.key});

  @override
  State<DeciderPage> createState() => _DeciderPageState();
}

class _DeciderPageState extends State<DeciderPage> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
