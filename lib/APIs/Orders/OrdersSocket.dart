// controllers/order_controller.dart - Fixed for shop view
import 'dart:convert';
import 'package:delivery/APIs/SOCKET_IO/SocketService.dart';
import 'package:delivery/APIs/api_config.dart';
import 'package:delivery/pages/order/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OrderController extends ChangeNotifier {
  final SocketService _socketService = SocketService();
  final String baseUrl = '${ApiConfig.SocketUrl}';

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  Order? _currentOrder;

  // Getters
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Order? get currentOrder => _currentOrder;
  bool get isSocketConnected => _socketService.isConnected;

  // Initialize socket connection
  Future<void> initializeSocket() async {
    try {
      await _socketService.connect();
      _setupSocketListeners();
    } catch (e) {
      _error = 'Failed to connect to socket: $e';
      notifyListeners();
    }
  }

  // Setup socket event listeners
  // ใน order_controller.dart
  void _setupSocketListeners() {
    _socketService.on('order:updated', (data) async {
      print('📦 Order updated: $data');

      // Update state
      _handleOrderUpdate(data);

      // 🔄 ถ้ามี userId ให้ reload order list อัตโนมัติ
      if (_currentOrder?.userId != null) {
        await fetchOrdersByCustomer(userId: _currentOrder!.userId);
      }

      notifyListeners();
    });

    _socketService.on('customer:newOrder', (data) {
      print('🔔 New order for customer: $data');
      _handleNewOrderNotification(data);
    });

    _socketService.on('order_status_update', (data) {
      print('📊 Order status update: $data');
      _handleOrderUpdate(data);
    });

    _socketService.on('error', (error) {
      print('🚫 Socket error: $error');
      _error = 'Socket error: ${error.toString()}';
      notifyListeners();
    });
  }

  // Handle order update from socket
  void _handleOrderUpdate(dynamic data) {
    if (data == null) return;

    final orderId = data['order_id'];
    if (orderId == null) return;

    // Update current order if it matches
    if (_currentOrder?.orderId == orderId) {
      _currentOrder = _currentOrder?.copyWith(
        status: data['status'] ?? _currentOrder!.status,
        riderId: data['rider_id'] ?? _currentOrder!.riderId,
        updatedAt: data['timestamp'] != null
            ? DateTime.parse(data['timestamp'])
            : _currentOrder!.updatedAt,
      );
    }

    // Update order in list
    final index = _orders.indexWhere((order) => order.orderId == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: data['status'] ?? _orders[index].status,
        riderId: data['rider_id'] ?? _orders[index].riderId,
        updatedAt: data['timestamp'] != null
            ? DateTime.parse(data['timestamp'])
            : _orders[index].updatedAt,
      );
    }

    notifyListeners();
  }

  // Handle new order notification
  void _handleNewOrderNotification(dynamic data) {
    // Refresh orders list when new order comes in
    fetchOrders();
  }

  // Watch specific order
  void watchOrder(int orderId) {
    _socketService.watchOrder(orderId);
  }

  // Stop watching order
  void stopWatchingOrder() {
    _socketService.off('order:updated');
  }

  // Fetch orders from API - Updated to use the correct endpoint
  Future<void> fetchOrders({int? userId, String? status}) async {
    _setLoading(true);
    _error = null;

    try {
      String url = '$baseUrl/orders';
      List<String> queryParams = [];

      if (userId != null) {
        queryParams.add('user_id=$userId');
      }
      if (status != null) {
        queryParams.add('status=$status');
      }

      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.join('&');
      }

      print('🔍 Fetching orders from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      print("📦 Order JSON: ${jsonEncode(json)}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> ordersData = data['data'] ?? [];
          _orders = ordersData
              .map((orderJson) => Order.fromJson(orderJson))
              .toList();
          print('✅ Successfully loaded ${_orders.length} orders');
        } else {
          _error = data['error'] ?? 'Failed to fetch orders';
          print('❌ API Error: $_error');
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode}';
        print('❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('❌ Network error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Fetch orders specifically for shop/market
  Future<void> fetchOrdersByMarket({required int marketId}) async {
    _setLoading(true);
    _error = null;

    try {
      String url = '$baseUrl/orders?market_id=$marketId';

      print('🏪 Fetching orders for market $marketId from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Response status: ${response.statusCode}');
      // ตัด body ที่ยาวมาก ๆ ให้โชว์แค่ส่วนต้น
      print(
        '📦 Response body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> ordersData = data['data'] ?? [];

          print('📦 Raw orders count from API: ${ordersData.length}');
          for (var i = 0; i < ordersData.length; i++) {
            print('➡️ Order $i JSON: ${ordersData[i]}');
          }

          // แปลงเป็น Order objects
          final parsedOrders = ordersData
              .map((orderJson) {
                try {
                  return Order.fromJson(orderJson);
                } catch (e) {
                  print('❌ Error parsing order: $e');
                  print('📄 Failed Order JSON: $orderJson');
                  return null;
                }
              })
              .where((o) => o != null)
              .cast<Order>()
              .toList();

          // --- MERGE LOGIC ---
          final Map<int, Order> merged = {
            for (var o in _orders) o.orderId: o, // เก็บ state เดิม
          };

          for (var o in parsedOrders) {
            merged[o.orderId] = o; // อัปเดตถ้ามีอยู่แล้ว / insert ถ้าใหม่
          }

          _orders = merged.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // เรียงใหม่

          print('✅ After merging, orders in state: ${_orders.length}');
          for (var o in _orders) {
            print(
              '   ↳ OrderID: ${o.orderId}, status: ${o.status}, createdAt: ${o.createdAt}',
            );
          }

          // Group orders by status
          final statusGroups = <String, int>{};
          for (var order in _orders) {
            statusGroups[order.status] = (statusGroups[order.status] ?? 0) + 1;
          }
          print('📊 Orders by status: $statusGroups');
        } else {
          _error = data['error'] ?? 'Failed to fetch orders';
          print('❌ API Error: $_error');
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode} - ${response.body}';
        print('❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('❌ Network error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get specific order
  Future<void> fetchOrderById(int orderId) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order_status/$orderId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        double _toDouble(dynamic value) {
          if (value == null) return 0.0;
          if (value is double) return value;
          if (value is int) return value.toDouble();
          if (value is String) return double.tryParse(value) ?? 0.0;
          return 0.0;
        }

        if (data['success'] == true) {
          // Create order object from status data
          _currentOrder = Order(
            orderId: data['data']['order_id'],
            userId: 0, // Will be filled from full order data
            marketId: data['data']['market_id'] ?? 0,
            shopName: data['data']['shop_name'],
            riderId: data['data']['rider_id'],
            address: data['data']['address'] ?? '',
            deliveryType: data['data']['delivery_type'] ?? '',
            paymentMethod: data['data']['payment_method'] ?? '',
            deliveryFee: _toDouble(data['data']['delivery_fee']),
            totalPrice: _toDouble(data['data']['total_price']),

            status: data['data']['status'],
            createdAt: DateTime.parse(data['data']['timestamps']['created_at']),
            updatedAt: data['data']['timestamps']['updated_at'] != null
                ? DateTime.parse(data['data']['timestamps']['updated_at'])
                : DateTime.now(),
            items: [],
          );
        } else {
          _error = data['error'] ?? 'Failed to fetch order';
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Accept order (for shop) - Updated to match backend API
  Future<bool> acceptOrder(int orderId, int marketId) async {
    try {
      print('🏪 Accepting order $orderId for market $marketId');

      final response = await http.post(
        Uri.parse('$baseUrl/accept_order'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': orderId, 'market_id': marketId}),
      );

      print('📡 Accept order response: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        // Update local order status immediately for better UX
        final orderIndex = _orders.indexWhere(
          (order) => order.orderId == orderId,
        );
        if (orderIndex != -1) {
          _orders[orderIndex] = _orders[orderIndex].copyWith(
            status: 'accepted',
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }

        print('✅ Order $orderId accepted successfully');
        return true;
      } else {
        _error = data['error'] ?? 'Failed to accept order';
        print('❌ Failed to accept order: $_error');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('❌ Network error: $e');
      notifyListeners();
      return false;
    }
  }

  // Assign rider to order
  Future<bool> assignRider(int orderId, int riderId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/assign_rider'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': orderId, 'rider_id': riderId}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return true;
      } else {
        _error = data['error'] ?? 'Failed to assign rider';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return false;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(
    int orderId,
    String status, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('🔄 Updating order $orderId status to $status');

      final response = await http.put(
        Uri.parse('$baseUrl/update_order_status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': orderId,
          'status': status,
          'additional_data': additionalData,
        }),
      );

      print('📡 Update status response: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        // Update local order status immediately for better UX
        final orderIndex = _orders.indexWhere(
          (order) => order.orderId == orderId,
        );
        if (orderIndex != -1) {
          _orders[orderIndex] = _orders[orderIndex].copyWith(
            status: status,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }

        print('✅ Order $orderId status updated to $status');
        return true;
      } else {
        _error = data['error'] ?? 'Failed to update order status';
        print('❌ Failed to update order status: $_error');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('❌ Network error: $e');
      notifyListeners();
      return false;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(int orderId, String reason) async {
    try {
      print("🚀 เริ่มยกเลิกออเดอร์ ID: $orderId ด้วยเหตุผล: $reason");

      final response = await http.post(
        Uri.parse('$baseUrl/orders/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': orderId, 'reason': reason}),
      );

      print("📡 Response status: ${response.statusCode}");
      print("📦 Response body: ${response.body}");

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print("✅ ยกเลิกออเดอร์สำเร็จ: ${data.toString()}");
        return true;
      } else {
        _error = data['error'] ?? 'Failed to cancel order';
        print("❌ ยกเลิกออเดอร์ไม่สำเร็จ: $_error");
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      print("⚠️ เกิดข้อผิดพลาดเครือข่าย: $e");
      notifyListeners();
      return false;
    }
  }

  // NEW: Fetch orders by customer ID
  Future<void> fetchOrdersByCustomer({required int userId}) async {
    _setLoading(true);
    _error = null;

    try {
      String url = '$baseUrl/orders?user_id=$userId';

      print('👤 Fetching orders for customer $userId from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Response status: ${response.statusCode}');
      print(
        '📦 Response body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> ordersData = data['data'] ?? [];

          print('📦 Raw orders count from API: ${ordersData.length}');

          // แปลงเป็น Order objects
          final parsedOrders = ordersData
              .map((orderJson) {
                try {
                  return Order.fromJson(orderJson);
                } catch (e) {
                  print('❌ Error parsing order: $e');
                  print('📄 Failed Order JSON: $orderJson');
                  return null;
                }
              })
              .where((o) => o != null)
              .cast<Order>()
              .toList();

          // เรียงตาม createdAt ใหม่สุดก่อน
          _orders = parsedOrders
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          print('✅ Successfully loaded ${_orders.length} customer orders');
          for (var o in _orders) {
            print(
              '   ↳ OrderID: ${o.orderId}, status: ${o.status}, createdAt: ${o.createdAt}',
            );
          }

          // Group orders by status for logging
          final statusGroups = <String, int>{};
          for (var order in _orders) {
            statusGroups[order.status] = (statusGroups[order.status] ?? 0) + 1;
          }
          print('📊 Customer orders by status: $statusGroups');
        } else {
          _error = data['error'] ?? 'Failed to fetch customer orders';
          print('❌ API Error: $_error');
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode} - ${response.body}';
        print('❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('❌ Network error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get orders by status - Updated with better filtering
  List<Order> getOrdersByStatus(String status) {
    final filtered = _orders.where((order) => order.status == status).toList();
    print('🔍 getOrdersByStatus($status): found ${filtered.length} orders');
    return filtered;
  }

  // Get pending orders (waiting for shop confirmation)
  List<Order> get pendingOrders => getOrdersByStatus('waiting');

  // Get accepted orders (shop confirmed, cooking)
  List<Order> get acceptedOrders => getOrdersByStatus('accepted');

  // Get completed orders
  List<Order> get completedOrders => getOrdersByStatus('completed');

  // Get cancelled/rejected orders
  List<Order> get rejectedOrders {
    final rejected = _orders
        .where(
          (order) => order.status == 'cancelled' || order.status == 'rejected',
        )
        .toList();
    return rejected;
  }

  // Get orders with riders
  List<Order> get ordersWithRiders =>
      _orders.where((order) => order.hasRider).toList();

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}

// Extension for Order copyWith method
extension OrderCopyWith on Order {
  Order copyWith({
    int? orderId,
    int? userId,
    int? marketId,
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
      shopName: shopName,
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
