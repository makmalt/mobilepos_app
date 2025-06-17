import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:mobilepos_app/services/printer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({Key? key}) : super(key: key);

  @override
  _PrinterSettingsScreenState createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrinterService _printerService = PrinterService();
  List<BluetoothDevice> _devices = [];
  bool _isLoading = true;
  String? _selectedPrinterName;
  bool _isScanning = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _loadPairedDevices();
    _loadSelectedPrinter();
  }

  Future<void> _loadSelectedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPrinterName = prefs.getString('selected_printer');
    });
  }

  Future<void> _loadPairedDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final devices = await _printerService.getPairedDevices();
      print("Found ${devices.length} paired devices"); // Debug print
      for (var device in devices) {
        print("Device: ${device.name} - ${device.address}"); // Debug print
      }
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      print("Error in _loadPairedDevices: $e"); // Debug print
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading devices: $e')),
      );
    }
  }

  Future<void> _connectToPrinter(BluetoothDevice device) async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      final success = await _printerService.connectToPrinter(device);
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'selected_printer', device.name ?? 'Unknown Printer');
        setState(() {
          _selectedPrinterName = device.name;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${device.name}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to printer')),
        );
      }
    } catch (e) {
      print("Error in _connectToPrinter: $e"); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to printer: $e')),
      );
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Settings'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
            onPressed: _isConnecting
                ? null
                : () {
                    setState(() {
                      _isScanning = !_isScanning;
                    });
                    _loadPairedDevices();
                  },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No paired devices found'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isConnecting ? null : _loadPairedDevices,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPairedDevices,
                  child: ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isSelected = device.name == _selectedPrinterName;

                      return ListTile(
                        leading: Icon(
                          Icons.print,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        title: Text(device.name ?? 'Unknown Printer'),
                        subtitle: Text(device.address ?? 'Unknown Address'),
                        trailing: _isConnecting && isSelected
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : isSelected
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : const Icon(Icons.radio_button_unchecked),
                        onTap: _isConnecting
                            ? null
                            : () => _connectToPrinter(device),
                      );
                    },
                  ),
                ),
    );
  }
}
