// pages/chat/customer_chat_list_screen.dart
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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CustomerChatController _chatController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chatController = Provider.of<CustomerChatController>(
      context,
      listen: false,
    );

    // Initialize และโหลดข้อมูล
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    try {
      await _chatController.initializeUserInfoIfNeeded();
    } catch (e) {
      print('Error initializing chat: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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
              // Connection Status
              if (!controller.isConnected)
                Container(
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
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          );
        }

        if (rooms.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, // ✅ ย่อให้เท่ากับขนาด children
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

  void _openChat(ChatRoom room) {
    // Mark room as entered to clear unread count
    _chatController.markRoomAsEntered(room.roomId!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerChatDetailScreen(
          roomId: room.roomId!,
          orderId: room.orderId!,
          riderName: room.riderName ?? 'ไรเดอร์',
          riderPhoto: room.riderPhoto,
          riderPhone: null, // Add rider phone if available
        ),
      ),
    );
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
        leading: CircleAvatar(
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
                overflow: TextOverflow.ellipsis, // ✅ ป้องกันข้อความยาวเกิน
                maxLines: 1,
              ),
            ),
            if (room.orderStatus != null)
              Flexible(
                // ✅ ใช้ Flexible แทน Container ปกติ
                child: Container(
                  margin: EdgeInsets.only(left: 8), // ✅ เว้นระยะห่างเล็กน้อย
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
                    overflow: TextOverflow.ellipsis, // ✅ กันข้อความสถานะยาวเกิน
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
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (room.totalAmount != null)
                Text(
                  'ยอดรวม ฿${room.totalAmount!.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            if ((room.unreadCount ?? 0) > 0) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  room.unreadCount! > 99 ? '99+' : room.unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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
