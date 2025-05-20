import 'package:flutter/material.dart';
import 'package:mobilepos_app/app_config.dart';
import 'package:mobilepos_app/component/app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetailPage extends StatefulWidget {
  final int? id;
  final String? barcode;

  const DetailPage({super.key, this.id, this.barcode});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Map<String, dynamic>? item;
  bool isLoading = true;

  String baseUrl = AppConfig.baseUrl;

  Future<void> fetchDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    String apiUrl;

    //handle detail page from home or scan
    if (widget.barcode != null) {
      apiUrl =
          "$baseUrl/api/barang/barcode/${widget.barcode}"; // Menggunakan barcode
    } else if (widget.id != null) {
      apiUrl = "$baseUrl/api/barang/show/${widget.id}"; // Menggunakan ID
    } else {
      throw Exception("ID atau Barcode diperlukan.");
    }

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          item = data;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load item details");
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching item details: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppbar(title: ("Detail")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : item == null
              ? const Center(child: Text("Data not found"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: SizedBox(
                        width: 250,
                        height: 500,
                        child: Card(
                            color: Colors.white70,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Gambar
                                  Container(
                                    height: 200,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                            '$baseUrl/storage/${item!['image']}'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  // Nama barang
                                  Text(
                                    item!['nama_barang'],
                                    style: const TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  // Harga barang
                                  Text(
                                    "Rp. ${item!['harga']}",
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  // Deskripsi
                                  Text(
                                    item!['deskripsi'] ??
                                        "Deskripsi tidak tersedia",
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                  const SizedBox(height: 8.0),
                                  // Stok barang
                                  Text(
                                    "Stok: ${item!['stok_tersedia']}",
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                  const SizedBox(height: 8.0),
                                  // Stok barang
                                  Text(
                                    "Kategori: ${item!['kategori']['nama_kategori']}",
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                ],
                              ),
                            ))),
                  )),
    );
  }
}
