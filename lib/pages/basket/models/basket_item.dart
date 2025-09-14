class BasketItem {
  final int cartId; // ✅ เพิ่ม
  final String storeName;
  final int foodId;
  final String foodName;
  final String imagePath;
  final int marketId;
  final List<Map<String, dynamic>> selectedOptions;
  final String note;
  final double sell_price; // ราคาขาย
  double total;   // ราคารวม (จาก backend)
  int quantity;
  bool selected;

  BasketItem({
    required this.cartId,
    required this.storeName,
    required this.foodId,
    required this.foodName,
    this.imagePath = '',
    this.marketId = 0,
    this.selectedOptions = const [],
    this.note = '',
    required this.sell_price,
    required this.total,
    required this.quantity,
    this.selected = true,
  });

  /// ตัวเลือกเริ่มต้น (อันแรกใน list)
  String get defaultOptionLabel =>
      selectedOptions.isNotEmpty ? selectedOptions[0]['label'] : '';

  /// ✅ รวม option ทั้งหมดเป็นข้อความอ่านง่าย
  String get optionsText {
    if (selectedOptions.isEmpty) return "ไม่มีตัวเลือก";
    return selectedOptions.map((opt) {
      final label = opt['label'] ?? '';
      final extra = (opt['extraPrice'] ?? 0) > 0 ? " (+${opt['extraPrice']}฿)" : "";
      return "$label$extra";
    }).join(", ");
  }

  factory BasketItem.fromJson(Map<String, dynamic> json) {
    return BasketItem(
      cartId: json['cart_id'] ?? 0, // ✅ เพิ่ม
      storeName: json['shop_name'] ?? 'ร้านค้าไม่ระบุ',
      foodId: json['food_id'] != null ? int.tryParse(json['food_id'].toString()) ?? 0 : 0,
      foodName: json['food_name'] ?? 'ไม่ระบุ',
      imagePath: json['image_url'] ?? '',
      marketId: json['market_id'] != null ? int.tryParse(json['market_id'].toString()) ?? 0 : 0,
      selectedOptions: List<Map<String, dynamic>>.from(
          json['selected_options'] ?? []),
      note: json['note'] ?? '',
      sell_price: double.tryParse(json['sell_price'].toString()) ?? 0,
      total: double.tryParse(json['total'].toString()) ?? 0,
      quantity: json['quantity'] ?? 1,
    );
  }
}
