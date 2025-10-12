import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:delivery/pages/bottom/shopPage1/FoodListByCategoryPage.dart';
import 'package:delivery/APIs/api_config.dart'; // ✅ เพิ่ม import ด้านบนไฟล์

// ✅ Model
class FoodCategory {
  final int id;
  final String name;
  final String? cateImageUrl;

  FoodCategory({
    required this.id,
    required this.name,
    this.cateImageUrl,
  });

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    return FoodCategory(
      id: json['id'],
      name: json['name'],
      cateImageUrl: json['cate_image_url'],
    );
  }
}

// ✅ ดึงข้อมูลจาก API
Future<List<FoodCategory>> fetchFoodCategories() async {
  final url = Uri.parse('${ApiConfig.baseHost}/client/categories'); // ✅ ใช้ dynamic base URL
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    final List<dynamic> list = jsonData['data'];
    return list.map((item) => FoodCategory.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load categories');
  }
}

// ✅ UI หลัก
class FoodCategoryListPage extends StatefulWidget {
  const FoodCategoryListPage({Key? key, required List }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'หมวดหมู่อาหาร',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 10, 199, 7),
      ),
      body: FutureBuilder<List<FoodCategory>>(
        future: futureCategories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่พบหมวดหมู่อาหาร'));
          }

          final categories = snapshot.data!;

          // ✅ แสดงผลเป็น GridView
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 ช่องต่อแถว
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1, // ให้เป็นสี่เหลี่ยมจัตุรัส
            ),
            itemBuilder: (context, index) {
              final category = categories[index];

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // ไปหน้า FoodListByCategoryPage พร้อมส่ง id และ name
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: const Color.fromARGB(255, 7, 217, 63),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✅ รูปภาพเท่ากันทุกช่อง + สัดส่วนไม่เพี้ยน
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 100,
                          height: 100,
                          color: Colors.orange.shade50,
                          child: category.cateImageUrl != null
                              ? Image.network(
                                  category.cateImageUrl!,
                                  fit: BoxFit.contain, // ✅ ไม่ครอป ไม่บีบ
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image,
                                          size: 50, color: Colors.grey),
                                )
                              : Image.asset(
                                  'assets/menus/fast1.png',
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
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
