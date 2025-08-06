import 'package:flutter/material.dart';

class ChatWithRider extends StatefulWidget {
  const ChatWithRider({Key? key}) : super(key: key);

  @override
  State<ChatWithRider> createState() => _ChatWithRiderState();
}

class _ChatWithRiderState extends State<ChatWithRider> {
  bool isOnline = true; // สถานะออนไลน์ของไรเดอร์

  void _showReviewDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int rating = 5;
        final TextEditingController _controller = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFE7FBD7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Column(
                children: [
                  const Text(
                    'รีวิวการส่งอาหารให้ไรเดอร์',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                        icon: Icon(
                          Icons.star,
                          color: index < rating ? Colors.amber : Colors.grey,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              content: TextField(
                controller: _controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'เขียนรีวิว...',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      print('Rating: $rating');
                      print('Review: ${_controller.text}');
                    },
                    icon: const Icon(Icons.wb_sunny_outlined),
                    label: const Text('รีวิว'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color headerGreen = const Color(0xFF3EC876);

    return Scaffold(
      appBar: AppBar(
        title: const Text('แชทกับไรเดอร์'),
        backgroundColor: headerGreen,
        actions: [IconButton(icon: const Icon(Icons.call), onPressed: () {})],
      ),
      body: Column(
        children: [
          // หัวแชทของไรเดอร์
          Container(
            width: double.infinity,
            color: headerGreen,
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: AssetImage('assets/status_img/rider.png'),
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ไรเดอร์: คุณสมชาย',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: isOnline ? Colors.green : Colors.red,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOnline ? 'ออนไลน์' : 'ออฟไลน์',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // เนื้อหาแชท
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('เลขที่สั่งซื้อ A-1234456789'),
                const SizedBox(height: 10),
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    border: Border.all(),
                    image: const DecorationImage(
                      image: AssetImage('assets/png/login-background.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _showReviewDialog,
                  icon: const Icon(Icons.wb_sunny_outlined),
                  label: const Text('รีวิวการจัดส่งอาหาร สำหรับไรเดอร์'),
                ),
                const SizedBox(height: 10),
                const Text('ขอบคุณครับ ไรเดอร์ เดี๋ยวจะรีวิวให้นะครับ'),
              ],
            ),
          ),
          const Spacer(),

          // ช่องพิมพ์ข้อความ
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'พิมพ์ข้อความ...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.send, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
