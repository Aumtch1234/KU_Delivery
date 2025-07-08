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
  String imageStoreURL = '';
  String storeDescription = '';
  String opened = '';
  String closed = '';
  bool isLoading = true;
  bool isOpen = true;

  @override
  void initState() {
    super.initState();
    loadMarket();
  }

  Future<void> loadMarket() async {
    final market = await fetchMyMarket();
    final foods = await FetchFoodsForMarket();

    if (market != null && foods != null) {
      setState(() {
        storeName = market['shop_name'] ?? 'ไม่มีชื่อร้าน';
        imageStoreURL = market['shop_logo_url'] ?? '';
        storeDescription = market['shop_description'] ?? '';
        opened = market['open_time'] ?? 'ไม่ได้ตั้งเวลาเปิดร้าน';
        closed = market['close_time'] ?? 'ไม่ได้ตั้งเวลาปิดร้าน';
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
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text("ร้านค้าของฉัน"),
        backgroundColor: const Color(0xFF34C759),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Image.network(
                        imageStoreURL,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.store, size: 100),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '4.5',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    storeName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    storeDescription,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "ร้านเปิด $opened - $closed",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isOpen = !isOpen;
                                });
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF34C759),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageStoreURL.isNotEmpty)
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(imageStoreURL),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  storeName,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.add, color: Colors.white),
                title: const Text(
                  'เพิ่มอาหาร',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/addFood');
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_attributes, color: Colors.white),
                title: const Text(
                  'แก้ไขข้อมูลร้านค้า',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text(
                  'ออกจากร้านค้า',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/dashboard');
                }
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'v1.0',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
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
        await loadMarket();
      },
      child: Container(
        padding: EdgeInsets.all(isTablet ? 18 : size.width * 0.02),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            isTablet ? 18 : size.width * 0.03,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
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
            const SizedBox(height: 8),
            Text(
              foodData['food_name'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 18 : size.width * 0.04,
              ),
            ),
            Text(
              storeName,
              style: TextStyle(
                fontSize: isTablet ? 14 : size.width * 0.03,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.grey),
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
