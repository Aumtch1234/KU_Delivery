// CustomerChatDetailScreen - Fixed Version
import 'dart:convert';
import 'dart:async';
import 'package:delivery/APIs/Chat/ChatControllerSKAPI.dart';
import 'package:delivery/APIs/Chat/models/ChatCustomerModel.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerChatDetailScreen extends StatefulWidget {
  final int roomId;
  final int orderId;
  final String riderName;
  final String? riderPhoto;
  final String? riderPhone;

  const CustomerChatDetailScreen({
    Key? key,
    required this.roomId,
    required this.orderId,
    required this.riderName,
    this.riderPhoto,
    this.riderPhone,
  }) : super(key: key);

  @override
  _CustomerChatDetailScreenState createState() =>
      _CustomerChatDetailScreenState();
}

class _CustomerChatDetailScreenState extends State<CustomerChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late CustomerChatController _chatController;

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _lastMessageId;
  bool _hasMoreMessages = true;
  bool _isTyping = false;
  bool _isInitialized = false;

  // ✅ เพิ่ม stream subscriptions เพื่อจัดการ memory leaks
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _chatController = Provider.of<CustomerChatController>(
      context,
      listen: false,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeChat();
      _setupScrollListener();
      _isInitialized = true;
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels <= 100 &&
          !_isLoadingMore &&
          _hasMoreMessages) {
        _loadMoreMessages();
      }
    });
  }

  // ✅ แก้ไข _initializeChat ให้ทำงานแบบลำดับที่ถูกต้อง
  Future<void> _initializeChat() async {
    try {
      print('🚀 Initializing customer chat for room ${widget.roomId}');
      setState(() {
        _messages.clear();
        _lastMessageId = null;
        _hasMoreMessages = true;
        _isLoading = true;
      });

      // ✅ 1) ตรวจสอบ user info ก่อน
      await _chatController.initializeUserInfoIfNeeded();

      if (_chatController.userId == null) {
        throw Exception('User not logged in');
      }

      // ✅ 2) Connect socket และรอให้เชื่อมต่อจริงๆ
      await _chatController.chatService.connectSocket(_chatController.userId!);

      // รอให้ socket connect จริงๆ
      int attempts = 0;
      const maxAttempts = 15; // เพิ่มจำนวนครั้งที่รอ
      while (!_chatController.chatService.isConnected &&
          attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
        print(
          '⏳ Waiting for socket connection... attempt $attempts/$maxAttempts',
        );
      }

      if (_chatController.chatService.isConnected) {
        print('✅ Socket connected, proceeding to join room');

        // ✅ 3) Setup listeners ก่อน join room
        _setupRealtimeListeners();

        // ✅ 4) Join room ผ่าน socket และ API
        await _chatController.chatService.joinRoom(widget.roomId);
        await _chatController.chatService.joinChatRoomAPI(widget.roomId);

        // ✅ 5) โหลดข้อความหลังจาก join สำเร็จ
        await _loadMessages();

        // ✅ 6) Mark as read
        _chatController.chatService.markMessagesAsReadAPI(widget.roomId);
        _chatController.chatService.markAsRead();

        print('✅ Chat initialization completed successfully');
      } else {
        print('❌ Socket connection timeout after ${maxAttempts} attempts');
        _showErrorSnackBar('ไม่สามารถเชื่อมต่อได้ กรุณาลองใหม่อีกครั้ง');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing chat: $e');
      debugPrint('Stack trace: $stackTrace');
      _showErrorSnackBar('ไม่สามารถโหลดการแชทได้: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ✅ แก้ไข _setupRealtimeListeners ให้ filter และ handle ได้ถูกต้อง
  void _setupRealtimeListeners() {
    print('🔊 Setting up realtime listeners for room ${widget.roomId}');

    // Cancel existing subscriptions
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _connectionSubscription?.cancel();

    // ✅ Listen for new messages
    _messageSubscription = _chatController.chatService.messageStream.listen(
      (message) {
        print('📩 [STREAM] New message from room ${message.roomId}');
        print('📍 Current room: ${widget.roomId}');
        print('📝 Message: ${message.messageText}');
        print('👤 Sender: ${message.senderId} (${message.senderType})');

        // ✅ ตรวจสอบว่าเป็นข้อความของห้องนี้หรือไม่
        if (message.roomId?.toString() == widget.roomId.toString()) {
          // ✅ ป้องกัน duplicate messages อย่างเข้มงวด
          final isDuplicate = _messages.any((existingMessage) {
            // ตรวจสอบ message_id ก่อน
            if (existingMessage.messageId == message.messageId &&
                existingMessage.messageId != null &&
                message.messageId != null) {
              return true;
            }

            // ถ้าไม่มี message_id หรือไม่ตรงกัน ให้ตรวจสอบเนื้อหาและเวลา
            return existingMessage.messageText == message.messageText &&
                existingMessage.senderId == message.senderId &&
                existingMessage.senderType == message.senderType &&
                _isMessageTimeSimilar(
                  existingMessage.createdAt,
                  message.createdAt,
                );
          });

          if (!isDuplicate && mounted) {
            setState(() {
              _messages.add(message);
            });

            // ✅ เลื่อนไปข้อความล่าสุด
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });

            print('✅ New message added to UI successfully');

            // ✅ Mark as read ถ้าข้อความไม่ใช่ของเราเอง
            if (!_isMyMessage(message)) {
              _chatController.chatService.markAsRead();
              _chatController.chatService.markMessagesAsReadAPI(widget.roomId);
            }
          } else if (isDuplicate) {
            print('🔄 Duplicate message ignored');
          }
        } else {
          print('⚠️ [STREAM] Message ignored (not current room)');
        }
      },
      onError: (error) {
        print('❌ Message stream error: $error');
      },
    );

    // ✅ Listen for typing status
    _typingSubscription = _chatController.chatService.typingStream.listen(
      (data) {
        final roomId = data['roomId'];
        final userId = data['userId'];
        final isTyping = data['isTyping'] ?? false;

        print('⌨️ Typing event: room=$roomId, user=$userId, typing=$isTyping');

        if (roomId == widget.roomId &&
            userId != _chatController.userId &&
            mounted) {
          setState(() {
            _isTyping = isTyping;
          });

          // ✅ หยุด typing หลังจาก 3 วินาที (กันกรณี stop event หาย)
          if (isTyping) {
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _isTyping = false;
                });
              }
            });
          }
        }
      },
      onError: (error) {
        print('❌ Typing stream error: $error');
      },
    );

    // ✅ Listen for connection status
    _connectionSubscription = _chatController.chatService.connectionStream
        .listen(
          (isConnected) {
            print('🔌 Connection status changed: $isConnected');
            if (mounted) {
              setState(() {
                // Force rebuild to show connection status
              });
            }
          },
          onError: (error) {
            print('❌ Connection stream error: $error');
          },
        );

    print('✅ All realtime listeners setup completed');
  }

  // ✅ เพิ่มฟังก์ชันตรวจสอบว่าเป็นข้อความของเราหรือไม่
  bool _isMyMessage(ChatMessage message) {
    return message.senderId == _chatController.userId &&
        (message.senderType == 'customer' || message.senderType == 'member');
  }

  bool _isMessageTimeSimilar(DateTime? time1, DateTime? time2) {
    if (time1 == null || time2 == null) return false;
    return (time1.difference(time2).abs().inSeconds < 5);
  }

  // ✅ แก้ไข _loadMessages ให้ handle ได้ดีขึ้น
  Future<void> _loadMessages() async {
    try {
      print('🔍 Loading messages for room: ${widget.roomId}');

      final response = await _chatController.chatService.getChatMessages(
        widget.roomId,
        limit: 50,
      );

      print('📨 API Response success: ${response['success']}');

      if (response['success'] && mounted) {
        final List<dynamic> messagesJson = response['messages'] ?? [];
        print('📨 Raw messages count: ${messagesJson.length}');

        if (messagesJson.isNotEmpty) {
          print('📨 Sample message: ${messagesJson.first}');
        }

        final messages = <ChatMessage>[];
        for (var json in messagesJson) {
          try {
            final message = _parseMessage(json);
            messages.add(message);
          } catch (e) {
            print('❌ Error parsing message: $e');
            print('❌ Raw data: $json');
          }
        }

        // ✅ เรียงข้อความตามเวลา (เก่าสุดไปใหม่สุด)
        messages.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return -1;
          if (b.createdAt == null) return 1;
          return a.createdAt!.compareTo(b.createdAt!);
        });

        setState(() {
          _messages
            ..clear()
            ..addAll(messages);
          _hasMoreMessages = messages.length >= 50;
          if (messages.isNotEmpty) {
            _lastMessageId = messages.last.messageId?.toString();
          }
        });

        // ✅ เลื่อนไปข้อความล่าสุดหลังโหลดเสร็จ
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        print('💬 Messages loaded successfully: ${messages.length}');
      } else {
        print('❌ API response success=false or not mounted');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading messages: $e');
      debugPrint('Stack trace: $stackTrace');
      _showErrorSnackBar('ไม่สามารถโหลดข้อความได้: $e');
    }
  }

  // ✅ แก้ไข _parseMessage ให้ handle ได้หลากหลาย format
  ChatMessage _parseMessage(dynamic messageData) {
    try {
      Map<String, dynamic> data;

      if (messageData is Map) {
        data = Map<String, dynamic>.from(
          messageData.map((k, v) => MapEntry(k.toString(), v)),
        );
      } else if (messageData is String) {
        final decoded = jsonDecode(messageData);
        data = Map<String, dynamic>.from(
          decoded.map((k, v) => MapEntry(k.toString(), v)),
        );
      } else {
        throw Exception('Invalid message format: ${messageData.runtimeType}');
      }

      // ✅ Map database fields to model fields - รองรับทั้ง snake_case และ camelCase
      final mappedData = {
        'message_id':
            data['message_id']?.toString() ?? data['messageId']?.toString(),
        'room_id':
            data['room_id']?.toString() ??
            data['roomId']?.toString() ??
            widget.roomId.toString(),
        'sender_id': data['sender_id'] ?? data['senderId'],
        'sender_type':
            data['sender_type']?.toString() ?? data['senderType']?.toString(),
        'sender_name':
            data['sender_name']?.toString() ?? data['senderName']?.toString(),
        'sender_photo':
            data['sender_photo']?.toString() ?? data['senderPhoto']?.toString(),
        'message_text':
            data['message_text']?.toString() ?? data['messageText']?.toString(),
        'message_type':
            data['message_type']?.toString() ??
            data['messageType']?.toString() ??
            'text',
        'image_url':
            data['image_url']?.toString() ?? data['imageUrl']?.toString(),
        'latitude': data['latitude']?.toString(),
        'longitude': data['longitude']?.toString(),
        'is_read': data['is_read'] ?? data['isRead'] ?? false,
        'created_at':
            data['created_at']?.toString() ??
            data['createdAt']?.toString() ??
            DateTime.now().toIso8601String(),
        'updated_at':
            data['updated_at']?.toString() ??
            data['updatedAt']?.toString() ??
            data['created_at']?.toString() ??
            data['createdAt']?.toString(),
      };

      return ChatMessage.fromJson(mappedData);
    } catch (e) {
      print('⚠️ Error parsing message: $e');
      rethrow;
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _chatController.chatService.getChatMessages(
        widget.roomId,
        after: _lastMessageId,
        limit: 50,
      );

      if (response['success'] && mounted) {
        final List<dynamic> messagesJson = response['messages'] ?? [];
        final newMessages = <ChatMessage>[];

        for (var json in messagesJson) {
          try {
            final message = _parseMessage(json);
            newMessages.add(message);
          } catch (e) {
            print('❌ Error parsing message: $e');
          }
        }

        if (newMessages.isNotEmpty) {
          setState(() {
            _messages.insertAll(0, newMessages.reversed);
            _lastMessageId = newMessages.first.messageId?.toString();
            _hasMoreMessages = newMessages.length >= 50;
          });
        } else {
          setState(() {
            _hasMoreMessages = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading more messages: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  // ✅ แก้ไข _sendMessage ให้ทำงานได้เสถียร
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      print('📤 Sending message: $text');

      // ✅ Clear input และ stop typing ทันที
      final messageToSend = text;
      _messageController.clear();
      _chatController.chatService.stopTyping();

      // ✅ สร้าง request
      final request = SendMessageRequest(
        roomId: widget.roomId,
        messageText: messageToSend,
        messageType: 'text',
        senderType: 'customer',
      );

      // ✅ ส่งข้อความ - service จะจัดการ HTTP + Socket
      await _chatController.chatService.sendMessage(request);
      print('✅ Message sent successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error sending message: $e');
      debugPrint('Stack trace: $stackTrace');
      _showErrorSnackBar('ไม่สามารถส่งข้อความได้: $e');

      // ✅ คืน text กลับไปใน field ถ้าส่งไม่สำเร็จ
      if (mounted) {
        _messageController.text = text;
      }
    }
  }

  // ปรับ _sendImage ให้รับ source เป็น parameter
  Future<void> _sendImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  SizedBox(height: 16),
                  Text('กำลังส่งรูปภาพ...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        // Upload image
        final imageUrl = await _chatController.chatService.uploadImage(
          image.path,
        );

        // Close loading dialog
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        // Send message with image
        final request = SendMessageRequest(
          roomId: widget.roomId,
          messageText: null,
          messageType: 'image',
          senderType: 'customer',
          imageUrl: imageUrl,
        );

        await _chatController.chatService.sendMessage(request);
        print('✅ Image message sent successfully');
      } catch (e) {
        // Close loading dialog
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error sending image: $e');
      debugPrint('Stack trace: $stackTrace');
      _showErrorSnackBar('ไม่สามารถส่งรูปภาพได้: $e');
    }
  }

  void _onTypingChanged(String text) {
    if (text.isNotEmpty) {
      _chatController.chatService.startTyping();
    } else {
      _chatController.chatService.stopTyping();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _makePhoneCall() async {
    if (widget.riderPhone == null || widget.riderPhone!.isEmpty) {
      _showErrorSnackBar('ไม่พบหมายเลขโทรศัพท์');
      return;
    }

    try {
      final uri = Uri.parse('tel:${widget.riderPhone}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorSnackBar('ไม่สามารถโทรศัพท์ได้');
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการโทรศัพท์');
    }
  }

  @override
  void dispose() {
    // ✅ Cancel all subscriptions
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _connectionSubscription?.cancel();

    // ✅ Dispose controllers
    _messageController.dispose();
    _scrollController.dispose();

    // ✅ Clean up chat service
    _chatController.chatService.stopTyping();
    _chatController.chatService.leaveRoom();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF7F7F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.riderName,
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF4CAF50)),
              SizedBox(height: 16),
              Text('กำลังโหลดการแชท...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  widget.riderPhoto != null && widget.riderPhoto!.isNotEmpty
                  ? NetworkImage(widget.riderPhoto!)
                  : null,
              child: widget.riderPhoto == null || widget.riderPhoto!.isEmpty
                  ? Icon(Icons.person, color: Colors.white, size: 24)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.riderName,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Consumer<CustomerChatController>(
                    builder: (context, controller, child) {
                      return Text(
                        controller.isConnected
                            ? 'ออนไลน์'
                            : 'กำลังเชื่อมต่อ...',
                        style: TextStyle(
                          color: controller.isConnected
                              ? Colors.green
                              : Colors.orange[600],
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.riderPhone != null && widget.riderPhone!.isNotEmpty)
            IconButton(
              icon: Icon(Icons.call, color: Color(0xFF4CAF50)),
              onPressed: _makePhoneCall,
            ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status Banner
          Consumer<CustomerChatController>(
            builder: (context, controller, child) {
              if (!controller.isConnected) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  color: Colors.orange.shade100,
                  child: Text(
                    'กำลังเชื่อมต่อ...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),

          // Messages List
          Expanded(
            child: Column(
              children: [
                // Load more indicator
                if (_isLoadingMore)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  ),

                // Messages
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'ยังไม่มีข้อความ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'เริ่มต้นการสนทนากับ ${widget.riderName}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(16),
                          itemCount: _messages.length + (_isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length) {
                              // Typing indicator
                              return _buildTypingIndicator();
                            }

                            final message = _messages[index];
                            final isMe = _isMyMessage(message);

                            return Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: _buildMessageBubble(message, isMe),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Message Input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                // กล้องอยู่ซ้ายสุด
                IconButton(
                  icon: Icon(Icons.camera_alt, color: Colors.grey[600]),
                  onPressed: () => _sendImage(ImageSource.camera),
                  tooltip: 'ถ่ายภาพ',
                ),
                IconButton(
                  icon: Icon(Icons.photo_library, color: Colors.grey[600]),
                  onPressed: () => _sendImage(ImageSource.gallery),
                  tooltip: 'เลือกจากแกลเลอรี่',
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      onChanged: _onTypingChanged,
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความ...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[500]),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    final messageText = message.messageText ?? '';
    final isImage = message.messageType == 'image';
    final safeImageUrl = message.imageUrl?.isNotEmpty == true
        ? message.imageUrl!
        : '';

    // เฉพาะฝั่งไรเดอร์เท่านั้นที่แสดงโปรไฟล์
    final showRiderAvatar = !isMe;
    final photoUrl = showRiderAvatar && message.senderPhoto?.isNotEmpty == true
        ? message.senderPhoto!
        : null;

    Widget avatar = showRiderAvatar
        ? Container(
            margin: EdgeInsets.only(
              bottom: 0,
              right: 0,
            ), // ขยับขึ้นขนานกับกล่องข้อความ
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Icon(Icons.person, color: Colors.white, size: 20)
                  : null,
            ),
          )
        : SizedBox(width: 0);

    return Container(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center, // ขนานกับกล่องข้อความ
        children: isMe
            ? [
                // ฝั่งเรา: ไม่มี avatar
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.65,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF4CAF50),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: isImage
                            ? (safeImageUrl.isNotEmpty
                                  ? _buildImageMessage(safeImageUrl)
                                  : Text(
                                      'ไม่พบรูปภาพ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ))
                            : Text(
                                messageText.isNotEmpty
                                    ? messageText
                                    : '(ไม่มีข้อความ)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatMessageTime(message.createdAt),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ]
            : [
                avatar,
                SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.65,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: isImage
                            ? (safeImageUrl.isNotEmpty
                                  ? _buildImageMessage(safeImageUrl)
                                  : Text(
                                      'ไม่พบรูปภาพ',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ))
                            : Text(
                                messageText.isNotEmpty
                                    ? messageText
                                    : '(ไม่มีข้อความ)',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatMessageTime(message.createdAt),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildImageMessage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 200,
        height: 150,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 200,
            height: 150,
            color: Colors.grey[300],
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 150,
            color: Colors.grey[300],
            child: Icon(Icons.error, color: Colors.grey[600]),
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.riderName} กำลังพิมพ์',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'เมื่อวาน ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
