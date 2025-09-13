
class ShippingAddress {
  String id;
  String name;
  String phone;
  String address;
  String district;
  String province;
  String postalCode;
  bool isDefault;

  ShippingAddress({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.district,
    required this.province,
    required this.postalCode,
    required this.isDefault,
  });
}