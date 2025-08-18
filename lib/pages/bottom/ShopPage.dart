import 'package:delivery/APIs/Foods/FoodsMenuAPI.dart';
import 'package:delivery/APIs/Foods/MaketsAllAPI.dart';
import 'package:delivery/pages/store/StoreMenuPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store/foods/OrderFoodPage.dart';
import '../../providers/basket_provider.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final FoodApiService _foodApiService = FoodApiService();
  final MarketsApiService _MarketApiService = MarketsApiService();

  List<dynamic> allFoods = [];
  List<dynamic> allMarkets = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllFoods();
  }

  Future<void> fetchAllFoods() async {
    try {
      final foodData = await _foodApiService.getAllFoods();
      final MarketData = await _MarketApiService.getAllMarkets();

      setState(() {
        allFoods = foodData;
        allMarkets = MarketData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: Colors.green.shade400,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Background green section
              Container(
                height: size.height * 0.4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF34C759),
                      const Color.fromARGB(255, 84, 205, 90),
                    ],
                  ),
                ),
              ),
              // Main scrollable content
              SafeArea(
                child: SingleChildScrollView(
                  physics: ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      // Header section
                      Padding(
                        padding: EdgeInsets.all(isTablet ? 24 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top bar with title and icons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'CSC HD Food',
                                  style: TextStyle(
                                    fontSize: isTablet ? 28 : size.width * 0.06,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Shopping cart with badge
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(context, '/basket');
                                      },
                                      child: Consumer<BasketProvider>(
                                        builder: (context, basket, _) {
                                          int count = basket.items.fold(
                                            0,
                                            (sum, e) => sum + e.quantity,
                                          );
                                          return Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(
                                                  isTablet ? 12 : 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.shopping_cart,
                                                  color: Colors.white,
                                                  size: isTablet ? 24 : 20,
                                                ),
                                              ),
                                              if (count > 0)
                                                Positioned(
                                                  right: -6,
                                                  top: -15,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 22,
                                                          minHeight: 22,
                                                        ),
                                                    child: Center(
                                                      child: Text(
                                                        '$count',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                    SizedBox(width: isTablet ? 12 : 8),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/dashboard',
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(
                                          isTablet ? 12 : 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: isTablet ? 24 : 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(
                              height: isTablet ? 20 : size.height * 0.015,
                            ),
                            // Search bar
                            TextField(
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: isTablet ? 26 : 20,
                                ),
                                suffixIcon: Container(
                                  margin: EdgeInsets.all(isTablet ? 6 : 4),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF34C759),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.tune,
                                    color: Colors.white,
                                    size: isTablet ? 20 : 16,
                                  ),
                                ),
                                hintText: 'Search',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    isTablet ? 16 : 12,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: isTablet ? 18 : size.width * 0.045,
                              ),
                            ),
                            SizedBox(
                              height: isTablet ? 24 : size.height * 0.02,
                            ),
                            // Main text
                            Text(
                              "Food That's\nGood For You",
                              style: TextStyle(
                                fontSize: isTablet ? 24 : size.width * 0.05,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ],
                        ),
                      ),
                      // White content section
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isTablet ? 32 : 24),
                            topRight: Radius.circular(isTablet ? 32 : 24),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isTablet ? 24 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Categories section
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'หมวดหมู่อาหาร',
                                    style: TextStyle(
                                      fontSize: isTablet
                                          ? 20
                                          : size.width * 0.045,
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
                                        fontSize: isTablet
                                            ? 18
                                            : size.width * 0.04,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: isTablet ? 12 : size.height * 0.01,
                              ),
                              // Categories horizontal list
                              SizedBox(
                                height: isTablet ? 120 : size.width * 0.22,
                                child: Center(
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    shrinkWrap: true,
                                    physics: BouncingScrollPhysics(),
                                    children: [
                                      _buildCategory(
                                        size,
                                        isTablet,
                                        'assets/menus/main.png',
                                        'มื้อหลัก',
                                      ),
                                      _buildCategory(
                                        size,
                                        isTablet,
                                        'assets/menus/main.png',
                                        'ก๋วยเตี๋ยว',
                                      ),
                                      _buildCategory(
                                        size,
                                        isTablet,
                                        'assets/menus/main.png',
                                        'เครื่องดื่ม',
                                      ),
                                      _buildCategory(
                                        size,
                                        isTablet,
                                        'assets/menus/main.png',
                                        'ของหวาน',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: isTablet ? 24 : size.height * 0.02,
                              ),
                              Divider(color: Colors.grey),
                              SizedBox(
                                height: isTablet ? 24 : size.height * 0.02,
                              ),
                              // Stores section
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ร้านค้าที่เข้าร่วม',
                                    style: TextStyle(
                                      fontSize: isTablet
                                          ? 20
                                          : size.width * 0.045,
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
                                        fontSize: isTablet
                                            ? 18
                                            : size.width * 0.04,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: isTablet ? 12 : size.height * 0.01,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: allMarkets.map((Maket) {
                                  print('Maket data: $Maket');

                                  // เรียกใช้ _buildStoreItem และส่ง image_url เข้าไปด้วย
                                  return _buildStoreItem(
                                    context,
                                    size,
                                    isTablet,
                                    Maket['shop_name'] ?? 'ชื่อร้านไม่ระบุ',
                                    Maket['shop_logo_url'] ??
                                        'https://via.placeholder.com/150', // ส่ง URL รูปภาพ
                                  );
                                }).toList(),
                              ),
                              SizedBox(
                                height: isTablet ? 24 : size.height * 0.02,
                              ),
                              Divider(color: Colors.grey),
                              SizedBox(
                                height: isTablet ? 24 : size.height * 0.02,
                              ),
                              // Recommended menu section
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'เมนูแนะนำ',
                                    style: TextStyle(
                                      fontSize: isTablet
                                          ? 20
                                          : size.width * 0.045,
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
                                        fontSize: isTablet
                                            ? 18
                                            : size.width * 0.04,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: isTablet ? 12 : size.height * 0.01,
                              ),
                              // Recommended menu grid
                              GridView.count(
                                crossAxisCount: isTablet ? 3 : 2,
                                crossAxisSpacing: isTablet ? 24 : 16,
                                mainAxisSpacing: isTablet ? 24 : 16,
                                childAspectRatio: isTablet ? 0.9 : 0.75,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                children: [
                                  _buildRecommendedMenu(
                                    size,
                                    isTablet,
                                    "ข้าวกระเพรา หมูสับ ผัดพริกแกง ต้มเป็ด",
                                    "ร้านอร่อย",
                                    "15 นาที",
                                    45,
                                    'assets/menus/kai.png',
                                    5.0,
                                  ),
                                  _buildRecommendedMenu(
                                    size,
                                    isTablet,
                                    "ข้าวผัด",
                                    "ร้านเจ๊หมี",
                                    "20 นาที",
                                    50,
                                    'assets/menus/yam.png',
                                    4.0,
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: isTablet ? 24 : size.height * 0.02,
                              ),
                              Divider(color: Colors.grey),
                              SizedBox(
                                height: isTablet ? 24 : size.height * 0.02,
                              ),
                              // Recommended menu section
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'เมนูทั้งหมด',
                                    style: TextStyle(
                                      fontSize: isTablet
                                          ? 20
                                          : size.width * 0.045,
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
                                        fontSize: isTablet
                                            ? 18
                                            : size.width * 0.04,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: isTablet ? 12 : size.height * 0.01,
                              ),
                              // Recommended menu grid
                              GridView.count(
                                crossAxisCount: isTablet ? 3 : 2,
                                crossAxisSpacing: isTablet ? 24 : 16,
                                mainAxisSpacing: isTablet ? 24 : 16,
                                childAspectRatio: isTablet ? 0.9 : 0.75,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                children: allFoods.map((food) {
                                  // ใช้ข้อมูลจาก API มาแสดงผลในเมนูแต่ละรายการ
                                  // print('Food data: $food');  เอาไว้ log เบิ่งข้อมูล
                                  final price =
                                      double.tryParse(
                                        food['price'].toString(),
                                      ) ??
                                      0.0;
                                  final rating =
                                      double.tryParse(
                                        food['rating'].toString(),
                                      ) ??
                                      0.0;
                                  return _buildRecommendedMenu(
                                    size,
                                    isTablet,
                                    food['food_name'] ?? 'ชื่ออาหารไม่ระบุ',
                                    food['shop_name'] ?? 'ร้านค้าไม่ระบุ',
                                    food['estimated_delivery_time'] ?? '- นาที',
                                    price, // ใช้ตัวแปร price ที่แปลงค่าแล้ว
                                    food['image_url'] ??
                                        'https://via.placeholder.com/150',
                                    rating, // ใช้ตัวแปร rating ที่แปลงค่าแล้ว
                                  );
                                }).toList(),
                              ),
                              SizedBox(
                                height: isTablet ? 40 : size.height * 0.05,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategory(Size size, bool isTablet, String icon, String label) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : size.width * 0.015,
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: isTablet ? 44 : size.width * 0.08,
            child: Image.asset(icon, height: isTablet ? 32 : size.width * 0.06),
          ),
          SizedBox(height: isTablet ? 8 : size.height * 0.005),
          Text(
            label,
            style: TextStyle(fontSize: isTablet ? 16 : size.width * 0.03),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreItem(
    BuildContext context,
    Size size,
    bool isTablet,
    String name,
    String imageUrl,
  ) {
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
            width: isTablet ? 120 : size.width * 0.22,
            height: isTablet ? 120 : size.width * 0.22,
            // เพิ่มเงา (shadow) ให้ดูมีมิติ
            decoration: BoxDecoration(
              color: Colors.white, // เปลี่ยนสีพื้นหลังเป็นสีขาว
              borderRadius: BorderRadius.circular(
                isTablet ? 60 : size.width * 0.11, // ทำให้เป็นวงกลม
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
              // ใช้ NetworkImage เพื่อดึงรูปจาก URL
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 8 : size.height * 0.01),
          // ใช้ Padding เพื่อให้ชื่อร้านไม่ติดขอบมากเกินไป
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 4),
            child: Text(
              name,
              textAlign: TextAlign.center, // จัดตำแหน่งข้อความตรงกลาง
              maxLines: 1, // จำกัดให้แสดงแค่บรรทัดเดียว
              overflow: TextOverflow.ellipsis, // ถ้าชื่อยาวเกินให้แสดง ...
              style: TextStyle(
                fontSize: isTablet ? 16 : size.width * 0.035,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedMenu(
    Size size,
    bool isTablet,
    String title,
    String shop,
    String time,
    double price,
    String imagePath,
    double rating,
  ) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderFoodPage(
                foodName: title,
                imagePath: imagePath,
                rating: rating,
                storeName: shop,
                price: price,
                description: 'เมนูแนะนำจาก $shop',
              ),
            ),
          );
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
                color: const Color.fromARGB(
                  255,
                  114,
                  114,
                  114,
                ).withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  isTablet ? 12 : size.width * 0.02,
                ),
                child: Stack(
                  children: [
                    Image.network(
                      imagePath,
                      height: isTablet ? 120 : size.width * 0.25,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      // เพิ่ม loadingBuilder และ errorBuilder เพื่อจัดการสถานะการโหลด
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback UI เมื่อโหลดรูปไม่ได้
                        return Container(
                          height: isTablet ? 120 : size.width * 0.25,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: Icon(Icons.broken_image, size: 50),
                        );
                      },
                    ),
                    Positioned(
                      top: isTablet ? 12 : size.width * 0.02,
                      right: isTablet ? 12 : size.width * 0.02,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 10 : size.width * 0.015,
                          vertical: isTablet ? 4 : size.width * 0.005,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF34C759).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(
                            isTablet ? 8 : size.width * 0.015,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.yellow,
                              size: isTablet ? 20 : size.width * 0.035,
                            ),
                            SizedBox(width: isTablet ? 6 : size.width * 0.01),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: isTablet ? 14 : size.width * 0.03,
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
              SizedBox(height: isTablet ? 12 : size.height * 0.01),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 18 : size.width * 0.04,
                ),
              ),
              SizedBox(height: isTablet ? 6 : size.height * 0.005),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  shop,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : size.width * 0.03,
                    color: Colors.grey,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.timer, size: isTablet ? 18 : size.width * 0.035),
                  SizedBox(width: isTablet ? 6 : size.width * 0.01),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : size.width * 0.03,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$ $price.-',
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
      ),
    );
  }
}
