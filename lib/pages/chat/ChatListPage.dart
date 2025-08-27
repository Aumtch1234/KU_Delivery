import 'package:delivery/pages/chat/ChatPage.dart';
import 'package:flutter/material.dart';

// Mock Data
List<ChatMessage> mockChatData = [
  ChatMessage(
    id: '1',
    senderName: 'Angela Garrett',
    message: 'Hello, how are you?',
    time: '12 min',
    avatarUrl:
        'https://images.unsplash.com/photo-1494790108755-2616b612b77c?w=150&h=150&fit=crop&crop=face',
    isOnline: true,
    unreadCount: 3,
  ),
  ChatMessage(
    id: '2',
    senderName: 'Tammy Hayes',
    message: 'Thanks pretty wild on you.',
    time: '5:54 PM',
    avatarUrl:
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
    isOnline: false,
    unreadCount: 0,
    isLastMessageFromMe: true,
  ),
  ChatMessage(
    id: '3',
    senderName: 'Leon Hunt',
    message: 'I really love that!',
    time: '6:14 PM',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
    isOnline: false,
    unreadCount: 0,
    isLastMessageFromMe: true,
  ),
  ChatMessage(
    id: '4',
    senderName: 'Sandra Aguilar',
    message: 'You interest the movie...',
    time: '10:54 PM',
    avatarUrl:
        'https://images.unsplash.com/photo-1544725176-7c40e5a71c5e?w=150&h=150&fit=crop&crop=face',
    isOnline: true,
    unreadCount: 0,
  ),
  ChatMessage(
    id: '5',
    senderName: 'Marie Fowler',
    message: 'Thank you so much!',
    time: 'Sun',
    avatarUrl:
        'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&h=150&fit=crop&crop=face',
    isOnline: false,
    unreadCount: 1,
  ),
  ChatMessage(
    id: '6',
    senderName: 'Cynthia Medina',
    message: 'Hey, what are you favorites...',
    time: 'Oct 23',
    avatarUrl:
        'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&h=150&fit=crop&crop=face',
    isOnline: false,
    unreadCount: 0,
  ),
];

// Main Chat List Screen
class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.grey[600]),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar - ปรับแต่งให้เหมือนรูปที่ส่งมา
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5), // สีพื้นหลังของแทบบาร์
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[700],
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Color(0xFF4CAF50), // สีเขียวเหมือนในรูป
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
                    child: Text(
                      'ที่ยังไม่ได้อ่าน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: mockChatData.length,
                itemBuilder: (context, index) {
                  final chat = mockChatData[index];
                  return ChatListItem(
                    chat: chat,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(chat: chat),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Chat List Item Widget
class ChatListItem extends StatelessWidget {
  final ChatMessage chat;
  final VoidCallback onTap;

  const ChatListItem({Key? key, required this.chat, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(chat.avatarUrl),
            ),
            if (chat.isOnline)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          chat.senderName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            chat.message,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              chat.time,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            if (chat.unreadCount > 0) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  chat.unreadCount.toString(),
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
