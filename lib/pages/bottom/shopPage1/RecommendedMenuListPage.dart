import 'package:flutter/material.dart';
import 'package:delivery/APIs/Foods/FoodsMenuAPI.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:delivery/pages/store/OrderFoodPage.dart'; // ✅ Path ที่แท้จริง

class RecommendedMenuListPage extends StatefulWidget {
  const RecommendedMenuListPage({Key? key}) : super(key: key);

  @override
  State<RecommendedMenuListPage> createState() =>
      _RecommendedMenuListPageState();
}

class _RecommendedMenuListPageState extends State<RecommendedMenuListPage> {
  final FoodApiService _foodApiService = FoodApiService();
  bool isLoading = true;
  List<dynamic> foods = [];

  @override
  void initState() {
    super.initState();
    fetchFoods();
  }

  Future<void> fetchFoods() async {
    try {
      final auth = AuthService();
      await auth.refreshUserToken();
      final token = await auth.getToken();
      if (token == null) return;

      final data = await _foodApiService.getAllFoods();

      // ✅ กรองเฉพาะเมนูที่มีเรตติ้งสูง (>= 4.0)
      final recommendedFoods = data.where((f) {
        final rating = double.tryParse(f['rating']?.toString() ?? '0') ?? 0;
        return rating >= 3.0;
      }).toList();

      setState(() {
        foods = recommendedFoods;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching foods: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('เมนูแนะนำ'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : foods.isEmpty
              ? const Center(child: Text('ไม่พบข้อมูลเมนูแนะนำ'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isTablet ? 0.9 : 0.8,
                  ),
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    final price =
                        double.tryParse(food['sell_price']?.toString() ?? '0') ?? 0.0;
                    final rating =
                        double.tryParse(food['rating']?.toString() ?? '0') ?? 0.0;

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
                                height: 130,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  height: 130,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image, size: 60),
                                ),
                              ),
                            ),

                            // ✅ ชื่อเมนู
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                food['food_name'] ?? 'ชื่ออาหารไม่ระบุ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // ✅ ชื่อร้าน
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                food['shop_name'] ?? 'ร้านค้าไม่ระบุ',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const Spacer(),

                            // ✅ ราคา + เรตติ้ง
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${price.toStringAsFixed(0)}.-',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
