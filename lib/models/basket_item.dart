class BasketItem {
  final String storeName;
  final String foodName;
  final String imagePath;
  final String spicyLevel;
  final String note;
  final double price;
  int quantity;
  bool selected;

  BasketItem({
    required this.storeName,
    required this.foodName,
    required this.imagePath,
    required this.spicyLevel,
    required this.note,
    required this.price,
    required this.quantity,
    this.selected = true,
  });
}
