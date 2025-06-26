// lib/screens/home_page.dart
import 'package:delivery/pages/store/StoreMenuPage.dart';
import 'package:flutter/material.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CSC HD Food',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: Icon(Icons.tune),
                        hintText: 'Search',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Food That's\nGood For You",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'หมวดหมู่อาหาร',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'เพิ่มเติม',
                            style: TextStyle(
                              color: Color(0xFF34C759),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 80,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5.0,
                                  ),
                                  child: _buildCategory(
                                    'assets/menus/main.png',
                                    'มื้อหลัก',
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5.0,
                                  ),
                                  child: _buildCategory(
                                    'assets/menus/main.png',
                                    'ก๋วยเตี๋ยว',
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5.0,
                                  ),
                                  child: _buildCategory(
                                    'assets/menus/main.png',
                                    'เครื่องดื่ม',
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5.0,
                                  ),
                                  child: _buildCategory(
                                    'assets/menus/main.png',
                                    'ของหวาน',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ร้านค้าที่เข้าร่วม',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'เพิ่มเติม',
                            style: TextStyle(
                              color: Color(0xFF34C759),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStoreItem(context, 'ร้านข้าวมันไก่'),
                        _buildStoreItem(context, 'ร้านก๋วยเตี๋ยว'),
                        _buildStoreItem(context, 'ร้านอาหารตามสั่ง'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'เมนูแนะนำ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'เพิ่มเติม',
                            style: TextStyle(
                              color: Color(0xFF34C759),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildRecommendedMenu(
                          "ข้าวกระเพรา",
                          "ร้านอร่อย",
                          "15 นาที",
                          45,
                          'assets/menus/kai.png', // 👈 รูปไม่ซ้ำ
                          5.0, // ⭐ เพิ่ม rating
                        ),
                        _buildRecommendedMenu(
                          "ข้าวผัด",
                          "ร้านเจ๊หมี",
                          "20 นาที",
                          50,
                          'assets/menus/yam.png',
                          4.0, // ⭐ เพิ่ม rating
                        ),
                        _buildRecommendedMenu(
                          "ก๋วยเตี๋ยว",
                          "ร้านเตี๋ยวเด็ด",
                          "12 นาที",
                          40,
                          'assets/menus/yam.png',
                          4.0, // ⭐ เพิ่ม rating
                        ),
                        _buildRecommendedMenu(
                          "ข้าวหมูแดง",
                          "ร้านหมูแดง",
                          "10 นาที",
                          55,
                          'assets/menus/kai.png',
                          4.3, // ⭐ เพิ่ม rating
                        ),
                      ],
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

  Widget _buildCategory(String icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 28,
            child: Image.asset(icon, height: 30),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStoreItem(BuildContext context, String name) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreMenuPage(storeName: name),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: AssetImage('assets/menus/kai.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedMenu(
    String title,
    String shop,
    String time,
    double price,
    String imagePath,
    double rating, // ⭐ เพิ่มตัวแปร rating
  ) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 🔼 รูปภาพ + ดาว
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Image.asset(
                  imagePath,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF34C759).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.yellow, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1), // ⭐ ใช้ตัวแปรแทน
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 🔽 ชื่อเมนูอยู่กลาง
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          // 🔽 ชื่อร้านเป็นบรรทัดปกติ
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              shop,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),

          const Spacer(), // ดันข้อมูลให้อยู่ล่าง
          // ⏱️ เวลากับราคา
          Row(
            children: [
              const Icon(Icons.timer, size: 14),
              const SizedBox(width: 4),
              Text(time, style: const TextStyle(fontSize: 12)),
              const Spacer(),
              Text(
                '\$ $price.-',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
