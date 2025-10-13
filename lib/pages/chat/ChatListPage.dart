// pages/chat/customer_chat_list_screen.dart (Fixed)
import 'dart:async'; // ✅ เพิ่ม import สำหรับ StreamSubscription
import 'package:delivery/APIs/Chat/ChatControllerSKAPI.dart';
import 'package:delivery/APIs/Chat/models/ChatCustomerModel.dart';
import 'package:delivery/pages/chat/ChatPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomerChatListScreen extends StatefulWidget {
  @override
  _CustomerChatListScreenState createState() => _CustomerChatListScreenState();
}

class _CustomerChatListScreenState extends State<CustomerChatListScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late CustomerChatController _chatController;
  bool _isInitialized = false;

  // ✅ เพิ่ม StreamSubscription สำหรับฟังข้อความใหม่
  StreamSubscription? _messageSubscription;
  StreamSubscription? _roomUpdateSubscription;

  StreamSubscription? _messageSub;
  StreamSubscription? _roomSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chatController = Provider.of<CustomerChatController>(
      context,
      listen: false,
    );

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeChat();
      _setupRealtimeListeners(); // ✅ เรียกหลัง init เสร็จ
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // ✅ โหลดข้อมูลใหม่เมื่อกลับมาที่แอพ
    if (state == AppLifecycleState.resumed && _isInitialized) {
      print('🔄 App resumed, refreshing chat rooms');
      _chatController.refreshChatRooms();
    }
  }

  // ✅ เพิ่ม method สำหรับฟัง real-time events
  void _setupRealtimeListeners() {
    print('🎧 Setting up real-time listeners for chat list');

    _messageSubscription?.cancel();
    _roomUpdateSubscription?.cancel();

    Timer? _refreshTimer;

    _messageSubscription = _chatController.chatService.messageStream.listen((
      message,
    ) async {
      print('💬 [CHAT_LIST] New message received: ${message.messageText}');

      // ✅ อัปเดตข้อมูลทันทีใน allChatRooms โดยไม่รอ unread
      final roomIndex = _chatController.allChatRooms.indexWhere(
        (r) => r.roomId == message.roomId,
      );
      if (roomIndex != -1) {
        final oldRoom = _chatController.allChatRooms[roomIndex];
        _chatController.allChatRooms[roomIndex] = oldRoom.copyWith(
          lastMessage: message.messageText,
          lastMessageTime: DateTime.now(),
          unreadCount: oldRoom.unreadCount, // ✅ คงค่า unread เดิมไว้
        );
      }

      // ✅ บังคับ UI อัปเดตทันที
      if (mounted) setState(() {});

      // ✅ ค่อย refresh จาก API ทีหลัง (เพื่อ sync ข้อมูลเต็ม)
      Future.delayed(Duration(milliseconds: 500), () async {
        await _chatController.refreshChatRooms();
        if (mounted) setState(() {});
      });
    });

    _roomUpdateSubscription = _chatController.chatService.roomUpdateStream
        .listen((room) async {
          print('🏠 [CHAT_LIST] Room updated: ${room.roomId}');
          await _chatController.refreshChatRooms();
          if (mounted) setState(() {});
        });
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) {
      print('🔁 Already initialized, just refreshing rooms');
      await _chatController.refreshChatRooms();
      return;
    }

    try {
      print('🚀 Initializing chat list screen');
      await _chatController.initializeUserInfoIfNeeded();

      if (_chatController.isSocketConnected) {
        await _chatController.loadChatRooms();

        // 🆕 join ห้องทั้งหมดอีกครั้งเพื่อความชัวร์
        for (final room in _chatController.allChatRooms) {
          if (room.roomId != null) {
            await _chatController.chatService.joinRoom(room.roomId!);
            print('🏠 [UI] Joined room: ${room.roomId}');
          }
        }
      } else {
        await Future.delayed(Duration(seconds: 1));
        if (_chatController.isSocketConnected) {
          await _chatController.loadChatRooms();
        }
      }

      _isInitialized = true;
      print('✅ Chat list screen initialized');
    } catch (e) {
      print('❌ Error initializing chat: $e');
    }
  }

  @override
  void dispose() {
    print('🗑️ Disposing chat list screen');

    // ✅ Cancel stream subscriptions
    _messageSubscription?.cancel();
    _roomUpdateSubscription?.cancel();

    // ✅ Leave all rooms เมื่อออกจากหน้า
    _chatController.chatService.leaveRoom();

    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _messageSub?.cancel();
    _roomSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'แชท',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // ✅ เพิ่มปุ่ม reconnect เมื่อ socket หลุด
          Consumer<CustomerChatController>(
            builder: (context, controller, child) {
              if (!controller.isConnected) {
                return IconButton(
                  icon: Icon(Icons.refresh, color: Colors.orange),
                  onPressed: () => controller.forceReconnect(),
                  tooltip: 'เชื่อมต่อใหม่',
                );
              }
              return SizedBox.shrink();
            },
          ),
          IconButton(
            icon: Icon(Icons.search, color: Colors.grey[600]),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: Consumer<CustomerChatController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              // ✅ Connection Status - แสดงสถานะการเชื่อมต่อ
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: controller.isConnected ? 0 : 40,
                child: !controller.isConnected
                    ? Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        color: Colors.orange.shade100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.orange.shade800,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'กำลังเชื่อมต่อ...',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SizedBox.shrink(),
              ),

              // Tab Bar
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[700],
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: EdgeInsets.all(4),
                    labelPadding: EdgeInsets.zero,
                    tabs: [
                      Container(
                        height: 40,
                        alignment: Alignment.center,
                        child: Text(
                          'ทั้งหมด',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        height: 40,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ที่ยังไม่ได้อ่าน',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (controller.unreadCount > 0) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  controller.unreadCount > 99
                                      ? '99+'
                                      : '${controller.unreadCount}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Chat List
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: ทั้งหมด
                      _buildChatList(controller.allChatRooms),

                      // Tab 2: ที่ยังไม่ได้อ่าน
                      _buildChatList(controller.unreadChatRooms),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatList(List<ChatRoom> rooms) {
    return Consumer<CustomerChatController>(
      builder: (context, controller, child) {
        if (controller.isLoading && rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF4CAF50)),
                SizedBox(height: 16),
                Text(
                  'กำลังโหลดแชท...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (rooms.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'ยังไม่มีการแชท',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'การแชทจะปรากฏที่นี่เมื่อคุณสั่งอาหาร',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  // ✅ เพิ่มปุ่มรีเฟรชเมื่อไม่มีแชท
                  ElevatedButton.icon(
                    onPressed: () => controller.refreshChatRooms(),
                    icon: Icon(Icons.refresh),
                    label: Text('รีเฟรช'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshChatRooms(),
          color: Color(0xFF4CAF50),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return ChatRoomItem(
                room: room,
                controller: controller,
                onTap: () => _openChat(room),
              );
            },
          ),
        );
      },
    );
  }

  void _openChat(ChatRoom room) async {
    try {
      print('🚀 Opening chat room ${room.roomId}');

      // ✅ 1. Join room socket ก่อนเข้าแชท
      if (_chatController.isSocketConnected) {
        await _chatController.chatService.joinRoom(room.roomId!);
        print('✅ Joined room ${room.roomId} via socket');
      } else {
        print('⚠️ Socket not connected, joining via API only');
      }

      // ✅ 2. Mark room as entered ก่อนเข้า
      _chatController.markRoomAsEntered(room.roomId!);

      // ✅ 3. เข้าไปหน้าแชท
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomerChatDetailScreen(
            roomId: room.roomId!,
            orderId: room.orderId!,
            riderName: room.riderName ?? 'ไรเดอร์',
            riderPhoto: room.riderPhoto,
          ),
        ),
      );

      // ✅ 4. เมื่อกลับมา THEN refresh + join ใหม่ + ตั้ง listener
      print('🔄 Returned from chat room, refreshing list');
      await _chatController.refreshChatRooms();

      // 🏠 join ทุกห้องใหม่ก่อน
      for (final room in _chatController.allChatRooms) {
        if (room.roomId != null) {
          await _chatController.chatService.joinRoom(room.roomId!);
          print('🏠 [UI] Rejoined room: ${room.roomId}');
        }
      }

      // ✅ ค่อยตั้ง listener หลัง joinRoom เสร็จ
      _setupRealtimeListeners();
    } catch (e) {
      print('❌ Error opening chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเปิดแชทได้: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class ChatRoomItem extends StatelessWidget {
  final ChatRoom room;
  final CustomerChatController controller;
  final VoidCallback onTap;

  const ChatRoomItem({
    Key? key,
    required this.room,
    required this.controller,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  room.riderPhoto != null && room.riderPhoto!.isNotEmpty
                  ? NetworkImage(room.riderPhoto!)
                  : null,
              child: room.riderPhoto == null || room.riderPhoto!.isEmpty
                  ? Icon(Icons.person, color: Colors.white, size: 30)
                  : null,
            ),
            // ✅ Online indicator (ถ้า socket เชื่อมต่อ)
            if (controller.isConnected)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                room.riderName ?? 'ไรเดอร์',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (room.orderStatus != null)
              Flexible(
                child: Container(
                  margin: EdgeInsets.only(left: 8),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: controller
                        .getOrderStatusColor(room.orderStatus)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.getOrderStatusText(room.orderStatus),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: controller.getOrderStatusColor(room.orderStatus),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.formatLastMessage(
                  room.lastMessage,
                  room.messageType,
                ),
                style: TextStyle(
                  color: (room.unreadCount ?? 0) > 0
                      ? Colors.black87
                      : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: (room.unreadCount ?? 0) > 0
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (room.totalAmount != null)
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    'ยอดรวม ฿${room.totalAmount!.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              controller.formatLastMessageTime(room.lastMessageTime),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: (room.unreadCount ?? 0) > 0
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            if ((room.unreadCount ?? 0) > 0) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.all(6),
                constraints: BoxConstraints(minWidth: 24),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  room.unreadCount! > 99 ? '99+' : room.unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
