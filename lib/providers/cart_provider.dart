import 'package:flutter/material.dart';
import 'package:mobilepos_app/models/items.dart';
import 'package:mobilepos_app/models/barang_transaksi.dart';

class CartProvider extends ChangeNotifier {
  List<Item> _cartItems = [];

  List<Item> get cartItems => _cartItems;

  void addToCart(Item item) {
    _cartItems.add(item);
    notifyListeners();
  }

  void removeFromCart(Item item) {
    _cartItems.remove(item);
    notifyListeners();
  }

  void removeAllItemsWithId(int itemId) {
    _cartItems.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  List<BarangTransaksi> getTransactionItems() {
    Map<int, BarangTransaksi> itemMap = {};

    for (var item in _cartItems) {
      if (itemMap.containsKey(item.id)) {
        itemMap[item.id]!.quantity++;
        itemMap[item.id]!.totalHarga = itemMap[item.id]!.quantity * item.harga;
      } else {
        itemMap[item.id] = BarangTransaksi.fromItem(item, 1);
      }
    }

    return itemMap.values.toList();
  }
}
