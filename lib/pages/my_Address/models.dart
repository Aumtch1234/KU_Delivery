class ShippingAddress {
  int id;
  String name;
  String phone;
  String address;
  String district;
  String province;
  String postalCode;
  bool isDefault;
  String? notes;        // เพิ่ม
  double? latitude;     // เพิ่ม
  double? longitude;    // เพิ่ม

  ShippingAddress({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.district,
    required this.province,
    required this.postalCode,
    required this.isDefault,
    this.notes,
    this.latitude,
    this.longitude,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      district: json['district'] ?? '',
      province: json['city'] ?? '',
      postalCode: json['postal_code'] ?? '',
      isDefault: json['is_default'] ?? false,
      notes: json['notes'],                 // เพิ่ม
      latitude: json['latitude']?.toDouble(),   // เพิ่ม
      longitude: json['longitude']?.toDouble(), // เพิ่ม
    );
  }
}
