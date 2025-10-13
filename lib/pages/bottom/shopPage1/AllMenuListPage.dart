import 'package:flutter/material.dart';
import 'package:delivery/APIs/Foods/FoodsMenuAPI.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:delivery/pages/store/OrderFoodPage.dart';

class AllMenuListPage extends StatefulWidget {
  const AllMenuListPage({Key? key}) : super(key: key);

  @override
  State<AllMenuListPage> createState() => _AllMenuListPageState();
}

class _AllMenuListPageState extends State<AllMenuListPage> {
  final FoodApiService _foodApiService = FoodApiService();
  bool isLoading = true;
  List<dynamic> foods = [];

  @override
  void initState() {
    super.initState();
    fetchAllFoods();
  }

  Future<void> fetchAllFoods() async {
    try {
      final auth = AuthService();
      await auth.refreshUserToken();
      final token = await auth.getToken();
      if (token == null) return;

      final data = await _foodApiService.getAllFoods();
      setState(() {
        foods = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching all foods: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('เมนูทั้งหมด'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : foods.isEmpty
              ? const Center(child: Text('ไม่พบข้อมูลเมนู'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isTablet ? 0.9 : 0.75, // ✅ ปรับให้สูงขึ้น
                  ),
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    final price = double.tryParse(
                            food['sell_price']?.toString() ?? '0') ??
                        0.0;
                    final rating = double.tryParse(
                            food['rating']?.toString() ?? '0') ??
                        0.0;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderFoodPage(foodId: food['food_id']),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ รูปอาหาร
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Image.network(
                                food['image_url'] ??
                                    'https://via.placeholder.com/150',
                                height: 120, // ✅ ลดจาก 130 เป็น 120
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  height: 120,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image,
                                      size: 50, color: Colors.grey),
                                ),
                              ),
                            ),

                            // ✅ ชื่อเมนู (ลด padding)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                              child: Text(
                                food['food_name'] ?? 'ชื่ออาหารไม่ระบุ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14, // ✅ ลดจาก 16 เป็น 14
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // ✅ ชื่อร้าน (ลด padding)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                food['shop_name'] ?? 'ร้านค้าไม่ระบุ',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12, // ✅ ลดจาก 14 เป็น 12
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const Spacer(),

                            // ✅ ราคา + เรตติ้ง (ลด padding)
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(8, 4, 8, 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${price.toStringAsFixed(0)}.-',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14, // ✅ ลดจาก 16 เป็น 14
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 14, // ✅ ลดจาก 16 เป็น 14
                                      ),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12, // ✅ ลดจาก 14 เป็น 12
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}