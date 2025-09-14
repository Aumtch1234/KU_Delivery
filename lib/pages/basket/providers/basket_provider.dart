import 'package:delivery/APIs/Carts/Carts.dart';
import 'package:flutter/material.dart';
import '../models/basket_item.dart';

class BasketProvider extends ChangeNotifier {
  final List<BasketItem> _items = [];
  int cartCount = 0; 
  bool isEditMode = false;

  List<BasketItem> get items => _items;

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void addItem(BasketItem item) {
    final index = _items.indexWhere(
      (e) =>
          e.foodName == item.foodName &&
          e.storeName == item.storeName &&
          e.note == item.note,
    );

    final extra = item.selectedOptions.fold<double>(
      0,
      (sum, opt) => sum + (opt['extraPrice'] ?? 0),
    );

    item.total = (item.sell_price + extra) * item.quantity;

    print('🛒 ADD ITEM: ${item.foodName}');
    print(
      '   >> sellPrice=${item.sell_price}, extra=$extra, qty=${item.quantity}, total=${item.total}',
    );

    if (index != -1) {
      _items[index].quantity += item.quantity;
      final existingExtra = _items[index].selectedOptions.fold<double>(
        0,
        (sum, opt) => sum + (opt['extraPrice'] ?? 0),
      );

      _items[index].total =
          (_items[index].sell_price + existingExtra) * _items[index].quantity;

      print('   >> UPDATED ITEM: ${_items[index].foodName}');
      print(
        '      sellPrice=${_items[index].sell_price}, total=${_items[index].total}',
      );
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  Future<void> removeSelected() async {
    final selectedItems = _items.where((e) => e.selected).toList();

    for (var item in selectedItems) {
      try {
        final success = await CartAPI.deleteCartItem(item.cartId);
        if (!success) {
          print('❌ Failed to delete cart item: ${item.cartId}');
        }
      } catch (e) {
        print('❌ RemoveCart error: $e');
      }
    }

    _items.removeWhere((e) => e.selected);
    notifyListeners();
  }

  void toggleSelectAll(bool value) {
    for (var e in _items) e.selected = value;
    notifyListeners();
  }

  void toggleEditMode() {
    isEditMode = !isEditMode;
    notifyListeners();
  }

  void toggleItemSelected(int index, bool value) {
    _items[index].selected = value;
    notifyListeners();
  }

  // 🆕 เพิ่มฟังก์ชันเลือกร้านทั้งหมด
  void toggleStoreSelected(String storeName, bool value) {
    for (var item in _items) {
      if (item.storeName == storeName) {
        item.selected = value;
      }
    }
    notifyListeners();
  }

  // 🆕 ตรวจสอบว่าร้านนี้เลือกทั้งหมดหรือไม่
  bool isStoreFullySelected(String storeName) {
    final storeItems = _items.where((e) => e.storeName == storeName).toList();
    if (storeItems.isEmpty) return false;
    return storeItems.every((e) => e.selected);
  }

  // 🆕 ตรวจสอบว่าร้านนี้เลือกบางส่วนหรือไม่
  bool isStorePartiallySelected(String storeName) {
    final storeItems = _items.where((e) => e.storeName == storeName).toList();
    if (storeItems.isEmpty) return false;
    return storeItems.any((e) => e.selected) && !storeItems.every((e) => e.selected);
  }

  // 🆕 จำแนกสินค้าตามร้าน
  Map<String, List<BasketItem>> get itemsByStore {
    Map<String, List<BasketItem>> storeMap = {};
    for (var item in _items) {
      if (storeMap[item.storeName] == null) {
        storeMap[item.storeName] = [];
      }
      storeMap[item.storeName]!.add(item);
    }
    return storeMap;
  }

  // 🆕 รายชื่อร้าน
  List<String> get storeNames {
    return _items.map((e) => e.storeName).toSet().toList();
  }

  void updateQuantity(int index, int newQuantity) {
    if (newQuantity < 1) return;

    final item = _items[index];
    item.quantity = newQuantity;

    final extra = item.selectedOptions.fold<double>(
      0,
      (sum, opt) => sum + (opt['extraPrice'] ?? 0),
    );

    item.total = (item.sell_price + extra) * newQuantity;

    print('🔄 UPDATE QTY: ${item.foodName}');
    print(
      '   >> sellPrice=${item.sell_price}, extra=$extra, qty=${item.quantity}, total=${item.total}',
    );

    notifyListeners();
  }

  double get totalSelectedPrice =>
      _items.where((e) => e.selected).fold(0, (sum, e) => sum + e.total);

  int get selectedCount =>
      _items.where((e) => e.selected).fold(0, (sum, e) => sum + e.quantity);

  bool get allSelected => _items.isNotEmpty && _items.every((e) => e.selected);

  /// 🔄 โหลดข้อมูลจาก API /cart
  Future<void> loadCartFromAPI() async {
    try {
      final cartItems = await CartAPI.getCart();
      _items.clear();

      for (var item in cartItems) {
        final extra = item.selectedOptions.fold<double>(
          0,
          (sum, opt) => sum + (opt['extraPrice'] ?? 0),
        );

        item.total = (item.sell_price + extra) * item.quantity;

        _items.add(item);

        print('🛒 LOAD ITEM: ${item.foodName}');
        print(
          '   >> sellPrice=${item.sell_price}, extra=$extra, qty=${item.quantity}, total=${item.total}',
        );
      }

      notifyListeners();
    } catch (e) {
      print('Error loading cart: $e');
    }
  }
}