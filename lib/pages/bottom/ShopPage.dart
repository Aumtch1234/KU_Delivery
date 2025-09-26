import 'package:delivery/APIs/Foods/FoodsMenuAPI.dart';
import 'package:delivery/APIs/Foods/MaketsAllAPI.dart';
import 'package:delivery/APIs/Markets/FetchMarket.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:delivery/main.dart';
import 'package:delivery/pages/store/StoreMenuPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store/OrderFoodPage.dart';
import '../basket/providers/basket_provider.dart';

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
    loadMarketData(); // ✅ เพิ่มการโหลด market data

    // ✅ โหลดตะกร้าทันที
    Future.microtask(() {
      final basket = Provider.of<BasketProvider>(context, listen: false);
      basket.loadCartFromAPI();
    });
  }

  /// ✅ โหลดข้อมูลร้านค้าของผู้ใช้เพื่อแสดง AssistiveButton
  Future<void> loadMarketData() async {
    try {
      final marketData = await fetchMyMarket();
      // อัปเดต market data ใน AuthService
      AuthService().updateMarketData(marketData);
    } catch (e) {
      print('Error loading market data in ShopPage: $e');
      AuthService().updateMarketData(null);
    }
  }

  Future<void> fetchAllFoods() async {
    try {
      final auth = AuthService();

      // ✅ รีเฟรช token ถ้าหมดอายุ
      final refreshed = await auth.refreshUserToken();
      if (!refreshed) {
        print("❌ refresh token ไม่สำเร็จ → กลับไปหน้า wellcome");
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/wellcome');
        }
        return;
      }

      final token = await auth.getToken();
      if (token == null) return;

      // ✅ ยิง API ด้วย token ล่าสุด
      final foodData = await _foodApiService.getAllFoods();
      final marketData = await _MarketApiService.getAllMarkets();

      setState(() {
        allFoods = foodData;
        allMarkets = marketData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final isLargeTablet = size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.green.shade400,
      body: SafeArea(
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header Section with Gradient
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF34C759),
                            const Color.fromARGB(255, 84, 205, 90),
                            const Color(0xFF28A745),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isTablet ? 32 : 20,
                          isTablet ? 24 : 16,
                          isTablet ? 32 : 20,
                          isTablet ? 32 : 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Navigation Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'CSC HD Food',
                                    style: TextStyle(
                                      fontSize: isLargeTablet
                                          ? 32
                                          : isTablet
                                          ? 28
                                          : size.width * 0.065,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    _buildTopIconButton(
                                      context,
                                      isTablet,
                                      Icons.shopping_cart,
                                      '/basket',
                                    ),
                                    SizedBox(width: isTablet ? 16 : 12),
                                    _buildTopIconButton(
                                      context,
                                      isTablet,
                                      Icons.person,
                                      '/dashboard',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: isTablet ? 28 : 20),

                            // Search Bar with Enhanced Design
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.all(isTablet ? 16 : 12),
                                    child: Icon(
                                      Icons.search,
                                      size: isTablet ? 28 : 22,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  suffixIcon: Container(
                                    margin: EdgeInsets.all(isTablet ? 8 : 6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF34C759),
                                          Color(0xFF28A745),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.tune,
                                      color: Colors.white,
                                      size: isTablet ? 22 : 18,
                                    ),
                                  ),
                                  hintText: 'ค้นหาอาหารที่คุณต้องการ...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: isTablet ? 18 : 16,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 20 : 16,
                                    vertical: isTablet ? 18 : 16,
                                  ),
                                ),
                                style: TextStyle(fontSize: isTablet ? 18 : 16),
                              ),
                            ),
                            SizedBox(height: isTablet ? 32 : 24),

                            // Welcome Text
                            Text(
                              "อาหารดีๆ\nสำหรับคุณ",
                              style: TextStyle(
                                fontSize: isLargeTablet
                                    ? 32
                                    : isTablet
                                    ? 28
                                    : size.width * 0.06,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Main Content Section
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          // Handle bar indicator
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Categories Section
                          _buildSectionHeader(
                            'หมวดหมู่อาหาร',
                            'ดูทั้งหมด',
                            isTablet,
                            size,
                          ),
                          const SizedBox(height: 16),
                          _buildCategoriesSection(size, isTablet),

                          const SizedBox(height: 32),
                          _buildDivider(),
                          const SizedBox(height: 32),

                          // Participating Stores Section
                          _buildSectionHeader(
                            'ร้านค้าที่เข้าร่วม',
                            'ดูทั้งหมด',
                            isTablet,
                            size,
                          ),
                          const SizedBox(height: 16),
                          _buildStoresSection(size, isTablet),

                          const SizedBox(height: 32),
                          _buildDivider(),
                          const SizedBox(height: 32),

                          // Recommended Menu Section
                          _buildSectionHeader(
                            'เมนูแนะนำ',
                            'ดูทั้งหมด',
                            isTablet,
                            size,
                          ),
                          const SizedBox(height: 16),
                          _buildRecommendedMenusGrid(size, isTablet),

                          const SizedBox(height: 32),
                          _buildDivider(),
                          const SizedBox(height: 32),

                          // All Menu Section
                          _buildSectionHeader(
                            'เมนูทั้งหมด',
                            'ดูเพิ่มเติม',
                            isTablet,
                            size,
                          ),
                          const SizedBox(height: 16),
                          _buildAllMenusGrid(size, isTablet),

                          SizedBox(height: isTablet ? 60 : 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTopIconButton(
    BuildContext context,
    bool isTablet,
    IconData icon,
    String route,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Consumer<BasketProvider>(
        builder: (context, basket, _) {
          final isCartIcon = icon == Icons.shopping_cart;
          final count = isCartIcon ? basket.cartCount : 0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 14 : 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isTablet ? 26 : 22,
                ),
              ),
              if (isCartIcon && count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
    );
  }

  Widget _buildSectionHeader(
    String title,
    String actionText,
    bool isTablet,
    Size size,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 24 : size.width * 0.05,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12,
                vertical: isTablet ? 8 : 6,
              ),
            ),
            child: Text(
              actionText,
              style: TextStyle(
                color: const Color(0xFF34C759),
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.grey.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(Size size, bool isTablet) {
    final categories = [
      {'icon': 'assets/menus/main.png', 'label': 'มื้อหลัก'},
      {'icon': 'assets/menus/main.png', 'label': 'ก๋วยเตี๋ยว'},
      {'icon': 'assets/menus/main.png', 'label': 'เครื่องดื่ม'},
      {'icon': 'assets/menus/main.png', 'label': 'ของหวาน'},
      {'icon': 'assets/menus/main.png', 'label': 'ผลไม้'},
      {'icon': 'assets/menus/bakefast.png', 'label': 'ของทอด'},
      {'icon': 'assets/menus/main.png', 'label': 'สลัด'},
    ];

    return SizedBox(
      height: isTablet ? 140 : size.width * 0.28,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return _buildCategory(
            size,
            isTablet,
            categories[index]['icon']!,
            categories[index]['label']!,
            
          );
        },
      ),
    );
  }
  

  Widget _buildStoresSection(Size size, bool isTablet) {
    // จำกัดร้านค้าที่แสดงเป็น 10 ร้าน
    final displayMarkets = allMarkets.take(10).toList();

    return SizedBox(
      height: isTablet ? 160 : size.width * 0.35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
        itemCount: displayMarkets.length,
        itemBuilder: (context, index) {
          final market = displayMarkets[index];
          return Padding(
            padding: EdgeInsets.only(right: isTablet ? 20 : 16),
            child: _buildStoreItem(
              context,
              size,
              isTablet,
              market['market_id'],
              market['shop_name'] ?? 'ชื่อร้านไม่ระบุ',
              market['shop_logo_url'] ?? 'https://via.placeholder.com/150',
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedMenusGrid(Size size, bool isTablet) {
    final recommendedFoods = allFoods
        .where((food) {
          final rating = double.tryParse(food['rating'].toString()) ?? 0.0;
          return rating >= 2.5;
        })
        .take(15) // จำกัดเป็น 15 รายการ
        .toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 3 : 2,
          crossAxisSpacing: isTablet ? 24 : 16,
          mainAxisSpacing: isTablet ? 24 : 16,
          childAspectRatio: isTablet ? 0.85 : 0.75,
        ),
        itemCount: recommendedFoods.length,
        itemBuilder: (context, index) {
          final food = recommendedFoods[index];
          return _buildRecommendedMenu(
            size,
            isTablet,
            food['food_name'] ?? '',
            food['shop_name'] ?? '',
            food['time']?.toString() ?? '',
            double.tryParse(food['sell_price']?.toString() ?? '0') ?? 0.0,
            food['image_url'] ?? '',
            double.tryParse(food['rating']?.toString() ?? '0') ?? 0.0,
            food['food_id'] ?? 0,
          );
        },
      ),
    );
  }

  Widget _buildAllMenusGrid(Size size, bool isTablet) {
    final displayFoods = allFoods.take(15).toList(); // จำกัดเป็น 15 รายการ

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 3 : 2,
          crossAxisSpacing: isTablet ? 24 : 16,
          mainAxisSpacing: isTablet ? 24 : 16,
          childAspectRatio: isTablet ? 0.85 : 0.75,
        ),
        itemCount: displayFoods.length,
        itemBuilder: (context, index) {
          final food = displayFoods[index];
          return _buildRecommendedMenu(
            size,
            isTablet,
            food['food_name'] ?? '',
            food['shop_name'] ?? '',
            food['time']?.toString() ?? '',
            double.tryParse(food['sell_price']?.toString() ?? '0') ?? 0.0,
            food['image_url'] ?? '',
            double.tryParse(food['rating']?.toString() ?? '0') ?? 0.0,
            food['food_id'] ?? 0,
          );
        },
      ),
    );
  }

 Widget _buildCategory(Size size, bool isTablet, String icon, String label) {
  final bool isFried = label == 'ของทอด'; // 👈 เช็คว่าคือ "ของทอด" ไหม

  return Padding(
    padding: EdgeInsets.only(right: isTablet ? 20 : 16),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: isTablet ? 80 : size.width * 0.16,
          height: isTablet ? 80 : size.width * 0.16,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              icon,
              height: isFried
                  ? (isTablet ? 100 : size.width * 0.11)  // 👈 ของทอดใหญ่ขึ้น
                  : (isTablet ? 36 : size.width * 0.08),
              width: isFried
                  ? (isTablet ? 50 : size.width * 0.11)
                  : (isTablet ? 36 : size.width * 0.08),
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 14 : size.width * 0.032,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

  Widget _buildStoreItem(
    BuildContext context,
    Size size,
    bool isTablet,
    int marketID,
    String shopName,
    String imageUrl,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RouteWrapper(
              child: StoreMenuPage(marketID: marketID),
              routeName: '/storeMenu',
            ),
          ),
        );
        print("Navigating to StoreMenuPage with marketID: $marketID");
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
              shopName,
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
    int foodId,
  ) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RouteWrapper(
                child: OrderFoodPage(foodId: foodId),
                routeName: '/order_food',
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
