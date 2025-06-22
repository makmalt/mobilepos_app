import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobilepos_app/shared/components/bottom_bar.dart';
import 'package:mobilepos_app/features/auth/screens/login_page.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mobilepos_app/features/splash/screens/decider_page.dart';
import 'package:mobilepos_app/features/transaction/screens/transaksi.dart';
import 'package:provider/provider.dart';
import 'package:mobilepos_app/shared/providers/cart_provider.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initialization();
  }

  void initialization() async {
    await Future.delayed(const Duration(seconds: 2));
    FlutterNativeSplash.remove(); // Hapus splash setelah delay
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: MaterialApp(
        theme: ThemeData(
          textTheme: GoogleFonts.montserratTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        home: const DeciderPage(), // <- bukan initialRoute lagi
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => CustomBottomBar(
                arguments: ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?,
              ),
          '/transaction': (context) => const Transaksi(),
        },
      ),
    );
  }
}
