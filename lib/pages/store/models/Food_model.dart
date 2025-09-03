class Food {
  final int foodId;
  final String foodName;
  final double price;
  final String imageUrl;
  final double? foodRating;
  final int marketId;
  final String shopName;
  final String shopLogoUrl;
  final double latitude;
  final double longitude;
  final bool isOpen;
  final double? marketRating;
  final String address;
  final String phone;

  Food({
    required this.foodId,
    required this.foodName,
    required this.price,
    required this.imageUrl,
    this.foodRating,
    required this.marketId,
    required this.shopName,
    required this.shopLogoUrl,
    required this.latitude,
    required this.longitude,
    required this.isOpen,
    this.marketRating,
    required this.address,
    required this.phone,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      foodId: json['food_id'],
      foodName: json['food_name'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: json['image_url'] ?? '',
      foodRating: json['food_rating'] != null
          ? double.tryParse(json['food_rating'].toString())
          : null,
      marketId: json['market_id'],
      shopName: json['shop_name'] ?? '',
      shopLogoUrl: json['shop_logo_url'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isOpen: json['is_open'] ?? false,
      marketRating: json['market_rating'] != null
          ? double.tryParse(json['market_rating'].toString())
          : null,
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}
