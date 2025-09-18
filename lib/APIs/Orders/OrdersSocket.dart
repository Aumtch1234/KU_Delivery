// controllers/order_controller.dart - แก้ไขให้ join room ครบถ้วน
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

  // Initialize socket connection - แก้ไขให้ join room ครบถ้วน
  Future<void> initializeSocket({
    int? userId,
    int? marketId,
    int? riderId,
  }) async {
    try {
      print('🔌 Initializing socket connection...');
      await _socketService.connect();
      _setupSocketListeners();

      // Register user with comprehensive data
      Map<String, dynamic> registrationData = {};
      String userType = 'customer';
      
      if (userId != null) {
        registrationData['userId'] = userId;
        userType = 'customer';
      }
      if (marketId != null) {
        registrationData['marketId'] = marketId;
        userType = 'shop';
      }
      if (riderId != null) {
        registrationData['riderId'] = riderId;
        userType = 'rider';
      }
      
      registrationData['userType'] = userType;
      
      print('📝 Registering user with data: $registrationData');
      _socketService.emit("register_user", registrationData);

      // Join appropriate rooms
      if (userId != null) {
        final customerRoom = "customer:$userId";
        _socketService.emit("join_room", {"room": customerRoom});
        print('📍 Joined customer room: $customerRoom');
      }
      
      if (marketId != null) {
        final shopRoom = "shop:$marketId";
        _socketService.emit("join_room", {"room": shopRoom});
        print('📍 Joined shop room: $shopRoom');
      }
      
      if (riderId != null) {
        final riderRoom = "rider:$riderId";
        _socketService.emit("join_room", {"room": riderRoom});
        print('📍 Joined rider room: $riderRoom');
      }

      print('✅ Socket initialization complete');
    } catch (e) {
      _error = 'Failed to connect to socket: $e';
      print('❌ Socket initialization failed: $e');
      notifyListeners();
    }
  }

  // Setup socket event listeners - เพิ่ม event listeners ที่จำเป็น
  void _setupSocketListeners() {
    print('🎧 Setting up socket listeners...');
    
    // ✅ Connection status
    _socketService.on('connect', (data) {
      print('✅ Socket connected successfully');
      notifyListeners();
    });

    _socketService.on('disconnect', (data) {
      print('❌ Socket disconnected');
      notifyListeners();
    });

    // ✅ Main order update listener
    _socketService.on('order:updated', (data) {
      print('📦 Order updated: $data');
      _handleOrderUpdate(data);
    });

    // ✅ New order notifications
    _socketService.on('new_order_notification', (data) {
      print('🔔 New order notification: $data');
      _handleNewOrderNotification(data);
    });

    // ✅ Customer-specific new order
    _socketService.on('customer:newOrder', (data) {
      print('👤 New order for customer: $data');
      _handleNewOrderNotification(data);
    });

    // ✅ Order status updates
    _socketService.on('order_status_update', (data) {
      print('📊 Order status update: $data');
      _handleOrderUpdate(data);
    });

    // ✅ Error handling
    _socketService.on('error', (error) {
      print('🚫 Socket error: $error');
      _error = 'Socket error: ${error.toString()}';
      notifyListeners();
    });

    // ✅ Heartbeat/ping for connection health
    _socketService.on('pong', (data) {
      print('💗 Heartbeat pong received');
    });

    print('✅ Socket listeners setup complete');
  }

  // Improved order update handler
  void _handleOrderUpdate(dynamic data) {
    if (data == null) {
      print('⚠️ Received null order update data');
      return;
    }

    print('🔄 Processing order update: $data');
    
    final orderId = data['order_id'];
    if (orderId == null) {
      print('⚠️ Order update missing order_id');
      return;
    }

    try {
      // Update current order if it matches
      if (_currentOrder?.orderId == orderId) {
        _currentOrder = _currentOrder?.copyWith(
          status: data['status'] ?? _currentOrder!.status,
          riderId: data['rider_id'] ?? _currentOrder!.riderId,
          updatedAt: data['timestamp'] != null
              ? DateTime.parse(data['timestamp'])
              : _currentOrder!.updatedAt,
        );
        print('📝 Updated current order: ${_currentOrder?.orderId}');
      }

      // Update order in list
      final index = _orders.indexWhere((order) => order.orderId == orderId);
      if (index != -1) {
        final oldStatus = _orders[index].status;
        _orders[index] = _orders[index].copyWith(
          status: data['status'] ?? _orders[index].status,
          riderId: data['rider_id'] ?? _orders[index].riderId,
          updatedAt: data['timestamp'] != null
              ? DateTime.parse(data['timestamp'])
              : _orders[index].updatedAt,
        );
        
        print('📝 Updated order in list: $orderId ($oldStatus -> ${_orders[index].status})');
      } else {
        print('⚠️ Order $orderId not found in local list for update');
        // Optionally fetch the order if it's not in the list
        _fetchSingleOrder(orderId);
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error handling order update: $e');
    }
  }

  // Handle new order notification
  void _handleNewOrderNotification(dynamic data) {
    print('🆕 Handling new order notification: $data');
    // Refresh orders list when new order comes in
    fetchOrders();
  }

  // Fetch single order (helper method)
  Future<void> _fetchSingleOrder(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order_status/$orderId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Create simplified order from status data
          // You might want to implement Order.fromStatusData if this is needed frequently
          print('📥 Fetched single order $orderId successfully');
        }
      }
    } catch (e) {
      print('❌ Error fetching single order $orderId: $e');
    }
  }

  // Watch specific order
  void watchOrder(int orderId) {
    print('👁️ Watching order: $orderId');
    _socketService.emit("customer:watchOrder", orderId);
    _socketService.emit("shop:watchOrder", orderId);
    _socketService.emit("rider:watchOrder", orderId);
  }

  // Stop watching order
  void stopWatchingOrder() {
    print('👁️‍🗨️ Stopping order watch');
    _socketService.off('order:updated');
  }

  // Send heartbeat to check connection
  void sendHeartbeat() {
    if (_socketService.isConnected) {
      _socketService.emit('ping');
    }
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> ordersData = data['data'] ?? [];

          // แปลงเป็น Order objects
          final parsedOrders = ordersData
              .map((orderJson) {
                try {
                  return Order.fromJson(orderJson);
                } catch (e) {
                  print('❌ Error parsing order: $e');
                  return null;
                }
              })
              .where((o) => o != null)
              .cast<Order>()
              .toList();

          // MERGE LOGIC - preserve existing orders and add/update new ones
          final Map<int, Order> merged = {
            for (var o in _orders) o.orderId: o,
          };

          for (var o in parsedOrders) {
            merged[o.orderId] = o;
          }

          _orders = merged.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          print('✅ After merging, orders in state: ${_orders.length}');

          // Group orders by status for logging
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
          _currentOrder = Order(
            orderId: data['data']['order_id'],
            userId: 0,
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

  // Accept order (for shop)
  Future<bool> acceptOrder(int orderId, int marketId) async {
    try {
      print('🏪 Accepting order $orderId for market $marketId');

      final response = await http.post(
        Uri.parse('$baseUrl/accept_order'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': orderId, 'market_id': marketId}),
      );

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
      final response = await http.post(
        Uri.parse('$baseUrl/cancel_order'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': orderId, 'reason': reason}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        // Update local order status immediately
        final orderIndex = _orders.indexWhere(
          (order) => order.orderId == orderId,
        );
        if (orderIndex != -1) {
          _orders[orderIndex] = _orders[orderIndex].copyWith(
            status: 'cancelled',
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }
        
        return true;
      } else {
        _error = data['error'] ?? 'Failed to cancel order';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> ordersData = data['data'] ?? [];

          // แปลงเป็น Order objects
          final parsedOrders = ordersData
              .map((orderJson) {
                try {
                  return Order.fromJson(orderJson);
                } catch (e) {
                  print('❌ Error parsing order: $e');
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

  // Get orders by status
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