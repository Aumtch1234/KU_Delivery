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
  final String customerName; // ชื่อลูกค้า
  final String customerPhone; // เบอร์โทรลูกค้า
  final String address;
  final String deliveryType;
  final String paymentMethod;
  final String? note; // โน้ต บอกไรเดอร์
  final double? distanceKm;
  final double deliveryFee;
  final double totalPrice;
  final double? originalTotalPrice; // ราคาต้นทุนรวม (ไม่รวมค่าส่ง)
  final String status;
  final String? shopStatus; // ✅ เพิ่ม
  final String? riderStatus; // ✅ เพิ่มเพื่อเก็บสถานะไรเดอร์ปัจจุบัน
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;

  Order({
    required this.orderId,
    required this.userId,
    required this.marketId,
    required this.shopName,
    this.riderId,
    required this.customerName, // ชื่อลูกค้าจาก API
    required this.customerPhone, // เบอร์โทรลูกค้า
    required this.address,
    required this.deliveryType,
    required this.paymentMethod,
    this.note,
    this.distanceKm,
    required this.deliveryFee,
    required this.totalPrice,
    this.originalTotalPrice,
    required this.status,
    this.shopStatus, // ✅ เพิ่ม
    this.riderStatus, // ✅ เพิ่มพารามิเตอร์ใหม่
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final String? shopStatus =
        json['shop_status'] ??
        (json['status'] == 'preparing' || json['status'] == 'ready_for_pickup'
            ? json['status']
            : null);

    // กำหนด riderStatus ตาม status ปัจจุบันหรือข้อมูลจาก API
    String? riderStatus;
    final String currentStatus = json['status'];
    if (currentStatus == 'going_to_shop' ||
        currentStatus == 'arrived_at_shop' ||
        currentStatus == 'picked_up' ||
        currentStatus == 'delivering') {
      riderStatus = currentStatus;
    } else if (json['rider_status'] != null) {
      riderStatus = json['rider_status'];
    }

    return Order(
      orderId: json['order_id'],
      userId: json['user_id'],
      marketId: json['market_id'],
      shopName: json['shop_name'],
      riderId: json['rider_id'],
      customerName:
          json['customer_name'] ??
          json['name'] ??
          'ไม่ระบุ', // กำหนดค่าเริ่มต้น
      customerPhone:
          json['customer_phone'] ??
          json['phone'] ??
          'ไม่ระบุ', // กำหนดค่าเริ่มต้น
      address: json['address'],
      deliveryType: json['delivery_type'],
      paymentMethod: json['payment_method'],
      note: json['note'],
      distanceKm: _toDouble(json['distance_km']),
      deliveryFee: _toDouble(json['delivery_fee']),
      totalPrice: _toDouble(json['total_price']),
      originalTotalPrice: _toDouble(json['original_total_price']),
      status: json['status'],
      shopStatus: shopStatus, // ✅ เพิ่ม
      riderStatus: riderStatus, // ✅ เพิ่ม
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
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'address': address,
      'delivery_type': deliveryType,
      'payment_method': paymentMethod,
      'note': note,
      'distance_km': distanceKm,
      'delivery_fee': deliveryFee,
      'total_price': totalPrice,
      'status': status,
      'shop_status': shopStatus, // ✅
      'rider_status': riderStatus, // ✅ เพิ่ม
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
    // เช็ค shop_status ก่อน (มีความสำคัญสูง)
    if (shopStatus != null) {
      switch (shopStatus) {
        case 'preparing':
          return 'ร้านกำลังเตรียมอาหาร';
        case 'ready_for_pickup':
          return 'พร้อมให้ไรเดอร์มารับ';
      }
    }

    // ถ้าไม่มี shop_status หรือไม่ตรงกับที่เช็ค ให้ใช้ status
    switch (status) {
      case 'waiting':
        return 'ออเดอร์ใหม่ รอไรเดอร์รับงาน';
      case 'rider_assigned':
        return 'มีไรเดอร์รับงานแล้ว รอร้านยืนยัน';
      case 'confirmed':
        return 'ร้านยืนยันรับออเดอร์แล้ว';
      case 'going_to_shop':
        return 'ไรเดอร์กำลังไปที่ร้าน';
      case 'arrived_at_shop':
        return 'ไรเดอร์ถึงร้านแล้ว';
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
    // เช็ค shop_status ก่อน (มีความสำคัญสูง)
    if (shopStatus != null) {
      switch (shopStatus) {
        case 'preparing':
          return Icons.restaurant;
        case 'ready_for_pickup':
          return Icons.shopping_bag;
      }
    }

    // ถ้าไม่มี shop_status หรือไม่ตรงกับที่เช็ค ให้ใช้ status
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
    String? customerName,
    String? customerPhone,
    String? address,
    String? deliveryType,
    String? paymentMethod,
    String? note,
    double? distanceKm,
    double? deliveryFee,
    double? totalPrice,
    double? originalTotalPrice,
    String? status,
    String? shopStatus, // ✅ เพิ่ม
    String? riderStatus, // ✅ เพิ่ม
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
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      address: address ?? this.address,
      deliveryType: deliveryType ?? this.deliveryType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      distanceKm: distanceKm ?? this.distanceKm,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      totalPrice: totalPrice ?? this.totalPrice,
      originalTotalPrice: originalTotalPrice ?? this.originalTotalPrice,
      status: status ?? this.status,
      shopStatus: shopStatus ?? this.shopStatus, // ✅
      riderStatus: riderStatus ?? this.riderStatus, // ✅ เพิ่ม
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
  final double? originalPrice; // ราคาต้นทุนต่อชิ้น
  final String additionalDetailsNote; // รายละเอียดเพิ่มเติมของแต่ละเมนูที่สั่ง เช่น ไม่เอาผัก, เอาน้ำแข็งเยอะๆ
  final double? originalSubtotal; // ราคาต้นทุนรวม
  final List<dynamic> selectedOptions;
  final List<dynamic>? originalOptions; // ตัวเลือกต้นทุน

  OrderItem({
    required this.itemId,
    required this.orderId,
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.sellPrice,
    required this.subtotal,
    this.originalPrice,
    required this.additionalDetailsNote,
    this.originalSubtotal,
    required this.selectedOptions,
    this.originalOptions,
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
      originalPrice: _toDouble(json['original_price']),
      additionalDetailsNote: json['additional_notes'] ?? '',
      originalSubtotal: _toDouble(json['original_subtotal']),
      selectedOptions: json['selected_options'] ?? [],
      originalOptions: json['original_options'] ?? [],
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
      'original_price': originalPrice,
      'additional_notes': additionalDetailsNote,
      'original_subtotal': originalSubtotal,
      'selected_options': selectedOptions,
      'original_options': originalOptions,
    };
  }
}
