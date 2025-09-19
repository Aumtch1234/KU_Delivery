// controllers/customer_order_controller.dart - สำหรับ Customer View
import 'dart:convert';
import 'package:delivery/APIs/Orders/OrdersSocket.dart';
import 'package:delivery/APIs/SOCKET_IO/SocketService.dart';
import 'package:delivery/APIs/api_config.dart';
import 'package:delivery/pages/order/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CustomerOrderController extends ChangeNotifier {
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

  // ✅ Initialize socket for customer
  Future<void> initializeSocket(int userId) async {
    try {
      await _socketService.connect();
      _setupSocketListeners();

      // Register customer room
      _socketService.emit('customer:register', userId);
    } catch (e) {
      _error = 'Failed to connect to socket: $e';
      notifyListeners();
    }
  }

  void _setupSocketListeners() {
    _socketService.on('order:updated', (data) {
      print('📦 Customer order updated: $data');
      _handleOrderUpdate(data);
    });

    _socketService.on('customer:newOrder', (data) {
      print('🛒 Customer got new order: $data');
      fetchOrders(); // refresh orders
    });

    _socketService.on('error', (error) {
      print('🚫 Socket error: $error');
      _error = 'Socket error: ${error.toString()}';
      notifyListeners();
    });
  }

  void _handleOrderUpdate(dynamic data) {
    if (data == null) return;
    final orderId = data['order_id'];
    if (orderId == null) return;

    final index = _orders.indexWhere((order) => order.orderId == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: data['status'] ?? _orders[index].status,
        riderId: data['rider_id'] ?? _orders[index].riderId,
        updatedAt: data['timestamps']?['updated_at'] != null
            ? DateTime.parse(data['timestamps']['updated_at'])
            : DateTime.now(),
      );
      notifyListeners();
    }
  }

  // ✅ Fetch all customer orders
  Future<void> fetchOrders() async {
    _setLoading(true);
    _error = null;

    try {
      final url = '$baseUrl/customer/orders';
      print('🔍 Fetching customer orders from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> ordersData = data['data'] ?? [];
          _orders = ordersData.map((o) => Order.fromJson(o)).toList();

          print('✅ Loaded ${_orders.length} customer orders');
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

  // ✅ Fetch single order
  Future<void> fetchOrderById(int orderId) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer/orders/$orderId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _currentOrder = Order.fromJson(data['order']);
        } else {
          _error = data['message'] ?? 'Failed to fetch order';
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

  // ✅ Cancel order (customer)
  Future<bool> cancelOrder(int orderId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cancel_order'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': orderId, 'reason': reason}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        fetchOrders();
        return true;
      } else {
        _error = data['error'] ?? 'Failed to cancel order';
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      return false;
    }
  }

  // Helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}
