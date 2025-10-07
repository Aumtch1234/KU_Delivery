// controllers/customer_chat_controller.dart (Fixed Real-time Update)
import 'dart:async';
import 'dart:convert';

import 'package:delivery/APIs/Chat/Utils/shared_preferences_helper.dart';
import 'package:delivery/APIs/Chat/models/ChatCustomerModel.dart';
import 'package:delivery/APIs/Services/ChatService.dart';
import 'package:flutter/material.dart';

class CustomerChatController extends ChangeNotifier {
  final CustomerChatService _chatService = CustomerChatService();
  CustomerChatService get chatService => _chatService;

  // State variables
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = false;
  bool _isConnected = false;
  int _unreadCount = 0;

  // User info (สำหรับลูกค้า)
  int? _userId;
  String? _userName;
  String? _userPhoto;
  String? _userPhone;

  // Getters
  List<ChatRoom> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  int get unreadCount => _unreadCount;
  int? get userId => _userId;
  String? get userName => _userName;
  String? get userPhoto => _userPhoto;

  // ✅ เพิ่ม stream subscriptions เพื่อจัดการ memory
  StreamSubscription? _msgSub, _roomSub, _readSub, _connectionSub;

  CustomerChatController() {
    _initializeUserInfo();
    _setupConnectionListener();
    _setupRealtimeListeners();
  }

  Future<void> initializeUserInfoIfNeeded() async {
    if (_userId == null) {
      await _initializeUserInfo();
    }
  }

  Future<void> _initializeUserInfo() async {
    try {
      final prefs = await SharedPreferencesHelper.getInstance();

      // Debug shared prefs
      final allKeys = prefs.getKeys();
      print("🔎 Keys in SharedPreferences:");
      for (var key in allKeys) {
        print("👉 $key = ${prefs.get(key)}");
      }

      // ✅ 1) โหลด user JSON
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = jsonDecode(userString);
        _userId = userData['user_id'];
        _userName = userData['display_name'] ?? userData['name'];
        _userPhoto = userData['photo_url'];
        _userPhone = userData['phone'];

        print("✅ Loaded customer user info from JSON");
        print("👤 User ID: $_userId");
        print("👤 User Name: $_userName");
        print("🖼️ User Photo: $_userPhoto");
        print("📞 User Phone: $_userPhone");
      } else {
        print("⚠️ user data not found!");
      }

      // ✅ 2) โหลด JWT token (string ไม่ต้อง decode)
      final token = prefs.getString('token');
      if (token != null) {
        _chatService.setAuthToken(token);
        print("🔑 JWT Token loaded: $token");
      } else {
        print("⚠️ JWT Token not found in SharedPreferences");
      }

      // ✅ 3) เชื่อมต่อ socket + โหลดแชท (ถ้ามี user_id)
      if (_userId != null) {
        await connectToChat();
        await loadChatRooms();
        await updateUnreadCount();
      } else {
        print("⚠️ User ID is null → ยังไม่ได้ login หรือไม่มีข้อมูล user");
      }
    } catch (e, stack) {
      debugPrint('❌ Error initializing user info: $e');
      debugPrint(stack.toString());
    }
  }

  void _setupConnectionListener() {
    // ✅ Cancel existing subscription before creating new one
    _connectionSub?.cancel();

    _connectionSub = _chatService.connectionStream.listen((connected) async {
      _isConnected = connected;
      notifyListeners();

      print('🔌 Connection status changed: $connected');

      // ✅ โหลดแชทเมื่อเชื่อมต่อสำเร็จ
      if (connected && _userId != null) {
        loadChatRooms();
      }
      if (connected && _userId != null) {
        await loadChatRooms();
        // 🆕 join อีกครั้งเมื่อ reconnect สำเร็จ
        for (final room in _chatRooms) {
          if (room.roomId != null) {
            await _chatService.joinRoom(room.roomId!);
          }
        }
      }
    });
  }

  // เชื่อมต่อ socket
  Future<void> connectToChat() async {
    if (_userId == null) {
      print('❌ Cannot connect to chat: User ID is null');
      return;
    }

    try {
      print('🔌 Connecting to chat for user $_userId');
      await _chatService.connectSocket(_userId!);
      print('✅ Chat connection initiated');
    } catch (e) {
      debugPrint('❌ Error connecting to chat: $e');
    }
  }

  // โหลดห้องแชท
  Future<void> loadChatRooms() async {
    if (_userId == null) {
      print('❌ Cannot load chat rooms: User ID is null');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      print('📋 Loading chat rooms for user $_userId');
      final rooms = await _chatService.getChatRooms();

      rooms.sort((a, b) {
        final timeA = a.lastMessageTime ?? DateTime(2000);
        final timeB = b.lastMessageTime ?? DateTime(2000);
        return timeB.compareTo(timeA);
      });

      _chatRooms = rooms;

      // ✅ 🔥 Join ทุกห้องหลังโหลดเสร็จ
      for (final room in _chatRooms) {
        if (room.roomId != null) {
          await _chatService.joinRoom(room.roomId!);
          print('🏠 Joined room: ${room.roomId}');
        }
      }

      _unreadCount = rooms.fold<int>(
        0,
        (sum, room) => sum + (room.unreadCount ?? 0),
      );

      print('✅ Chat rooms loaded: ${rooms.length} rooms, $_unreadCount unread');
    } catch (e) {
      debugPrint('❌ Error loading chat rooms: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // อัปเดตจำนวน unread
  Future<void> updateUnreadCount() async {
    if (_userId == null) return;

    try {
      _unreadCount = await _chatService.getUnreadCount();
      notifyListeners();
      print('🔢 Updated unread count: $_unreadCount');
    } catch (e) {
      debugPrint('❌ Error updating unread count: $e');
    }
  }

  void _setupRealtimeListeners() {
    // ✅ Cancel existing subscriptions before creating new ones
    _msgSub?.cancel();
    _roomSub?.cancel();
    _readSub?.cancel();

    // ✅ Message stream listener
    _msgSub = _chatService.messageStream.listen(
      (message) {
        print('📨 [CONTROLLER] New message received in room ${message.roomId}');
        print('📨 [CONTROLLER] Message text: ${message.messageText}');

        final idx = _chatRooms.indexWhere((r) => r.roomId == message.roomId);
        final isMyMessage =
            message.senderId == _userId &&
            (message.senderType == 'customer' ||
                message.senderType == 'member');

        if (idx != -1) {
          final prev = _chatRooms[idx];

          // ✅ สร้าง room ใหม่ด้วยข้อมูลล่าสุด
          final updatedRoom = prev.copyWith(
            lastMessage: message.messageText,
            messageType: message.messageType,
            lastMessageTime: message.createdAt,
            unreadCount: isMyMessage
                ? (prev.unreadCount ?? 0)
                : (prev.unreadCount ?? 0) + 1,
          );

          // ✅ ลบห้องเก่าออก
          _chatRooms.removeAt(idx);

          // ✅ เพิ่มห้องใหม่ที่ตำแหน่งบนสุด
          _chatRooms.insert(0, updatedRoom);

          // ✅ อัพเดท unread count
          if (!isMyMessage) {
            _unreadCount += 1;
          }

          // ✅ ส่งสัญญาณให้ UI อัพเดท
          notifyListeners();

          print('✅ [CONTROLLER] Chat room moved to top of list');
          print('✅ [CONTROLLER] Total unread: $_unreadCount');
        } else {
          // ถ้าไม่พบห้อง โหลดใหม่ (กันกรณีเพิ่งถูกสร้าง)
          print(
            '⚠️ [CONTROLLER] Room ${message.roomId} not found in list, reloading...',
          );
          loadChatRooms();
        }
      },
      onError: (error) {
        print('❌ [CONTROLLER] Message stream error: $error');
      },
    );

    // ✅ Room update stream listener
    _roomSub = _chatService.roomUpdateStream.listen(
      (room) {
        print('🏠 [CONTROLLER] Room update received: ${room.roomId}');

        final idx = _chatRooms.indexWhere((r) => r.roomId == room.roomId);
        if (idx == -1) {
          // ✅ ห้องใหม่ - เพิ่มที่บนสุด
          _chatRooms.insert(0, room);
          print('✅ [CONTROLLER] New room added to top of list');
        } else {
          // ✅ ห้องเดิม - อัพเดทและย้ายขึ้นบนสุด
          _chatRooms.removeAt(idx);
          _chatRooms.insert(0, room);
          print('✅ [CONTROLLER] Existing room updated and moved to top');
        }

        _unreadCount = _chatRooms.fold(0, (s, r) => s + (r.unreadCount ?? 0));
        notifyListeners();
      },
      onError: (error) {
        print('❌ [CONTROLLER] Room update stream error: $error');
      },
    );

    // ✅ Read status stream listener
    _readSub = _chatService.readStatusStream.listen(
      (data) {
        final roomId = data['roomId'] as int?;
        if (roomId == null) return;

        print('👁️ [CONTROLLER] Messages marked as read in room: $roomId');

        final idx = _chatRooms.indexWhere((r) => r.roomId == roomId);
        if (idx != -1) {
          final prev = _chatRooms[idx].unreadCount ?? 0;
          _chatRooms[idx] = _chatRooms[idx].copyWith(unreadCount: 0);
          _unreadCount = (_unreadCount - prev).clamp(0, 999);
          notifyListeners();
          print('✅ [CONTROLLER] Unread count updated: $_unreadCount');
        }
      },
      onError: (error) {
        print('❌ [CONTROLLER] Read status stream error: $error');
      },
    );

    print('✅ [CONTROLLER] All realtime listeners setup completed');
  }

  // รีเฟรช
  Future<void> refreshChatRooms() async {
    print('🔄 Refreshing chat rooms...');
    await loadChatRooms();
  }

  // เข้าแชท → unread = 0
  void markRoomAsEntered(int roomId) {
    print('👁️ Marking room as entered: $roomId');

    final index = _chatRooms.indexWhere((r) => r.roomId == roomId);
    if (index != -1) {
      final prevUnread = _chatRooms[index].unreadCount ?? 0;
      _chatRooms[index] = _chatRooms[index].copyWith(unreadCount: 0);
      _unreadCount = (_unreadCount - prevUnread).clamp(0, 999);
      notifyListeners();

      print('✅ Room marked as entered, unread count: $_unreadCount');
    }
  }

  // โทรศัพท์
  void makePhoneCall(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      debugPrint('❌ ไม่พบหมายเลขโทรศัพท์');
      return;
    }

    try {
      debugPrint('📞 กำลังโทรหา: $phoneNumber');
      // ใช้ url_launcher
      // launch('tel:$phoneNumber');
    } catch (e) {
      debugPrint('❌ ไม่สามารถโทรศัพท์ได้: $e');
    }
  }

  // helper format เวลา
  String formatLastMessageTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'เมื่อกี้นี้';
    if (diff.inHours < 1) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inDays < 1) return '${diff.inHours} ชั่วโมงที่แล้ว';
    if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // helper format ข้อความ
  String formatLastMessage(String? msg, String? type) {
    if (msg == null || msg.isEmpty) {
      return (type == 'image') ? '📷 รูปภาพ' : 'ไม่มีข้อความ';
    }
    return msg.length > 50 ? '${msg.substring(0, 50)}...' : msg;
  }

  // เปิดแชทกับไรเดอร์
  void openChatWithRider({
    required BuildContext context,
    required int roomId,
    required int orderId,
    required String riderName,
    String? riderPhoto,
    String? riderPhone,
  }) {
    print('🚀 Opening chat with rider:');
    print('  - roomId: $roomId');
    print('  - userId: $_userId');
    print('  - userType: member');

    // ✅ Mark room as entered when opening
    markRoomAsEntered(roomId);

    Navigator.pushNamed(
      context,
      '/customer-chat',
      arguments: {
        'roomId': roomId,
        'orderId': orderId,
        'partnerName': riderName,
        'partnerPhoto': riderPhoto,
        'partnerPhone': riderPhone,
        'userType': 'member', // สำหรับลูกค้าใช้ 'member'
        'userId': _userId,
        'userName': _userName,
        'userPhoto': _userPhoto,
      },
    );
  }

  // สีสถานะ order
  Color getOrderStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'waiting':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'rider_assigned':
        return Colors.amber;
      case 'going_to_shop':
        return Colors.deepOrange;
      case 'arrived_at_shop':
        return Colors.brown;
      case 'picked_up':
        return Colors.teal;
      case 'delivering':
        return Colors.indigo;
      case 'arrived_at_customer':
        return Colors.cyan;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'preparing':
        return Colors.purple;
      case 'ready_for_pickup':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String getOrderStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'waiting':
        return 'รอร้านยืนยัน';
      case 'confirmed':
        return 'ร้านยืนยันแล้ว';
      case 'rider_assigned':
        return 'รอไปรับงาน';
      case 'going_to_shop':
        return 'กำลังไปที่ร้าน';
      case 'arrived_at_shop':
        return 'ถึงร้านแล้ว';
      case 'picked_up':
        return 'รับของแล้ว';
      case 'delivering':
        return 'กำลังส่ง';
      case 'arrived_at_customer':
        return 'ถึงบ้านลูกค้า';
      case 'completed':
        return 'ส่งสำเร็จ';
      case 'cancelled':
        return 'ออเดอร์ถูกยกเลิก';
      case 'preparing':
        return 'ร้านกำลังทำอาหาร';
      case 'ready_for_pickup':
        return 'อาหารพร้อมรับ';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  // Get filtered chat rooms (สำหรับแท็บ "ที่ยังไม่ได้อ่าน")
  List<ChatRoom> get unreadChatRooms {
    return _chatRooms.where((room) => (room.unreadCount ?? 0) > 0).toList();
  }

  // Get all chat rooms (สำหรับแท็บ "ทั้งหมด")
  List<ChatRoom> get allChatRooms => _chatRooms;

  // ✅ เพิ่มการ force refresh connection
  Future<void> forceReconnect() async {
    if (_userId != null) {
      print('🔄 Force reconnecting...');
      await _chatService.disconnectSocket();
      await Future.delayed(Duration(seconds: 1));
      await _chatService.connectSocket(_userId!);
    }
  }

  // ✅ เพิ่มการตรวจสอบสถานะการเชื่อมต่อ
  bool get isSocketConnected => _chatService.isConnected;

  @override
  void dispose() {
    print('🗑️ Disposing CustomerChatController');

    // ✅ Cancel all subscriptions
    _msgSub?.cancel();
    _roomSub?.cancel();
    _readSub?.cancel();
    _connectionSub?.cancel();

    // ✅ Dispose chat service
    _chatService.dispose();

    super.dispose();
  }
}
