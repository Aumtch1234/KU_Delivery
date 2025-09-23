import 'package:flutter/material.dart';

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class Order {
  final int orderId;
  final int userId;
  final int marketId;
  final String shopName;
  final int? riderId;
  final String address;
  final String deliveryType;
  final String paymentMethod;
  final String? note;
  final double? distanceKm;
  final double deliveryFee;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;

  Order({
    required this.orderId,
    required this.userId,
    required this.marketId,
    required this.shopName,
    this.riderId,
    required this.address,
    required this.deliveryType,
    required this.paymentMethod,
    this.note,
    this.distanceKm,
    required this.deliveryFee,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'],
      userId: json['user_id'],
      marketId: json['market_id'],
      shopName: json['shop_name'],
      riderId: json['rider_id'],
      address: json['address'],
      deliveryType: json['delivery_type'],
      paymentMethod: json['payment_method'],
      note: json['note'],
      distanceKm: _toDouble(json['distance_km']),
      deliveryFee: _toDouble(json['delivery_fee']),
      totalPrice: _toDouble(json['total_price']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'user_id': userId,
      'market_id': marketId,
      'shop_name': shopName,
      'rider_id': riderId,
      'address': address,
      'delivery_type': deliveryType,
      'payment_method': paymentMethod,
      'note': note,
      'distance_km': distanceKm,
      'delivery_fee': deliveryFee,
      'total_price': totalPrice,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  // Helper methods for status checking
  bool get isPending => status == 'waiting';
  bool get isConfirmed => status == 'confirmed';
  bool get hasRider =>
      riderId != null ||
      status == 'rider_assigned' ||
      status == 'going_to_shop' ||
      status == 'arrived_at_shop' ||
      status == 'picked_up' ||
      status == 'delivering' ||
      status == 'arrived_at_customer';
  bool get isRiderAssigned => status == 'rider_assigned';
  bool get isGoingToShop => status == 'going_to_shop';
  bool get isArrivedAtShop => status == 'arrived_at_shop';
  bool get isPreparing => status == 'preparing';
  bool get isReadyForPickup => status == 'ready_for_pickup';
  bool get isPickedUp => status == 'picked_up';
  bool get isDelivering => status == 'delivering';
  bool get isArrivedAtCustomer => status == 'arrived_at_customer';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get statusText {
    switch (status) {
      case 'waiting':
        return 'ออเดอร์ใหม่ กำลังรอร้านยืนยัน';
      case 'confirmed':
        return 'ร้านยืนยันรับออเดอร์แล้ว';
      case 'rider_assigned':
        return 'มีไรเดอร์รับงานแล้ว';
      case 'going_to_shop':
        return 'ไรเดอร์กำลังไปที่ร้าน';
      case 'arrived_at_shop':
        return 'ไรเดอร์ถึงร้านแล้ว';
      case 'preparing':
        return 'ร้านกำลังเตรียมอาหาร';
      case 'ready_for_pickup':
        return 'พร้อมให้ไรเดอร์มารับ';
      case 'picked_up':
        return 'ไรเดอร์รับของแล้ว';
      case 'delivering':
        return 'ไรเดอร์กำลังส่งของ';
      case 'arrived_at_customer':
        return 'ไรเดอร์ถึงบ้านลูกค้าแล้ว';
      case 'completed':
        return 'ส่งสำเร็จ (ปิดงาน)';
      case 'cancelled':
        return 'ออเดอร์ถูกยกเลิก';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'waiting':
        return Colors.orange;
      case 'confirmed':
      case 'preparing':
        return Colors.blue;
      case 'rider_assigned':
      case 'going_to_shop':
        return Colors.purple;
      case 'arrived_at_shop':
      case 'ready_for_pickup':
        return Colors.indigo;
      case 'picked_up':
      case 'delivering':
        return Colors.teal;
      case 'arrived_at_customer':
        return Colors.green.shade700;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'waiting':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle;
      case 'rider_assigned':
        return Icons.motorcycle;
      case 'going_to_shop':
        return Icons.directions;
      case 'arrived_at_shop':
        return Icons.store;
      case 'preparing':
        return Icons.restaurant;
      case 'ready_for_pickup':
        return Icons.shopping_bag;
      case 'picked_up':
        return Icons.delivery_dining;
      case 'delivering':
        return Icons.local_shipping;
      case 'arrived_at_customer':
        return Icons.home;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // เพิ่ม copyWith method
  Order copyWith({
    int? orderId,
    int? userId,
    int? marketId,
    String? shopName,
    int? riderId,
    String? address,
    String? deliveryType,
    String? paymentMethod,
    String? note,
    double? distanceKm,
    double? deliveryFee,
    double? totalPrice,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      marketId: marketId ?? this.marketId,
      shopName: shopName ?? this.shopName,
      riderId: riderId ?? this.riderId,
      address: address ?? this.address,
      deliveryType: deliveryType ?? this.deliveryType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      distanceKm: distanceKm ?? this.distanceKm,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}

class OrderItem {
  final int itemId;
  final int? orderId;
  final int foodId;
  final String foodName;
  final int quantity;
  final double sellPrice;
  final double subtotal;
  final List<dynamic> selectedOptions;

  OrderItem({
    required this.itemId,
    required this.orderId,
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.sellPrice,
    required this.subtotal,
    required this.selectedOptions,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      itemId: json['item_id'],
      orderId: json['order_id'],
      foodId: json['food_id'],
      foodName: json['food_name'],
      quantity: json['quantity'],
      sellPrice: _toDouble(json['sell_price']),
      subtotal: _toDouble(json['subtotal']),
      selectedOptions: json['selected_options'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'order_id': orderId,
      'food_id': foodId,
      'food_name': foodName,
      'quantity': quantity,
      'sell_price': sellPrice,
      'subtotal': subtotal,
      'selected_options': selectedOptions,
    };
  }
}
