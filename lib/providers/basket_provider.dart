import 'package:flutter/material.dart';
import '../models/basket_item.dart';

class BasketProvider extends ChangeNotifier {
  void clear() {
    _items.clear();
    notifyListeners();
  }

  final List<BasketItem> _items = [];
  bool isEditMode = false;

  List<BasketItem> get items => _items;

  void addItem(BasketItem item) {
    // If same food (by name, store, spicy, note), increase quantity
    final index = _items.indexWhere(
      (e) =>
          e.foodName == item.foodName &&
          e.storeName == item.storeName &&
          e.spicyLevel == item.spicyLevel &&
          e.note == item.note,
    );
    if (index != -1) {
      _items[index].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeSelected() {
    _items.removeWhere((e) => e.selected);
    notifyListeners();
  }

  void toggleSelectAll(bool value) {
    for (var e in _items) {
      e.selected = value;
    }
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

  void updateQuantity(int index, int value) {
    _items[index].quantity = value;
    notifyListeners();
  }

  double get totalSelectedPrice => _items
      .where((e) => e.selected)
      .fold(0, (sum, e) => sum + e.price * e.quantity);

  int get selectedCount =>
      _items.where((e) => e.selected).fold(0, (sum, e) => sum + e.quantity);

  bool get allSelected => _items.isNotEmpty && _items.every((e) => e.selected);
}
