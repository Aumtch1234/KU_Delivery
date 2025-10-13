import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:delivery/pages/store/OrderFoodPage.dart';
import 'package:delivery/APIs/api_config.dart';

class FoodListByCategoryPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const FoodListByCategoryPage({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<FoodListByCategoryPage> createState() => _FoodListByCategoryPageState();
}

class _FoodListByCategoryPageState extends State<FoodListByCategoryPage> {
  List<dynamic> foods = [];
  bool isLoading = true;

  /// ✅ ดึงข้อมูลเมนูอาหารตามหมวดหมู่
  Future<void> fetchFoodsByCategory() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/categories/${widget.categoryId}/foods');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          foods = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        print('Error: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching foods by category: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFoodsByCategory();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : foods.isEmpty
              ? const Center(child: Text('ไม่พบเมนูอาหารในหมวดหมู่นี้'))
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
                    final name = food['food_name'] ?? 'ไม่ระบุชื่อ';
                    final image = food['image_url'] ??
                        'https://via.placeholder.com/150';
                    final price =
                        double.tryParse(food['sell_price']?.toString() ?? '') ??
                            double.tryParse(food['price']?.toString() ?? '') ??
                            0;
                    final rating =
                        double.tryParse(food['rating']?.toString() ?? '0') ?? 0;
                    final storeName =
                        food['shop_name'] ?? 'ร้านค้าไม่ระบุ';

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
                                image,
                                height: 120, // ✅ ลดขนาดจาก 130 เป็น 120
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
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14, // ✅ ลดขนาดจาก 16 เป็น 14
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // ✅ ชื่อร้าน (ลด padding)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                storeName,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12, // ✅ ลดขนาดจาก 14 เป็น 12
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const Spacer(),

                            // ✅ ราคาและเรตติ้ง (ลด padding)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${price.toStringAsFixed(0)} ฿',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14, // ✅ ลดขนาดจาก 16 เป็น 14
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 14, // ✅ ลดขนาดจาก 16 เป็น 14
                                      ),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12, // ✅ ลดขนาดจาก 14 เป็น 12
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