import 'package:delivery/pages/store/foods/OrderFoodPage.dart';
import 'package:delivery/providers/basket_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:delivery/pages/store/StoreDetailPage.dart'; // ตรวจสอบให้แน่ใจว่า import ถูกต้อง

class StoreMenuPage extends StatelessWidget {
  final String storeName;

  const StoreMenuPage({Key? key, required this.storeName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // สีพื้นหลังที่ดูสบายตา
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.8),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/basket'),
              child: Consumer<BasketProvider>(
                builder: (context, basket, _) {
                  int count = basket.items.fold(
                    0,
                    (sum, e) => sum + e.quantity,
                  );
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.8),
                        child: const Icon(
                          Icons.shopping_cart,
                          color: Colors.black,
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          right: -7,
                          top: -10,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            child: Center(
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วน Header รูปภาพร้านค้า
            _buildStoreHeader(),
            // ส่วนข้อมูลร้านค้า
            _buildStoreInfo(context),
            // ส่วนรายการเมนู
            _buildMenuItems(),
          ],
        ),
      ),
    );
  }

  /// สร้าง Widget สำหรับ Header ที่มีรูปภาพ
  Widget _buildStoreHeader() {
    return Stack(
      children: [
        // รูปภาพขนาดใหญ่สำหรับส่วนหัว
        Image.asset(
          'assets/menus/kai.png', // เปลี่ยนเป็นรูปภาพจาก API จริง
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        // Gradient overlay เพื่อให้ตัวอักษรด้านบนดูชัดเจนขึ้น
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// สร้าง Widget สำหรับส่วนข้อมูลร้านค้า
  Widget _buildStoreInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoreDetailPage(storeName: storeName),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'เปิดอยู่',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.star, color: Colors.amber, size: 20),
              SizedBox(width: 4),
              Text(
                '4.5',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(' • ', style: TextStyle(fontSize: 16)),
              Text(
                '15-20 นาที',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'เมนูทั้งหมด',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// สร้าง Widget สำหรับรายการเมนู
  Widget _buildMenuItems() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5, // สามารถเปลี่ยนให้ดึงข้อมูลจริงได้
      itemBuilder: (context, index) {
        return _buildMenuItem(
          context: context,
          name: 'เมนูที่ ${index + 1}',
          description: 'คำอธิบายรายละเอียดของเมนูที่ ${index + 1}',
          price: (40 + index * 5).toDouble(),
          imagePath: 'assets/menus/kai.png',
        );
      },
    );
  }

  /// Widget สำหรับแต่ละรายการเมนู
  Widget _buildMenuItem({
    required BuildContext context,
    required String name,
    required String description,
    required double price,
    required String imagePath,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderFoodPage(
                foodName: name,
                imagePath: imagePath,
                rating: 5.0,
                storeName: storeName,
                price: price,
                description: description,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '฿${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
