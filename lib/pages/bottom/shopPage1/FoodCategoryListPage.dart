import 'dart:convert';
import 'package:delivery/APIs/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:delivery/pages/bottom/shopPage1/FoodListByCategoryPage.dart';

// ✅ Model
class FoodCategory {
  final int id;
  final String name;
  final String? cateImageUrl;
  final int foodCount;

  FoodCategory({
    required this.id,
    required this.name,
    this.cateImageUrl,
    this.foodCount = 0,
  });

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return FoodCategory(
      id: safeInt(json['id']),
      name: json['name'] ?? '',
      cateImageUrl: json['cate_image_url'],
      foodCount: safeInt(json['food_count']),
    );
  }
}

// ✅ ดึงข้อมูลจาก API
Future<List<FoodCategory>> fetchFoodCategories() async {
  final url = Uri.parse('${ApiConfig.baseUrl}/categories');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    final List<dynamic> list = jsonData['data'];
    print(jsonData);

    return list.map((item) => FoodCategory.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load categories');
  }
}

// ✅ UI หลัก
class FoodCategoryListPage extends StatefulWidget {
  const FoodCategoryListPage({Key? key, required List}) : super(key: key);

  @override
  State<FoodCategoryListPage> createState() => _FoodCategoryListPageState();
}

class _FoodCategoryListPageState extends State<FoodCategoryListPage> {
  late Future<List<FoodCategory>> futureCategories;

  @override
  void initState() {
    super.initState();
    futureCategories = fetchFoodCategories();
  }

  // 🎨 สีไล่เฉดสำหรับแต่ละหมวดหมู่
  Color _getCategoryColor(int index) {
    final colors = [
      Colors.orange.shade50,
      Colors.green.shade50,
      Colors.blue.shade50,
      Colors.purple.shade50,
      Colors.pink.shade50,
      Colors.teal.shade50,
      Colors.amber.shade50,
      Colors.indigo.shade50,
    ];
    return colors[index % colors.length];
  }

  Color _getCategoryAccent(int index) {
    final colors = [
      Colors.orange,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'หมวดหมู่อาหาร',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade600,
                Colors.green.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<FoodCategory>>(
        future: futureCategories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.green.shade600,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังโหลดหมวดหมู่...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่พบหมวดหมู่อาหาร',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final categories = snapshot.data!;
          final screenWidth = MediaQuery.of(context).size.width;
          int crossAxisCount = (screenWidth ~/ 180).clamp(2, 5);

          // ✅ แสดงผลเป็น GridView สวยงาม
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              final bgColor = _getCategoryColor(index);
              final accentColor = _getCategoryAccent(index);

              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FoodListByCategoryPage(
                        categoryId: category.id,
                        categoryName: category.name,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✅ ภาพพื้นหลังกลม + รูปภาพเต็มกรอบ
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: category.cateImageUrl != null
                              ? Image.network(
                                  category.cateImageUrl!,
                                  fit: BoxFit.cover,
                                  width: 90,
                                  height: 90,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                    color: bgColor,
                                    child: Icon(
                                      Icons.restaurant,
                                      size: 40,
                                      color: accentColor,
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  'assets/menus/fast1.png',
                                  fit: BoxFit.cover,
                                  width: 90,
                                  height: 90,
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ✅ ชื่อหมวดหมู่
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ✅ จำนวนเมนู พร้อมไอคอน
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 14,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${category.foodCount} เมนู',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}