import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:mobilepos_app/models/barang_transaksi.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class PrinterService {
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;
  BluetoothDevice? selectedPrinter;

  // List of known thermal printer names/keywords
  final List<String> thermalPrinterKeywords = [
    'eppos',
    'epson',
    'thermal',
    'printer',
    'pos',
    '58mm',
    '58 mm',
    'receipt',
    'bluetooth printer',
    'bt-printer',
    'bt printer',
    'bluetooth thermal',
    'thermal printer',
    'pos printer',
    'receipt printer',
    'label printer',
    'sticker printer',
    'ticket printer',
    'cashier printer',
    'kasir printer',
    'struk printer',
    'struk',
    'kasir',
    'cashier',
    'pos58',
    'pos-58',
    'pos 58',
    'eppos58',
    'eppos-58',
    'eppos 58',
    'rpp02n',
    'rpp-02n',
    'rpp 02n',
    'rpp02',
    'rpp-02',
    'rpp 02',
    'rpp'
  ];

  bool _isThermalPrinter(String? deviceName) {
    if (deviceName == null) return false;
    final lowerName = deviceName.toLowerCase();
    return thermalPrinterKeywords
        .any((keyword) => lowerName.contains(keyword.toLowerCase()));
  }

  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      // Check if Bluetooth is available
      bool? isAvailable = await printer.isAvailable;
      if (isAvailable != true) {
        print("Bluetooth is not available");
        return [];
      }

      // Check if Bluetooth is enabled
      bool? isOn = await printer.isOn;
      if (isOn != true) {
        print("Bluetooth is not enabled");
        return [];
      }

      // Get paired devices
      List<BluetoothDevice> allDevices = await printer.getBondedDevices();

      // Filter only thermal printers
      List<BluetoothDevice> thermalPrinters =
          allDevices.where((device) => _isThermalPrinter(device.name)).toList();

      print(
          "Found ${thermalPrinters.length} thermal printers out of ${allDevices.length} total devices");

      // Print device details for debugging
      for (var device in thermalPrinters) {
        print("Thermal Printer: ${device.name} - ${device.address}");
      }

      // Try to restore connection to saved printer
      await _restorePrinterConnection(thermalPrinters);

      return thermalPrinters;
    } catch (e) {
      print("Error getting paired devices: $e");
      return [];
    }
  }

  Future<void> _restorePrinterConnection(List<BluetoothDevice> devices) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPrinterName = prefs.getString('selected_printer');
      final savedPrinterAddress = prefs.getString('selected_printer_address');

      if (savedPrinterName != null && savedPrinterAddress != null) {
        // Find the saved printer in the list of available devices
        final savedDevice = devices.firstWhere(
          (device) =>
              device.name == savedPrinterName &&
              device.address == savedPrinterAddress,
          orElse: () => null as BluetoothDevice,
        );

        if (savedDevice != null) {
          print(
              "Attempting to restore connection to saved printer: ${savedDevice.name}");
          await connectToPrinter(savedDevice);
        }
      }
    } catch (e) {
      print("Error restoring printer connection: $e");
    }
  }

  Future<bool> connectToPrinter(BluetoothDevice device) async {
    try {
      // Check if already connected to this device
      if (selectedPrinter?.address == device.address) {
        bool? isConnected = await printer.isConnected;
        if (isConnected == true) {
          print("Already connected to this printer");
          return true;
        }
      }

      // Disconnect from current printer if any
      if (selectedPrinter != null) {
        try {
          await printer.disconnect();
          print("Disconnected from previous printer");
        } catch (e) {
          print("Error disconnecting from previous printer: $e");
        }
        selectedPrinter = null;
      }

      // Try to connect
      try {
        print("Attempting to connect to printer");
        bool connected = await printer.connect(device);

        // If we get "already connected" error, consider it a success
        if (connected) {
          print("Successfully connected to printer: ${device.name}");
          selectedPrinter = device;

          // Save printer connection info
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'selected_printer', device.name ?? 'Unknown Printer');
          await prefs.setString(
              'selected_printer_address', device.address ?? '');

          return true;
        }
      } catch (e) {
        // If we get "already connected" error, consider it a success
        if (e.toString().contains('already connected')) {
          print("Printer is already connected");
          selectedPrinter = device;

          // Save printer connection info
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'selected_printer', device.name ?? 'Unknown Printer');
          await prefs.setString(
              'selected_printer_address', device.address ?? '');

          return true;
        }
        print("Connection failed: $e");
      }

      return false;
    } catch (e) {
      print("Error connecting to printer: $e");
      return false;
    }
  }

  Future<bool> isPrinterConnected() async {
    try {
      if (selectedPrinter == null) {
        // Try to restore connection if we have saved printer info
        final prefs = await SharedPreferences.getInstance();
        final savedPrinterName = prefs.getString('selected_printer');
        final savedPrinterAddress = prefs.getString('selected_printer_address');

        if (savedPrinterName != null && savedPrinterAddress != null) {
          print("Found saved printer info, attempting to restore connection");
          List<BluetoothDevice> devices = await getPairedDevices();
          final savedDevice = devices.firstWhere(
            (device) =>
                device.name == savedPrinterName &&
                device.address == savedPrinterAddress,
            orElse: () => null as BluetoothDevice,
          );

          if (savedDevice != null) {
            await connectToPrinter(savedDevice);
          }
        }
      }

      bool? isConnected = await printer.isConnected;
      return isConnected ?? false;
    } catch (e) {
      print("Error checking printer connection: $e");
      return false;
    }
  }

  // Generate noTransaksi format: TRX-ddmmyyyy-UNIQUEID
  String generateNoTransaksi() {
    final now = DateTime.now();
    final dateStr = DateFormat('ddMMyyyy').format(now);
    final uniqueId = _generateUniqueId();
    return 'TRX-$dateStr-$uniqueId';
  }

  String _generateUniqueId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final uniqueId =
        List.generate(13, (index) => chars[random.nextInt(chars.length)])
            .join();
    return uniqueId;
  }

  Future<void> printReceipt({
    required List<BarangTransaksi> items,
    required double total,
    required double payment,
    required double change,
    required String noTransaksi,
  }) async {
    // Check if printer is connected
    bool isConnected = await isPrinterConnected();
    if (!isConnected) {
      throw Exception(
          "Printer not connected. Please connect to a printer first.");
    }

    try {
      // Print header with company name in normal size but bold
      printer.printCustom(
          "Karya Hutama Oxygen", 1, 1); // Size 1 for company name
      printer.printNewLine();

      // Print address and phone in normal size
      printer.printCustom("Jl. Diponegoro No.122", 1, 1);
      printer.printCustom("Mojosari, Mojokerto", 1, 1);
      printer.printCustom("(0321)593940", 1, 1);
      printer.printNewLine();

      // Print divider
      printer.printCustom("--------------------------------", 1, 1);

      // Print transaction info
      printer.printCustom("No: $noTransaksi", 1, 0);
      printer.printCustom(
          "Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
          1,
          0);
      printer.printNewLine();

      // Print divider
      printer.printCustom("--------------------------------", 1, 1);

      // Print items
      for (var item in items) {
        // Truncate item name if longer than 20 characters
        String itemName = item.namaBarang;
        if (itemName.length > 20) {
          itemName = itemName.substring(0, 20);
        }

        // Print item name in bold
        printer.printCustom(itemName, 1, 0);

        // Print item details with proper spacing
        String detail =
            "${item.quantity} x Rp${item.hargaBarang.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')} = Rp${item.totalHarga.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}";
        printer.printCustom(detail, 1, 0);
        printer.printNewLine();
      }

      // Add spacing if items less than 3
      if (items.length < 3) {
        for (int i = 0; i < (3 - items.length); i++) {
          printer.printNewLine();
        }
      }

      // Print divider
      printer.printCustom("--------------------------------", 1, 1);

      // Print totals with proper alignment
      String totalStr = "Total:";
      String totalValue =
          "Rp${total.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}";
      printer.printCustom(
          "$totalStr${' ' * (32 - totalStr.length - totalValue.length)}$totalValue",
          1,
          0);

      String bayarStr = "Bayar:";
      String bayarValue =
          "Rp${payment.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}";
      printer.printCustom(
          "$bayarStr${' ' * (32 - bayarStr.length - bayarValue.length)}$bayarValue",
          1,
          0);

      String kembaliStr = "Kembali:";
      String kembaliValue =
          "Rp${change.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}";
      printer.printCustom(
          "$kembaliStr${' ' * (32 - kembaliStr.length - kembaliValue.length)}$kembaliValue",
          1,
          0);

      printer.printNewLine();

      // Print divider
      printer.printCustom("--------------------------------", 1, 1);

      // Print footer
      printer.printCustom("Terima Kasih", 1, 1);
      printer.printCustom("Atas Kunjungan Anda", 1, 1);

      // Add extra spacing at the end
      printer.printNewLine();
      printer.printNewLine();

      // Cut paper
      printer.paperCut();
    } catch (e) {
      print("Error printing receipt: $e");
      throw Exception("Failed to print receipt: $e");
    }
  }
}
