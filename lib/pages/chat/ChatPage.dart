import 'package:flutter/material.dart';


class ChatMessage {
  final String id;
  final String senderName;
  final String message;
  final String time;
  final String avatarUrl;
  final bool isOnline;
  final int unreadCount;
  final bool isLastMessageFromMe;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.message,
    required this.time,
    required this.avatarUrl,
    this.isOnline = false,
    this.unreadCount = 0,
    this.isLastMessageFromMe = false,
  });
}

// Mock Data
List<ChatMessage> mockChatData = [
  ChatMessage(
    id: '1',
    senderName: 'Angela Garrett',
    message: 'Hello, how are you?',
    time: '12 min',
    avatarUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b77c?w=150&h=150&fit=crop&crop=face',
    isOnline: true,
    unreadCount: 3,
  ),
  ChatMessage(
    id: '2',
    senderName: 'Tammy Hayes',
    message: 'Thanks pretty wild on you.',
    time: '5:54 PM',
    avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
    isOnline: false,
    unreadCount: 0,
    isLastMessageFromMe: true,
  ),
  ChatMessage(
    id: '3',
    senderName: 'Leon Hunt',
    message: 'I really love that!',
    time: '6:14 PM',
    avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
    isOnline: false,
    unreadCount: 0,
    isLastMessageFromMe: true,
  ),
  ChatMessage(
    id: '4',
    senderName: 'Sandra Aguilar',
    message: 'You interest the movie...',
    time: '10:54 PM',
    avatarUrl: 'https://images.unsplash.com/photo-1544725176-7c40e5a71c5e?w=150&h=150&fit=crop&crop=face',
    isOnline: true,
    unreadCount: 0,
  ),
  ChatMessage(
    id: '5',
    senderName: 'Marie Fowler',
    message: 'Thank you so much!',
    time: 'Sun',
    avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&h=150&fit=crop&crop=face',
    isOnline: false,
    unreadCount: 1,
  ),
  ChatMessage(
    id: '6',
    senderName: 'Cynthia Medina',
    message: 'Hey, what are you favorites...',
    time: 'Oct 23',
    avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&h=150&fit=crop&crop=face',
    isOnline: false,
    unreadCount: 0,
  ),
];

class ChatDetailScreen extends StatelessWidget {
  final ChatMessage chat;

  const ChatDetailScreen({Key? key, required this.chat}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              backgroundImage: NetworkImage(chat.avatarUrl),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.senderName,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    chat.isOnline ? 'Online' : 'Last seen recently',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Sample messages
                  ChatBubble(
                    message: "Hi Saif, How are you doing?\nYou are so cute.",
                    isMe: false,
                    time: "18:03",
                  ),
                  SizedBox(height: 16),
                  ChatBubble(
                    message: "Yoo..! I am doing great.\nOwww Leon Thanks.",
                    isMe: true,
                    time: "18:05",
                  ),
                  SizedBox(height: 16),
                  // Photo message
                  Container(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 200,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&h=200&fit=crop'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "18:10 ✓✓",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ChatBubble(
                    message: "😂😂😂 You so smart boy.\nwill you be my bf?",
                    isMe: false,
                    time: "18:13",
                  ),
                  SizedBox(height: 16),
                  ChatBubble(
                    message: "Yeah!",
                    isMe: true,
                    time: "18:14",
                  ),
                ],
              ),
            ),
          ),
          
          // Message input
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
                IconButton(
                  icon: Icon(Icons.mic, color: Colors.grey[600]),
                  onPressed: () {},
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Type something',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt, color: Colors.grey[600]),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.green),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// Chat Bubble Widget
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String time;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? Colors.green : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
                bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
              ),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            isMe ? "$time ✓✓" : time,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}