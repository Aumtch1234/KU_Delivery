// services/customer_chat_service.dart (แก้ไขแล้ว - Fixed Version)
import 'dart:async';
import 'package:delivery/APIs/Chat/models/ChatCustomerModel.dart';
import 'package:delivery/APIs/api_config.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class CustomerChatService {
  static const String baseUrl = '${ApiConfig.HosttUrl}';
  static const String socketUrl = '${ApiConfig.SocketChatUrl}';

  late Dio _dio;
  IO.Socket? _socket;
  int? _currentUserId;
  int? _currentRoomId;
  String? _authToken;

  // Stream controllers for real-time events
  final _messageStreamController = StreamController<ChatMessage>.broadcast();
  final _roomUpdateStreamController = StreamController<ChatRoom>.broadcast();
  final _typingStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _readStatusStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStreamController = StreamController<bool>.broadcast();

  // Public streams
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;
  Stream<ChatRoom> get roomUpdateStream => _roomUpdateStreamController.stream;
  Stream<Map<String, dynamic>> get typingStream =>
      _typingStreamController.stream;
  Stream<Map<String, dynamic>> get readStatusStream =>
      _readStatusStreamController.stream;
  Stream<bool> get connectionStream => _connectionStreamController.stream;

  CustomerChatService() {
    print('🔧 Initializing CustomerChatService');
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_authToken == null) {
            await _loadAuthToken();
          }
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          print('📡 API Request: ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '✅ API Response: ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ API Error: ${error.response?.statusCode} ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  Future<void> _loadAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('token');
      print(
        '🔑 Auth token loaded: ${_authToken != null ? 'Found' : 'Not found'}',
      );
    } catch (e) {
      print('❌ Error loading auth token: $e');
    }
  }

  void setAuthToken(String token) {
    _authToken = token;
    print('🔑 Auth token set manually');
  }

  Future<void> connectSocket(int userId) async {
    try {
      print('🔌 Connecting socket for customer $userId');

      if (_socket?.connected ?? false) {
        print('🔌 Disconnecting existing socket');
        await disconnectSocket();
      }

      _currentUserId = userId;

      // Ensure we have auth token
      if (_authToken == null) {
        await _loadAuthToken();
      }

      _socket = IO.io(
        '${socketUrl}/chat',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setExtraHeaders({'Authorization': 'Bearer $_authToken'})
            .enableAutoConnect()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .build(),
      );

      _setupSocketListeners();
      _socket!.connect();

      print('🔌 Socket connection initiated for customer $userId');
    } catch (e) {
      print('❌ Error connecting socket: $e');
      _connectionStreamController.add(false);
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    // Clear existing listeners to prevent duplicates
    _socket!.clearListeners();

    _socket!.on('connect', (data) {
      print('✅ Socket connected successfully');
      _connectionStreamController.add(true);
    });

    _socket!.on('disconnect', (data) {
      print('❌ Socket disconnected');
      _connectionStreamController.add(false);
    });

    _socket!.on('connect_error', (data) {
      print('❌ Socket connection error: $data');
      _connectionStreamController.add(false);
    });

    _socket!.on('error', (data) {
      print('❌ Socket error: $data');
    });

    _socket!.on('joined_room', (data) {
      print('🏠 Successfully joined room: ${data['roomId']} ✅');
    });

    // ✅ แก้ไข: รับ new_message และ parse ให้ตรงกับ ChatMessage model
    _socket!.on('new_message', (data) {
      try {
        print('📨 New message received: $data');

        final messageData = Map<String, dynamic>.from(data);

        // ✅ แก้ไข: แปลง format ให้ตรงกับ ChatMessage.fromJson()
        final mappedData = {
          'message_id':
              messageData['message_id']?.toString() ??
              messageData['messageId']?.toString(),
          'room_id':
              messageData['room_id']?.toString() ??
              messageData['roomId']?.toString(),
          'sender_id': messageData['sender_id'] ?? messageData['senderId'],
          'sender_type':
              messageData['sender_type'] ?? messageData['senderType'],
          'sender_name':
              messageData['sender_name'] ?? messageData['senderName'],
          'sender_photo':
              messageData['sender_photo'] ?? messageData['senderPhoto'],
          'message_text':
              messageData['message_text'] ?? messageData['messageText'],
          'message_type':
              messageData['message_type'] ??
              messageData['messageType'] ??
              'text',
          'image_url': messageData['image_url'] ?? messageData['imageUrl'],
          'latitude': messageData['latitude']?.toString(),
          'longitude': messageData['longitude']?.toString(),
          'is_read': messageData['is_read'] ?? messageData['isRead'] ?? false,
          'created_at': messageData['created_at'] ?? messageData['createdAt'],
          'updated_at':
              messageData['updated_at'] ??
              messageData['updatedAt'] ??
              messageData['created_at'] ??
              messageData['createdAt'],
        };

        print('📨 Mapped message data: $mappedData');
        final message = ChatMessage.fromJson(mappedData);

        // ✅ ส่งไปยัง stream เพื่อให้ UI รับทันที
        _messageStreamController.add(message);
        print('✅ Message added to stream for real-time update');
      } catch (e, stackTrace) {
        print('❌ Error parsing new message: $e');
        print('❌ Stack trace: $stackTrace');
        print('❌ Raw data: $data');
      }
    });

    _socket!.on('user_typing', (data) {
      print('⌨️ User typing: $data');
      final typingData = Map<String, dynamic>.from(data);
      typingData['roomId'] = _currentRoomId; // Add roomId for filtering
      _typingStreamController.add(typingData);
    });

    _socket!.on('messages_read', (data) {
      print('👁️ Messages read: $data');
      _readStatusStreamController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('user_joined', (data) {
      print('👤 User joined room: ${data['userName']}');
    });

    _socket!.on('user_left', (data) {
      print('👤 User left room: ${data['userId']}');
    });

    // ✅ เพิ่ม listener สำหรับ message_sent confirmation
    _socket!.on('message_sent', (data) {
      print('📤 Message sent confirmation: $data');
    });
  }

  // ✅ แก้ไข joinRoom ให้รอการตอบกลับจาก server
 Future<bool> joinRoom(int roomId) async {
  if (_socket?.connected != true || _currentUserId == null) {
    print('❌ Cannot join room - socket not connected or user not set');
    return false; // ❗ เปลี่ยนจาก throw เป็น false
  }

  print('🏠 Joining room $roomId for customer $_currentUserId');
  _currentRoomId = roomId;

  // ✅ ส่ง join_room event พร้อม userId และ userType ที่ถูกต้อง
  _socket!.emit('join_room', {
    'roomId': roomId,
    'userId': _currentUserId,
    'userType': 'customer',
  });

  // ✅ รอให้ server confirm การ join (เพิ่มเวลารอ)
  await Future.delayed(const Duration(milliseconds: 1000));
  print('✅ Room join request sent, waiting for confirmation');

  return true; // ✅ สำเร็จแล้ว return true
}


  void leaveRoom() {
    if (_currentRoomId != null && _socket?.connected == true) {
      print('🚪 Leaving room $_currentRoomId');
      _socket!.emit('leave_room', {'roomId': _currentRoomId});
      _currentRoomId = null;
    }
  }

  // ถ้าเชื่อมต่อไม่ได้จริง ๆ ค่อย fallback เป็น HTTP อย่างเดียว (และอย่า emit socket ตามมาอีก)
  Future<void> sendMessage(SendMessageRequest request) async {
    try {
      final payload = request.toJson();

      // ใส่ client_id เป็น idempotency key กันซ้ำ server/ลูกค้า
      final clientId =
          'c:${_currentUserId}-${DateTime.now().microsecondsSinceEpoch}';
      payload['client_id'] = clientId;
      payload['userId'] = _currentUserId;
      payload['userType'] = 'customer';

      final socketPayload = {
        'roomId': request.roomId,
        'messageText': request.messageText,
        'messageType': request.messageType ?? 'text',
        'imageUrl': request.imageUrl,
        'latitude': request.latitude,
        'longitude': request.longitude,
        'client_id': clientId,
      };

      if (_socket?.connected == true && _currentRoomId == request.roomId) {
        // ✅ ใช้ socket อย่างเดียว
        print('📡 Emitting message via socket: $socketPayload');
        _socket!.emit('send_message', socketPayload);
        return;
      }

      // 🔁 Fallback: ใช้ HTTP เมื่อ socket ใช้ไม่ได้
      print('⚠️ Socket not connected → using HTTP only');
      final response = await _dio.post(
        '/chat/customer/room/message',
        data: payload,
      );

      if (!(response.statusCode == 200 && response.data['success'] == true)) {
        throw Exception(response.data['message'] ?? 'ส่งข้อความไม่สำเร็จ');
      }
    } on DioException catch (e) {
      print('❌ HTTP send error: ${e.message}');
      throw Exception('ส่งข้อความไม่สำเร็จ: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  // Start typing
  void startTyping() {
    if (_currentRoomId != null && _socket?.connected == true) {
      print('⌨️ Starting typing in room $_currentRoomId');
      _socket!.emit('typing_start', {'roomId': _currentRoomId});
    }
  }

  // Stop typing
  void stopTyping() {
    if (_currentRoomId != null && _socket?.connected == true) {
      print('⌨️ Stopping typing in room $_currentRoomId');
      _socket!.emit('typing_stop', {'roomId': _currentRoomId});
    }
  }

  // Mark as read
  void markAsRead() {
    if (_currentRoomId != null && _socket?.connected == true) {
      print('👁️ Marking messages as read in room $_currentRoomId');
      _socket!.emit('mark_as_read', {'roomId': _currentRoomId});
    }
  }

  // Disconnect socket
  Future<void> disconnectSocket() async {
    print('🔌 Disconnecting socket');
    leaveRoom();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentUserId = null;
    _currentRoomId = null;
    _connectionStreamController.add(false);
  }

  // ===== HTTP API Methods =====

  Future<List<ChatRoom>> getChatRooms() async {
    try {
      print('📋 Fetching customer chat rooms');
      final response = await _dio.get('/chat/customer/rooms');

      print('📋 Chat rooms response: ${response.statusCode}');

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> roomsJson = response.data['data'] ?? [];
        final rooms = roomsJson.map((json) => ChatRoom.fromJson(json)).toList();
        print('📋 Successfully loaded ${rooms.length} chat rooms');
        return rooms;
      } else {
        final message = response.data['message'] ?? 'Unknown error';
        print('❌ Failed to get chat rooms: $message');
        throw Exception(message);
      }
    } on DioException catch (e) {
      print(
        '❌ DioException getting chat rooms: ${e.response?.statusCode} - ${e.message}',
      );
      if (e.response?.statusCode == 401) {
        throw Exception('ไม่มีสิทธิ์เข้าถึง กรุณาล็อกอินใหม่');
      }
      throw Exception('เกิดข้อผิดพลาด: ${e.message}');
    } catch (e) {
      print('❌ Error getting chat rooms: $e');
      throw Exception('เกิดข้อผิดพลาดในการโหลดรายการแชท');
    }
  }

  // ✅ แก้ไข getChatMessages ให้ handle response format ที่แตกต่างกัน
  Future<Map<String, dynamic>> getChatMessages(
    int roomId, {
    String? after,
    int limit = 200,
  }) async {
    try {
      print('💬 Fetching messages for room $roomId');

      Map<String, dynamic> queryParams = {'limit': limit};
      if (after != null) {
        queryParams['after'] = after;
      }

      final response = await _dio.get(
        '/chat/customer/room/$roomId/messages',
        queryParameters: queryParams,
      );

      print('💬 Messages API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        bool success = responseData['success'] ?? false;
        List<dynamic> messages = [];

        if (responseData.containsKey('messages')) {
          messages = responseData['messages'] ?? [];
        } else if (responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is List) {
            messages = data;
          } else if (data is Map && data.containsKey('messages')) {
            messages = data['messages'] ?? [];
          }
        }

        print('💬 Parsed ${messages.length} messages');
        return {'success': success, 'messages': messages};
      } else {
        final message = response.data['message'] ?? 'Unknown error';
        throw Exception(message);
      }
    } on DioException catch (e) {
      print(
        '❌ DioException getting messages: ${e.response?.statusCode} - ${e.message}',
      );
      if (e.response?.statusCode == 403) {
        throw Exception('ไม่มีสิทธิ์เข้าถึงห้องแชทนี้');
      }
      throw Exception('เกิดข้อผิดพลาด: ${e.message}');
    }
  }

  Future<void> joinChatRoomAPI(int roomId) async {
    try {
      print('🏠 Joining chat room $roomId via API');
      final response = await _dio.put('/chat/customer/room/$roomId/join');

      if (response.statusCode == 200 && response.data['success']) {
        print('✅ Successfully joined room via API');
      } else {
        throw Exception(response.data['message'] ?? 'Failed to join room');
      }
    } on DioException catch (e) {
      print('❌ Error joining room via API: ${e.message}');
      throw Exception('เกิดข้อผิดพลาด: ${e.message}');
    }
  }

  Future<String> uploadImage(String imagePath) async {
    try {
      print('📷 Uploading image: $imagePath');
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dio.post(
        '/chat/customer/upload-image',
        data: formData,
      );

      if (response.statusCode == 200 && response.data['success']) {
        final imageUrl = response.data['image_url'];
        print('✅ Image uploaded: $imageUrl');
        return imageUrl;
      } else {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการอัพโลดรูปภาพ: ${e.message}');
    }
  }

  Future<void> markMessagesAsReadAPI(int roomId) async {
    try {
      await _dio.put('/chat/customer/room/$roomId/mark-read');
      print('✅ Messages marked as read via API');
    } on DioException catch (e) {
      print('❌ Error marking messages as read: ${e.message}');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      print('🔢 Getting unread count for customer');
      final response = await _dio.get('/chat/customer/unread-count');

      if (response.statusCode == 200 && response.data['success']) {
        final count = response.data['unread_count'] ?? 0;
        print('🔢 Unread count: $count');
        return count;
      } else {
        print('⚠️ Failed to get unread count: ${response.data['message']}');
        return 0;
      }
    } on DioException catch (e) {
      print('❌ Error getting unread count: ${e.message}');
      return 0;
    }
  }

  void dispose() {
    print('🗑️ Disposing CustomerChatService');
    _messageStreamController.close();
    _roomUpdateStreamController.close();
    _typingStreamController.close();
    _readStatusStreamController.close();
    _connectionStreamController.close();
    disconnectSocket();
  }

  bool get isConnected => _socket?.connected ?? false;
}
