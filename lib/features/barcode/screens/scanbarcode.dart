import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobilepos_app/shared/components/app_bar.dart';
import 'package:mobilepos_app/features/home/screens/detailpage.dart';

class Scanbarcode extends StatefulWidget {
  const Scanbarcode({super.key});

  @override
  State<Scanbarcode> createState() => ScanbarcodeState();
}

class ScanbarcodeState extends State<Scanbarcode> {
  final MobileScannerController scannerController = MobileScannerController();
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    scannerController.start(); // Mulai scanner otomatis
  }

  @override
  void dispose() {
    scannerController.dispose(); // Matikan scanner pas keluar halaman
    super.dispose();
  }

  void processBarcode(String code) {
    if (!isProcessing) {
      setState(() {
        isProcessing = true;
      });
      scannerController.stop();
      debugPrint('Barcode ditemukan: $code');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailPage(barcode: code),
        ),
      ).then((_) {
        setState(() {
          isProcessing = false;
        });
          scannerController.start();
        });
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppbar(title: 'Scan'),
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 300, // Atur tinggi biar kelihatan
              child: MobileScanner(
                controller: scannerController,
                onDetect: (capture) {
                  if (capture.barcodes.isEmpty) {
                    debugPrint('Failed to scan Barcode');
                  } else {
                    final String code = capture.barcodes.first.rawValue!;
                    processBarcode(code);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.flash_on),
                    onPressed: () {
                      scannerController.toggleTorch();
                    },
                    iconSize: 20,
                  ),
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios),
                    onPressed: () {
                      scannerController.switchCamera();
                    },
                    iconSize: 20,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
