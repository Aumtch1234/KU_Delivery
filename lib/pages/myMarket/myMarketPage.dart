import 'package:delivery/APIs/FetchFoodsForMarket.dart';
import 'package:delivery/APIs/FetchMarket.dart';
import 'package:flutter/material.dart';

class Mymarketpage extends StatefulWidget {
  const Mymarketpage({Key? key}) : super(key: key);

  @override
  _MymarketpageState createState() => _MymarketpageState();
}

class _MymarketpageState extends State<Mymarketpage> {
  List<dynamic> foodList = [];
  String storeName = '';
  String storeDescription = '';
  bool isLoading = true;
  bool isOpen = true;

  @override
  void initState() {
    super.initState();
    loadMarket();
  }

  Future<void> loadMarket() async {
    final market = await fetchMyMarket(); // Map<String, dynamic>?
    final foods = await FetchFoodsForMarket(); // ดึงเมนูของร้านเจ้าของ

    if (market != null && foods != null) {
      setState(() {
        storeName = market['shop_name'] ?? 'ไม่มีชื่อร้าน';
        storeDescription = market['shop_description'] ?? 'ไม่มีคำอธิบายร้าน';
        foodList = foods;
        isLoading = false;
      });
    } else {
      setState(() {
        storeName = 'ไม่พบข้อมูลร้านค้า';
        storeDescription = '';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF34C759),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/addFood');
              if (result == true) {
                await loadMarket(); // โหลดข้อมูลเมนูใหม่หลังเพิ่มเมนูเสร็จ
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Image.asset(
                        'assets/menus/kai.png', // อาจเปลี่ยนเป็น market['shop_logo_url']
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ข้อมูลร้าน
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  storeName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  storeDescription,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    Text(
                                      '4.5',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(' • ', style: TextStyle(fontSize: 16)),
                                    Text(
                                      '15-20 นาที',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isOpen = !isOpen;
                                });
                                // TODO: ส่ง API เปลี่ยนสถานะร้าน
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isOpen
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isOpen ? 'เปิดอยู่' : 'ปิดอยู่',
                                  style: TextStyle(
                                    color: isOpen ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        const Text(
                          'เมนูทั้งหมด',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        GridView.count(
                          crossAxisCount: isTablet ? 3 : 2,
                          crossAxisSpacing: isTablet ? 24 : 16,
                          mainAxisSpacing: isTablet ? 24 : 16,
                          childAspectRatio: isTablet ? 0.9 : 0.75,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: foodList.map((food) {
                            return _buildFoodCard(
                              context,
                              foodData: food,
                              storeName: storeName,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFoodCard(
    BuildContext context, {
    required Map<String, dynamic> foodData,
    required String storeName,
  }) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    final price = double.tryParse(foodData['price'].toString()) ?? 0;

    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          '/editFood',
          arguments: {
            'id': foodData['food_id'],
            'name': foodData['food_name'],
            'price': foodData['price'],
            'imagePath': foodData['image_url'],
            'options': foodData['options'],
          },
        );
        // 🔁 ดึงข้อมูลเมนูใหม่หลังจากกลับมาจากหน้าแก้ไข
        await loadMarket();
      },

      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 18 : size.width * 0.02),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            isTablet ? 18 : size.width * 0.03,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                isTablet ? 12 : size.width * 0.02,
              ),
              child: Image.network(
                foodData['image_url'] ?? 'https://via.placeholder.com/150',
                height: isTablet ? 120 : size.width * 0.25,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error),
              ),
            ),
            SizedBox(height: isTablet ? 12 : size.height * 0.01),
            Text(
              foodData['food_name'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 18 : size.width * 0.04,
              ),
            ),
            SizedBox(height: isTablet ? 6 : size.height * 0.005),
            Text(
              storeName,
              style: TextStyle(
                fontSize: isTablet ? 14 : size.width * 0.03,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isTablet ? 12 : size.height * 0.008),
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: isTablet ? 16 : size.width * 0.035,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                const Text(
                  '20 นาที',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  '฿${price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: isTablet ? 16 : size.width * 0.035,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
