class DeliveryAddress {
  final int? id; // id อาจจะเป็น null เมื่อสร้างใหม่
  final String name;
  final String phone;
  final String address;
  final String district;
  final String city;
  final String postalCode;
  final String notes;
  final double latitude;
  final double longitude;

  DeliveryAddress({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.district,
    required this.city,
    required this.postalCode,
    this.notes = '',
    required this.latitude,
    required this.longitude,
  });

  // แปลงเป็น JSON สำหรับส่ง API
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "phone": phone,
      "address": address,
      "district": district,
      "city": city,
      "postalCode": postalCode,
      "notes": notes,
      "latitude": latitude,
      "longitude": longitude,
    };
  }

  // Factory สำหรับรับจาก API (ถ้ามี response กลับมา)
  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json["id"],
      name: json["name"],
      phone: json["phone"],
      address: json["address"],
      district: json["district"],
      city: json["city"],
      postalCode: json["postalCode"],
      notes: json["notes"] ?? '',
      latitude: (json["latitude"] as num).toDouble(),
      longitude: (json["longitude"] as num).toDouble(),
    );
  }
}
