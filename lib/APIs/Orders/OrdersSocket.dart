// แก้ไข controllers/order_controller.dart
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
  int? _currentMarketId; // เพิ่มเพื่อกรองข้อมูล
  int? _currentUserId; // เพิ่มเพื่อกรองข้อมูล

  // Getters
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Order? get currentOrder => _currentOrder;
  bool get isSocketConnected => _socketService.isConnected;

  // แก้ไข initializeSocket ให้ถูกต้อง
  Future<void> initializeSocket({
    int? userId,
    int? marketId,
    int? riderId,
  }) async {
    try {
      print('🔌 Initializing socket connection...');

      // เก็บข้อมูลปัจจุบัน
      _currentUserId = userId;
      _currentMarketId = marketId;

      await _socketService.connect();
      _setupSocketListeners();
      await _refreshCurrentData(); // ⭐ เพิ่มบรรทัดนี้

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

      // ⭐ Force UI update after socket connection
      notifyListeners();

      // ⭐ เพิ่ม subscription สำหรับ global order events
      _subscribeToGlobalOrderEvents();
    } catch (e) {
      _error = 'Failed to connect to socket: $e';
      print('❌ Socket initialization failed: $e');
      notifyListeners();
    }
  }

  // เพิ่ม method สำหรับ subscribe global order events
  void _subscribeToGlobalOrderEvents() {
    print('🌐 Subscribing to global order events...');

    // Subscribe to general order updates
    _socketService.emit("subscribe_order_updates", {
      "marketId": _currentMarketId,
      "userId": _currentUserId,
    });

    // Join global order room
    _socketService.emit("join_room", {"room": "order_updates"});

    if (_currentMarketId != null) {
      _socketService.emit("join_room", {
        "room": "market_${_currentMarketId}_orders",
      });
    }

    print('✅ Global order events subscription complete');
  }

  // แก้ไข _setupSocketListeners ให้ครบถ้วน
  void _setupSocketListeners() {
    print('🎧 Setting up socket listeners...');

    // Clear existing listeners first
    _socketService.off('connect');
    _socketService.off('disconnect');
    _socketService.off('order:updated');
    _socketService.off('new_order_notification');
    _socketService.off('customer:newOrder');
    _socketService.off('order_status_update');
    _socketService.off('rider:statusUpdate');
    _socketService.off('shop:orderUpdate');
    _socketService.off('error');
    _socketService.off('pong');

    // เพิ่ม listeners สำหรับ rider events
    _socketService.off('rider:updateStatus');
    _socketService.off('rider:orderStatusUpdate');
    _socketService.off('orderStatusChanged');
    _socketService.off('riderStatusUpdate');
    _socketService.off('order_rider_update');

    // Connection status
    _socketService.on('connect', (data) async {
      print('✅ Socket connected successfully');

      // 🔁 Rejoin room หลัง reconnect
      if (_currentUserId != null) {
        _socketService.emit("join_room", {"room": "customer:$_currentUserId"});
        print("📡 Rejoined customer room: customer:$_currentUserId");
      }
      if (_currentMarketId != null) {
        _socketService.emit("join_room", {"room": "shop:$_currentMarketId"});
        print("📡 Rejoined shop room: shop:$_currentMarketId");
      }

      await _refreshCurrentData();
      notifyListeners();
    });

    _socketService.on('disconnect', (data) {
      print('❌ Socket disconnected');
      notifyListeners(); // ⭐ อัปเดต UI
    });

    // Main order update listener
    _socketService.on('order:updated', (data) {
      print('📦 Order updated: $data');
      _handleOrderUpdate(data);
    });

    // New order notifications
    _socketService.on('new_order_notification', (data) {
      print('🔔 New order notification: $data');
      _handleNewOrderNotification(data);
    });

    _socketService.on('customer:newOrder', (data) {
      print('👤 New order for customer: $data');
      _handleNewOrderNotification(data);
    });

    _socketService.on('order_status_update', (data) {
      print('📊 Order status update: $data');
      _handleOrderUpdate(data);
    });

    _socketService.on('error', (error) {
      print('🚫 Socket error: $error');
      _error = 'Socket error: ${error.toString()}';
      notifyListeners(); // ⭐ อัปเดต UI
    });

    _socketService.on('pong', (data) {
      print('💗 Heartbeat pong received');
    });

    // เพิ่ม listeners สำหรับ rider และ shop updates
    _socketService.on('rider:statusUpdate', (data) {
      print('🏍️ Rider status update: $data');
      _handleOrderUpdate(data);
    });

    _socketService.on('shop:orderUpdate', (data) {
      print('🏪 Shop order update: $data');
      _handleOrderUpdate(data);
    });

    // เพิ่ม listeners เพิ่มเติมสำหรับ rider events
    _socketService.on('rider:updateStatus', (data) {
      print('🏍️ Rider update status event: $data');
      _handleOrderUpdate(data);
    });

    _socketService.on('rider:orderStatusUpdate', (data) {
      print('🏍️ Rider order status update event: $data');
      _handleOrderUpdate(data);
    });

    _socketService.on('orderStatusChanged', (data) {
      print('📊 Order status changed event: $data');
      _handleOrderUpdate(data);
    });

    _socketService.on('riderStatusUpdate', (data) {
      print('🏍️ Rider status update event: $data');
      _handleOrderUpdate(data);
    });

    _socketService.on('order_rider_update', (data) {
      print('📦🏍️ Order rider update event: $data');
      _handleOrderUpdate(data);
    });

    print('✅ Socket listeners setup complete');
  }

  // ปรับปรุง _handleOrderUpdate ให้กรองข้อมูลและอัปเดต UI
  void _handleOrderUpdate(dynamic data) {
    if (data == null) {
      print('⚠️ Received null order update data');
      return;
    }

    print('🔄 Processing order update: $data');

    // แปลง orderId ให้เป็น int เสมอ
    dynamic orderIdRaw = data['order_id'] ?? data['orderId'];
    if (orderIdRaw == null) {
      print('⚠️ Order update missing order_id');
      return;
    }

    int orderId;
    try {
      orderId = orderIdRaw is int
          ? orderIdRaw
          : int.parse(orderIdRaw.toString());
    } catch (e) {
      print('❌ Invalid orderId format: $orderIdRaw');
      return;
    }

    // ⭐ ลดการกรองที่เข้มงวดเกินไป - อนุญาตให้ update ผ่านได้มากขึ้น
    // ✅ เปลี่ยนเป็น optional filtering สำหรับ rider updates
    bool shouldFilter = false;
    if (_currentMarketId != null && data['market_id'] != null) {
      try {
        final dataMarketId = data['market_id'] is int
            ? data['market_id']
            : int.parse(data['market_id'].toString());
        if (dataMarketId != _currentMarketId) {
          print(
            '🚫 Different market detected: $dataMarketId (current: $_currentMarketId), but allowing rider updates',
          );
          // ถ้าเป็น rider status update ให้ผ่านไปได้
          if (![
            'going_to_shop',
            'arrived_at_shop',
            'picked_up',
            'delivering',
            'arrived_at_customer',
            'completed',
          ].contains(data['status'])) {
            shouldFilter = true;
          }
        }
      } catch (e) {
        print(
          '⚠️ Could not parse market_id, allowing update: ${data['market_id']}',
        );
      }
    }

    if (shouldFilter) {
      print('🚫 Filtering out non-rider update from different market');
      return;
    }

    try {
      bool hasChanges = false;

      // ✅ อ่านค่า shop_status จาก event (รองรับ fallback)
      final String? newShopStatus =
          data['shop_status'] ??
          ((data['status'] == 'preparing' ||
                  data['status'] == 'ready_for_pickup')
              ? data['status']
              : null);

      // Update current order if it matches
      if (_currentOrder?.orderId == orderId) {
        final newStatus = data['status'] ?? _currentOrder!.status;
        final newRiderId = data['rider_id'] ?? _currentOrder!.riderId;

        if (_currentOrder!.status != newStatus ||
            _currentOrder!.riderId != newRiderId ||
            _currentOrder!.shopStatus != newShopStatus) {
          _currentOrder = _currentOrder?.copyWith(
            status: newStatus,
            riderId: newRiderId,
            shopStatus: newShopStatus,
            updatedAt: data['timestamp'] != null
                ? DateTime.parse(data['timestamp'])
                : DateTime.now(),
          );
          hasChanges = true;
          print('📝 Updated current order: ${_currentOrder?.orderId}');
        }
      }

      // Update order in list
      final index = _orders.indexWhere((order) => order.orderId == orderId);
      if (index != -1) {
        final oldStatus = _orders[index].status;
        final oldShopStatus = _orders[index].shopStatus;
        final newStatus = data['status'] ?? _orders[index].status;
        final newRiderId = data['rider_id'] ?? _orders[index].riderId;

        if (oldStatus != newStatus ||
            _orders[index].riderId != newRiderId ||
            oldShopStatus != newShopStatus) {
          _orders[index] = _orders[index].copyWith(
            status: newStatus,
            riderId: newRiderId,
            shopStatus: newShopStatus,
            updatedAt: data['timestamp'] != null
                ? DateTime.parse(data['timestamp'])
                : DateTime.now(),
          );
          hasChanges = true;
          print(
            '📝 Updated order in list: $orderId ($oldStatus->$newStatus, shopStatus: $oldShopStatus->$newShopStatus)',
          );
        }
      } else {
        print('⚠️ Order $orderId not found in local list for update');
        // ลองค้นหาด้วย string conversion
        final stringIndex = _orders.indexWhere(
          (order) => order.orderId.toString() == orderId.toString(),
        );
        if (stringIndex != -1) {
          final oldStatus = _orders[stringIndex].status;
          final oldShopStatus = _orders[stringIndex].shopStatus;
          final newStatus = data['status'] ?? _orders[stringIndex].status;
          final newRiderId = data['rider_id'] ?? _orders[stringIndex].riderId;

          if (oldStatus != newStatus ||
              _orders[stringIndex].riderId != newRiderId ||
              oldShopStatus != newShopStatus) {
            _orders[stringIndex] = _orders[stringIndex].copyWith(
              status: newStatus,
              riderId: newRiderId,
              shopStatus: newShopStatus,
              updatedAt: data['timestamp'] != null
                  ? DateTime.parse(data['timestamp'])
                  : DateTime.now(),
            );
            hasChanges = true;
            print(
              '📝 Updated order in list (string match): $orderId ($oldStatus->$newStatus, shopStatus: $oldShopStatus->$newShopStatus)',
            );
          }
        } else {
          print('⚠️ Order $orderId not found even with string matching');
          hasChanges = true;
          // _refreshCurrentData(); // ปิดการ refresh เพื่อป้องกัน infinite loop
        }
      }

      // ⭐ Force UI update if there are changes
      if (hasChanges) {
        print('🔄 Notifying listeners of order update');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error handling order update: $e');
      _error = 'Error processing order update: $e';
      notifyListeners();
    }
  }

  // Handle new order notification
  void _handleNewOrderNotification(dynamic data) {
    print('🆕 Handling new order notification: $data');
    // Refresh orders list when new order comes in
    _refreshCurrentData();
  }

  // Helper method to refresh current data based on type
  Future<void> _refreshCurrentData() async {
    if (_currentMarketId != null) {
      await fetchOrdersByMarket(marketId: _currentMarketId!);
    } else if (_currentUserId != null) {
      await fetchOrdersByCustomer(userId: _currentUserId!);
    } else {
      await fetchOrders();
    }
  }

  // แก้ไข fetchOrdersByMarket ให้ replace แทน merge
  Future<void> fetchOrdersByMarket({required int marketId}) async {
    _setLoading(true);
    _error = null;
    _currentMarketId = marketId; // เก็บ market ID

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

          // แปลงเป็น Order objects และกรองเฉพาะร้านตัวเอง
          final parsedOrders = ordersData
              .map((orderJson) {
                try {
                  final order = Order.fromJson(orderJson);
                  // ⭐ กรองเฉพาะออเดอร์ของร้านตัวเอง
                  if (order.marketId == marketId) {
                    return order;
                  }
                  return null;
                } catch (e) {
                  print('❌ Error parsing order: $e');
                  return null;
                }
              })
              .where((o) => o != null)
              .cast<Order>()
              .toList();

          // ⭐ Replace แทน merge เพื่อป้องกันออเดอร์ร้านอื่นปะปน
          _orders = parsedOrders
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          print(
            '✅ Successfully loaded ${_orders.length} orders for market $marketId',
          );

          // Group orders by status for logging
          final statusGroups = <String, int>{};
          for (var order in _orders) {
            statusGroups[order.status] = (statusGroups[order.status] ?? 0) + 1;
          }
          print('📊 Orders by status for market $marketId: $statusGroups');
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

  // แก้ไข fetchOrdersByCustomer ให้กรองข้อมูลถูกต้อง
  Future<void> fetchOrdersByCustomer({required int userId}) async {
    _setLoading(true);
    _error = null;
    _currentUserId = userId; // เก็บ user ID

    try {
      String url = '$baseUrl/orders?user_id=$userId';
      print('👤 Fetching orders for customer $userId from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("{fetch data: ${data}");
        if (data['success'] == true) {
          final List<dynamic> ordersData = data['data'] ?? [];

          // แปลงเป็น Order objects และกรองเฉพาะลูกค้าตัวเอง
          final parsedOrders = ordersData
              .map((orderJson) {
                try {
                  final order = Order.fromJson(orderJson);
                  // ⭐ กรองเฉพาะออเดอร์ของลูกค้าตัวเอง
                  if (order.userId == userId) {
                    return order;
                  }
                  return null;
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

  // แก้ไข acceptOrder ให้อัปเดต UI ทันที
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
        // ⭐ Update local order status ทันทีพร้อม force UI update
        final orderIndex = _orders.indexWhere(
          (order) => order.orderId == orderId,
        );
        if (orderIndex != -1) {
          _orders[orderIndex] = _orders[orderIndex].copyWith(
            status: 'accepted',
            updatedAt: DateTime.now(),
          );
          print('✅ Local order updated immediately');
        }

        print('✅ Order $orderId accepted successfully');

        // ⭐ Force UI update
        notifyListeners();
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

  // เพิ่ม method สำหรับ updatePreparationStatus
  Future<bool> updatePreparationStatus(
    int orderId,
    String status, // 'preparing' หรือ 'ready_for_pickup'
  ) async {
    try {
      print('🔄 Updating preparation status for order $orderId to $status');

      final response = await http.post(
        Uri.parse('$baseUrl/update_preparation_status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': orderId, 'status': status}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        // ⭐ Update local order status ทันทีพร้อม force UI update
        final orderIndex = _orders.indexWhere(
          (order) => order.orderId == orderId,
        );
        if (orderIndex != -1) {
          final oldShopStatus = _orders[orderIndex].shopStatus;
          final currentOrder = _orders[orderIndex];

          // เก็บสถานะไรเดอร์ปัจจุบันก่อนที่จะอัปเดต (ถ้ายังไม่มี)
          String? preservedRiderStatus = currentOrder.riderStatus;
          if (preservedRiderStatus == null &&
              currentOrder.status != 'preparing') {
            // ถ้ายังไม่มี riderStatus และกำลังจะเปลี่ยนเป็น preparing
            // ให้เก็บสถานะปัจจุบันเป็น riderStatus
            if (currentOrder.status == 'going_to_shop' ||
                currentOrder.status == 'arrived_at_shop') {
              preservedRiderStatus = currentOrder.status;
            }
          }

          _orders[orderIndex] = _orders[orderIndex].copyWith(
            shopStatus: status, // อัปเดตเฉพาะ shopStatus
            riderStatus: preservedRiderStatus, // เก็บสถานะไรเดอร์ไว้
            updatedAt: DateTime.now(),
          );
          print(
            '✅ Local preparation status updated immediately: Order $orderId shopStatus changed from $oldShopStatus to $status',
          );
          print(
            '📊 Order $orderId after update: status=${_orders[orderIndex].status}, shopStatus=${_orders[orderIndex].shopStatus}',
          );
        } else {
          print('⚠️ Order $orderId not found in _orders list for local update');
        }

        if (_currentOrder?.orderId == orderId) {
          final oldShopStatus = _currentOrder?.shopStatus;
          final currentOrderRef = _currentOrder!;

          // เก็บสถานะไรเดอร์ปัจจุบันก่อนที่จะอัปเดต (ถ้ายังไม่มี)
          String? preservedRiderStatus = currentOrderRef.riderStatus;
          if (preservedRiderStatus == null &&
              currentOrderRef.status != 'preparing') {
            if (currentOrderRef.status == 'going_to_shop' ||
                currentOrderRef.status == 'arrived_at_shop') {
              preservedRiderStatus = currentOrderRef.status;
            }
          }

          _currentOrder = _currentOrder?.copyWith(
            shopStatus: status,
            riderStatus: preservedRiderStatus, // เก็บสถานะไรเดอร์ไว้
            updatedAt: DateTime.now(),
          );
          print(
            '✅ Current order preparation status updated immediately: Order $orderId shopStatus changed from $oldShopStatus to $status',
          );
        }
        print('✅ Order $orderId preparation status updated to $status');

        // ⭐ Force UI update
        print('🔄 Forcing UI update after preparation status change');

        // Debug: ตรวจสอบออเดอร์ในแต่ละแท็บหลัง update
        print('📊 Debug - Orders in each tab after preparation status update:');
        print(
          '  - rider_assigned: ${getOrdersByStatus('rider_assigned').length}',
        );
        print('  - accepted: ${getOrdersByStatus('accepted').length}');
        print('  - completed: ${getOrdersByStatus('completed').length}');

        // Debug: แสดงรายละเอียดออเดอร์ที่เพิ่งอัปเดต
        final updatedOrder = _orders.firstWhere((o) => o.orderId == orderId);
        print(
          '📦 Updated order details: ID=${updatedOrder.orderId}, status=${updatedOrder.status}, shopStatus=${updatedOrder.shopStatus}',
        );

        notifyListeners();
        return true;
      } else {
        _error = data['error'] ?? 'Failed to update preparation status';
        print('❌ Failed to update preparation status: $_error');
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

  // เพิ่ม method สำหรับมาร์คอาหารพร้อม - ส่งไปแท็บเสร็จแล้ว
  Future<bool> markFoodReady(int orderId) async {
    try {
      print(
        '🍽️ Marking food ready for order $orderId - sending to completed tab',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/update_preparation_status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': orderId, 'status': 'ready_for_pickup'}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        // ⭐ Update local order status เป็น ready_for_pickup เพื่อให้เด้งไปแท็บ completed
        final orderIndex = _orders.indexWhere(
          (order) => order.orderId == orderId,
        );
        if (orderIndex != -1) {
          _orders[orderIndex] = _orders[orderIndex].copyWith(
            shopStatus: 'ready_for_pickup',
            updatedAt: DateTime.now(),
          );
          print(
            '✅ Local food ready status updated - order moved to completed tab',
          );
        }
        if (_currentOrder?.orderId == orderId) {
          _currentOrder = _currentOrder?.copyWith(
            shopStatus: 'ready_for_pickup',
            updatedAt: DateTime.now(),
          ); // ✅
        }

        print(
          '✅ Order $orderId food marked as ready and moved to completed tab',
        );

        // ⭐ Force UI update
        notifyListeners();
        return true;
      } else {
        _error = data['error'] ?? 'Failed to mark food ready';
        print('❌ Failed to mark food ready: $_error');
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

  // แก้ไข updateOrderStatus ให้อัปเดต UI ทันที
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
        // ⭐ Update local order status ทันทีพร้อม force UI update
        final orderIndex = _orders.indexWhere(
          (order) => order.orderId == orderId,
        );
        if (orderIndex != -1) {
          _orders[orderIndex] = _orders[orderIndex].copyWith(
            status: status,
            updatedAt: DateTime.now(),
          );
          print('✅ Local order updated immediately');
        }

        print('✅ Order $orderId status updated to $status');

        // ⭐ Force UI update
        notifyListeners();
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

  // แก้ไข cancelOrder ให้อัปเดต UI ทันที
  Future<bool> cancelOrder(int orderId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cancel_order'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': orderId, 'reason': reason}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        // ⭐ Update local order status ทันทีพร้อม force UI update
        final orderIndex = _orders.indexWhere(
          (order) => order.orderId == orderId,
        );
        if (orderIndex != -1) {
          _orders[orderIndex] = _orders[orderIndex].copyWith(
            status: 'cancelled',
            updatedAt: DateTime.now(),
          );
          print('✅ Local order cancelled immediately');
        }

        // ⭐ Force UI update
        notifyListeners();
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

  // ปรับปรุง _setLoading ให้ force UI update
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners(); // ⭐ อัปเดต UI เสมอเมื่อ loading state เปลี่ยน
    }
  }

  // ปรับปรุง clearError ให้ force UI update
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners(); // ⭐ อัปเดต UI เมื่อ clear error
    }
  }

  // Get orders by status - ปรับปรุงการกรองสำหรับ Shop Categories
  List<Order> getOrdersByStatus(String statusCategory) {
    List<Order> filtered;

    switch (statusCategory) {
      case 'waiting':
        // รอไรเดอร์ - ออเดอร์ที่รอไรเดอร์กดรับ
        filtered = _orders.where((order) => order.status == 'waiting').toList();
        break;

      case 'rider_assigned':
        // รอรับ - ออเดอร์ที่มีไรเดอร์แล้วแต่ร้านยังไม่ยืนยัน
        filtered = _orders
            .where((order) => order.status == 'rider_assigned')
            .toList();
        break;

      case 'accepted':
        // รับแล้ว - ออเดอร์ที่ร้านยืนยันแล้ว รวมถึงไรเดอร์กำลังมาหรือถึงร้านแล้ว
        // รวมถึงที่กำลังทำอาหาร (preparing) แต่ยังไม่พร้อม (ready_for_pickup)
        filtered = _orders.where((order) {
          bool statusMatch = [
            'confirmed',
            'preparing', // ⭐ เพิ่ม 'preparing' เข้าไป
            'going_to_shop',
            'arrived_at_shop',
          ].contains(order.status);

          // แก้ไขการกรอง shop_status ให้ชัดเจน - รวม null และ preparing เท่านั้น
          bool shopStatusMatch =
              (order.shopStatus == null || order.shopStatus == 'preparing');

          // Debug logs สำหรับแต่ละ order
          print(
            '🔍 Order ${order.orderId}: status=${order.status}, shopStatus=${order.shopStatus}, statusMatch=$statusMatch, shopStatusMatch=$shopStatusMatch, included=${statusMatch && shopStatusMatch}',
          );

          return statusMatch && shopStatusMatch;
        }).toList();
        break;

      case 'completed':
        // เสร็จแล้ว - ออเดอร์ที่อาหารพร้อมแล้วจนถึงส่งสำเร็จ
        filtered = _orders
            .where(
              (order) =>
                  order.shopStatus == 'ready_for_pickup' ||
                  [
                    'picked_up',
                    'delivering',
                    'arrived_at_customer',
                    'completed',
                  ].contains(order.status),
            )
            .toList();
        break;

      case 'cancelled':
        // ปฏิเสธ/ยกเลิก
        filtered = _orders
            .where((order) => order.status == 'cancelled')
            .toList();
        break;

      default:
        // Fallback สำหรับ exact match
        filtered = _orders
            .where((order) => order.status == statusCategory)
            .toList();
        break;
    }

    print(
      '🔍 getOrdersByStatus($statusCategory): found ${filtered.length} orders',
    );

    // Debug: แสดงรายละเอียดแต่ละ order ที่กรองได้
    for (var order in filtered) {
      print(
        '  📦 Order ${order.orderId}: status=${order.status}, shopStatus=${order.shopStatus}',
      );
    }

    return filtered;
  }

  // เพิ่ม method สำหรับ debug
  void debugPrintOrdersState() {
    print('📊 Current orders state:');
    print('   Total orders: ${_orders.length}');
    print('   Current market ID: $_currentMarketId');
    print('   Current user ID: $_currentUserId');
    print('   Socket connected: $isSocketConnected');
    print('   Loading: $_isLoading');
    print('   Error: $_error');

    final statusGroups = <String, int>{};
    for (var order in _orders) {
      statusGroups[order.status] = (statusGroups[order.status] ?? 0) + 1;
    }
    print('   Orders by status: $statusGroups');

    // แสดงรายละเอียด order แต่ละอัน
    for (var order in _orders) {
      print(
        '   Order ${order.orderId}: ${order.status} (Market: ${order.marketId})',
      );
    }
  }

  // เพิ่ม method สำหรับบังคับ refresh
  Future<void> forceRefreshOrders() async {
    print('🔄 Force refreshing orders...');
    await _refreshCurrentData();
    print('✅ Force refresh completed');
  }

  // เพิ่ม method สำหรับ reconnect socket เมื่อมีปัญหา
  Future<void> reconnectSocket() async {
    print('🔄 Reconnecting socket...');
    _socketService.disconnect();
    await Future.delayed(Duration(seconds: 1));
    await initializeSocket(userId: _currentUserId, marketId: _currentMarketId);
  }

  // เพิ่ม method สำหรับ debug socket status
  void debugSocketStatus() {
    print('🔧 Socket Debug Info:');
    print('  Connected: ${_socketService.isConnected}');
    print('  Current Market ID: $_currentMarketId');
    print('  Current User ID: $_currentUserId');
    print('  Orders count: ${_orders.length}');
    print('  Socket status: ${_socketService.getConnectionStatus()}');
  }

  // Fetch single order (helper method) - ปรับปรุง
  Future<void> _fetchSingleOrder(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order_status/$orderId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('📥 Fetched single order $orderId successfully');
          // Refresh data to include the new order
          _refreshCurrentData();
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
            customerName: data['data']['customer_name'] ?? 'ไม่ระบุ',
            customerPhone: data['data']['customer_phone'] ?? 'ไม่ระบุ',
            address: data['data']['address'] ?? '',
            deliveryType: data['data']['delivery_type'] ?? '',
            paymentMethod: data['data']['payment_method'] ?? '',
            deliveryFee: _toDouble(data['data']['delivery_fee']),
            totalPrice: _toDouble(data['data']['total_price']),
            // ✅ สำคัญ
            shopStatus:
                data['shop_status'] ??
                ((data['status'] == 'preparing' ||
                        data['status'] == 'ready_for_pickup')
                    ? data['status']
                    : null),
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

  // Get pending orders (waiting for rider assignment)
  List<Order> get pendingOrders => getOrdersByStatus('rider_assigned');

  // Get accepted orders (shop confirmed, cooking)
  List<Order> get acceptedOrders => getOrdersByStatus('confirmed');

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
    print("🧹 OrderController disposed (socket not disconnected)");

    // _socketService.disconnect();
    super.dispose();
  }
}

extension OrderCopyWith on Order {
  Order copyWith({
    int? orderId,
    int? userId,
    int? marketId,
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
    String? shopStatus, // ✅ เพิ่ม shopStatus
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
      shopStatus: shopStatus ?? this.shopStatus, // ✅ เพิ่ม
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}
