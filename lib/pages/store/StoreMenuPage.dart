import 'package:delivery/APIs/Foods/FoodSelectAPI.dart';
import 'package:delivery/main.dart';
import 'package:delivery/pages/store/models/Food_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery/pages/basket/providers/basket_provider.dart';
import 'package:delivery/pages/store/OrderFoodPage.dart';
import 'package:delivery/pages/store/StoreDetailPage.dart';

class StoreMenuPage extends StatefulWidget {
  final int marketID;

  const StoreMenuPage({Key? key, required this.marketID}) : super(key: key);

  @override
  State<StoreMenuPage> createState() => _StoreMenuPageState();
}

class _StoreMenuPageState extends State<StoreMenuPage> {
  late Future<List<Food>> _futureFoods;

  @override
  void initState() {
    super.initState();
    _futureFoods = FoodService.fetchFoods(widget.marketID);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
      body: FutureBuilder<List<Food>>(
        future: _futureFoods,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final foods = snapshot.data ?? [];
          if (foods.isEmpty) {
            return const Center(child: Text("ไม่มีเมนูในร้านนี้"));
          }

          final marketLogo = foods.first.shopLogoUrl;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStoreHeader(marketLogo),
                _buildStoreInfo(context, foods.first),
                _buildMenuItems(foods),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ Header ใช้รูปจาก API
  Widget _buildStoreHeader(String logoUrl) {
    return Stack(
      children: [
        Image.network(
          logoUrl,
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image_not_supported, size: 80),
        ),
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

  // ✅ Market Info
  Widget _buildStoreInfo(BuildContext context, Food marketInfo) {
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
                    builder: (context) => RouteWrapper(
                      child: StoreDetailPage(marketID: widget.marketID),
                      routeName: '/store_detail',
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      marketInfo.shopName,
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
                  color: marketInfo.isOpen
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: marketInfo.isOpen
                        ? Colors
                              .green
                              .shade100 // ถ้าเปิด = เขียว
                        : Colors.red.shade100, // ถ้าปิด = แดง
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    marketInfo.isOpen
                        ? 'เปิดอยู่'
                        : 'ปิดแล้ว', // แสดงข้อความตามสถานะ
                    style: TextStyle(
                      color: marketInfo.isOpen ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                (marketInfo.marketRating ?? 0).toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(' • ', style: TextStyle(fontSize: 16)),
              const Text(
                '15-20 นาที', // เดี๋ยวตรงนี้ถ้า API มีเวลาจริง เราจะดึงมาแทน
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

  // ✅ Menu Items
  Widget _buildMenuItems(List<Food> foods) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        final food = foods[index];
        return _buildMenuItem(context, food);
      },
    );
  }

  Widget _buildMenuItem(BuildContext context, Food food) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RouteWrapper(
                child: OrderFoodPage(foodId: food.foodId),
                routeName: '/order_food',
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
                child: Image.network(
                  food.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.foodName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "รีวิว: ${food.foodRating ?? '-'} ⭐",
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '฿${food.sell_price.toStringAsFixed(0)}',
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
