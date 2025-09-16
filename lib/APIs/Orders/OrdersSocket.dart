// controllers/order_controller.dart
import 'dart:convert';
import 'package:delivery/APIs/SOCKET_IO/SocketService.dart';
import 'package:delivery/pages/order/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OrderController extends ChangeNotifier {
  final SocketService _socketService = SocketService();
  final String baseUrl = 'http://192.168.1.119:4000/socket'; // เปลี่ยนตาม server ของคุณ

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
  void _setupSocketListeners() {
    _socketService.on('order:updated', (data) {
      print('📦 Order updated: $data');
      _handleOrderUpdate(data);
    });

    _socketService.on('new_order_notification', (data) {
      print('🔔 New order notification: $data');
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

  // Fetch orders from API
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

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _orders = (data['data'] as List)
              .map((orderJson) => Order.fromJson(orderJson))
              .toList();
        } else {
          _error = data['error'] ?? 'Failed to fetch orders';
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
        if (data['success'] == true) {
          // Create order object from status data
          _currentOrder = Order(
            orderId: data['data']['order_id'],
            userId: 0, // Will be filled from full order data
            marketId: data['data']['shop_id'] ?? 0,
            riderId: data['data']['rider_id'],
            address: '',
            deliveryType: '',
            paymentMethod: '',
            deliveryFee: 0.0,
            totalPrice: 0.0,
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
      final response = await http.post(
        Uri.parse('$baseUrl/accept_order'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': orderId,
          'market_id': marketId,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return true;
      } else {
        _error = data['error'] ?? 'Failed to accept order';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return false;
    }
  }

  // Assign rider to order
  Future<bool> assignRider(int orderId, int riderId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/assign-rider'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': orderId,
          'rider_id': riderId,
        }),
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
  Future<bool> updateOrderStatus(int orderId, String status, {Map<String, dynamic>? additionalData}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/update-status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': orderId,
          'status': status,
          'additional_data': additionalData,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return true;
      } else {
        _error = data['error'] ?? 'Failed to update order status';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return false;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(int orderId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': orderId,
          'reason': reason,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
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
    return _orders.where((order) => order.status == status).toList();
  }

  // Get pending orders
  List<Order> get pendingOrders => getOrdersByStatus('waiting');

  // Get accepted orders
  List<Order> get acceptedOrders => getOrdersByStatus('accepted');

  // Get orders with riders
  List<Order> get ordersWithRiders => _orders.where((order) => order.hasRider).toList();

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