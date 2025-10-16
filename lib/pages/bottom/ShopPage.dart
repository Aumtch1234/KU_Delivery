import 'package:delivery/APIs/Foods/FoodsMenuAPI.dart';
import 'package:delivery/APIs/Foods/MaketsAllAPI.dart';
import 'package:delivery/APIs/Markets/FetchMarket.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:delivery/main.dart';
import 'package:delivery/pages/bottom/shopPage1/AdminMarketListPage.dart';
import 'package:delivery/pages/bottom/shopPage1/FoodCategoryListPage.dart';
import 'package:delivery/pages/bottom/shopPage1/MarketListPage.dart';
import 'package:delivery/pages/bottom/shopPage1/RecommendedMenuListPage.dart';
import 'package:delivery/pages/store/StoreMenuPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store/OrderFoodPage.dart';
import '../basket/providers/basket_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:delivery/pages/bottom/shopPage1/AllMenuListPage.dart';
import 'package:delivery/pages/bottom/shopPage1/FoodListByCategoryPage.dart';
import 'package:delivery/APIs/api_config.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  // ============ Services ============
  final FoodApiService _foodApiService = FoodApiService();
  final MarketsApiService _marketApiService = MarketsApiService();
  final TextEditingController _searchController = TextEditingController();

  // ============ Data States ============
  List<dynamic> _allFoods = [];
  List<dynamic> _allMarkets = [];
  List<dynamic> _adminMarkets = [];
  List<dynamic> _searchResults = [];

  // ============ UI States ============
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============ Initialization ============
  Future<void> _initializeData() async {
    await Future.wait([_loadBasket(), _loadMarketData(), _fetchAllData()]);
  }

  Future<void> _loadBasket() async {
    final basket = Provider.of<BasketProvider>(context, listen: false);
    await basket.loadCartFromAPI();
  }

  Future<void> _loadMarketData() async {
    try {
      final marketData = await fetchMyMarket();
      AuthService().updateMarketData(marketData);
    } catch (e) {
      debugPrint('Error loading market data: $e');
      AuthService().updateMarketData(null);
    }
  }

  // ============ Data Fetching ============
  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);

    try {
      final auth = AuthService();
      final refreshed = await auth.refreshUserToken();

      if (!refreshed) {
        debugPrint("❌ Token refresh failed");
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/wellcome');
        }
        return;
      }

      final token = await auth.getToken();
      if (token == null) return;

      // Fetch all data in parallel
      final results = await Future.wait([
        _foodApiService.getAllFoods(),
        _marketApiService.getAllMarkets(),
        _marketApiService.getAllADMINMarkets(),
      ]);

      setState(() {
        _allFoods = results[0];
        _allMarkets = results[1];
        _adminMarkets = results[2];
        _isLoading = false;
      });

      debugPrint('✅ Loaded foods: ${_allFoods.length}');
      debugPrint('✅ Loaded normal markets: ${_allMarkets.length}');
      debugPrint('✅ Loaded admin markets: ${_adminMarkets.length}');
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching data: $e');
    }
  }

  // ============ Search Functionality ============
  Future<void> _searchFoods(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    final url = Uri.parse(
      '${ApiConfig.baseUrl.replaceAll("/client", "")}/client/categories/search?q=$query',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = data['data'] ?? [];
        });
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    } catch (e) {
      debugPrint('Error searching: $e');
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _exitSearchMode() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _enterSearchMode() {
    setState(() {
      _isSearching = true;
      _searchController.clear();
      _searchResults = [];
    });
  }

  // ============ Navigation Helpers ============
  void _navigateToSection(String title) {
    final routes = {
      'หมวดหมู่อาหาร': () => FoodCategoryListPage(List: _allFoods),
      'ร้านค้าที่เข้าร่วม': () => const MarketListPage(),
      'ร้านค้าแอดมิน': () => const AdminMarketListPage(),
      'เมนูแนะนำ': () => const RecommendedMenuListPage(),
      'เมนูทั้งหมด': () => const AllMenuListPage(),
    };

    final page = routes[title];
    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => page()));
    }
  }

  // ============ Build Methods ============
  @override
  Widget build(BuildContext context) {
    if (_isSearching) {
      return _buildSearchView();
    }

    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: Colors.green.shade400,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : _buildMainContent(size, isTablet),
      ),
    );
  }

  Widget _buildSearchView() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildSearchAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
          ? const Center(child: Text('ไม่พบเมนูที่ค้นหา'))
          : _buildSearchResults(),
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      leadingWidth: 40,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4),
            ],
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _searchFoods,
            decoration: InputDecoration(
              hintText: 'ค้นหาเมนูอาหารที่คุณต้องการ...',
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _exitSearchMode,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.green,
      toolbarHeight: 60,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: _exitSearchMode,
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final food = _searchResults[index];
        return _buildSearchResultItem(food);
      },
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> food) {
    final name = food['food_name'] ?? 'ไม่ระบุชื่อ';
    final shopName = food['shop_name'] ?? 'ร้านไม่ระบุชื่อ';
    final image = food['image_url'] ?? 'https://via.placeholder.com/150';
    final price = food['sell_price'] ?? food['price'] ?? 0;
    final rating = double.tryParse(food['rating_avg']?.toString() ?? '') ?? 0.0;
    final foodId = food['food_id'];

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          image,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(shopName, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.star,
                size: 16,
                color: rating > 0 ? Colors.amber : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                rating > 0 ? rating.toStringAsFixed(1) : "ใหม่",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      trailing: Text(
        '$price ฿',
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderFoodPage(foodId: foodId),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(Size size, bool isTablet) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildHeader(size, isTablet),
        _buildContentSection(size, isTablet),
      ],
    );
  }

  Widget _buildHeader(Size size, bool isTablet) {
    final isLargeTablet = size.width >= 900;

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF34C759),
              Color.fromARGB(255, 84, 205, 90),
              Color(0xFF28A745),
            ],
            stops: [0.0, 0.5, 1.0],
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
              _buildTopBar(size, isTablet, isLargeTablet),
              SizedBox(height: isTablet ? 28 : 20),
              _buildSearchBar(size, isTablet),
              SizedBox(height: isTablet ? 32 : 24),
              _buildWelcomeText(size, isTablet, isLargeTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(Size size, bool isTablet, bool isLargeTablet) {
    return Row(
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
            _buildTopIconButton(isTablet, Icons.shopping_cart, '/basket'),
            SizedBox(width: isTablet ? 16 : 12),
            _buildTopIconButton(isTablet, Icons.person, '/dashboard'),
          ],
        ),
      ],
    );
  }

  Widget _buildTopIconButton(bool isTablet, IconData icon, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
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

  Widget _buildSearchBar(Size size, bool isTablet) {
    return Container(
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
        controller: _searchController,
        readOnly: true,
        onTap: _enterSearchMode,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: Icon(
              Icons.search,
              size: isTablet ? 28 : 22,
              color: Colors.grey[600],
            ),
          ),
          // suffixIcon: Container(
          //   margin: EdgeInsets.all(isTablet ? 8 : 6),
          //   decoration: BoxDecoration(
          //     gradient: const LinearGradient(
          //       colors: [Color(0xFF34C759), Color(0xFF28A745)],
          //     ),
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: Icon(
          //     Icons.tune,
          //     color: Colors.white,
          //     size: isTablet ? 22 : 18,
          //   ),
          // ),
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
    );
  }

  Widget _buildWelcomeText(Size size, bool isTablet, bool isLargeTablet) {
    return Text(
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
    );
  }

  Widget _buildContentSection(Size size, bool isTablet) {
    return SliverToBoxAdapter(
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
            _buildHandleBar(),
            const SizedBox(height: 24),
            _buildSection(
              'หมวดหมู่อาหาร',
              size,
              isTablet,
              _buildCategoriesSection,
            ),
            _buildSection(
              'ร้านค้าที่เข้าร่วม',
              size,
              isTablet,
              _buildStoresSection,
            ),
            _buildSection(
              'ร้านค้าแอดมิน',
              size,
              isTablet,
              _buildStoresAdminSection,
            ),
            _buildSection(
              'เมนูแนะนำ',
              size,
              isTablet,
              _buildRecommendedMenusGrid,
            ),
            _buildSection('เมนูทั้งหมด', size, isTablet, _buildAllMenusGrid),
            SizedBox(height: isTablet ? 60 : 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHandleBar() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSection(
    String title,
    Size size,
    bool isTablet,
    Widget Function(Size, bool) builder,
  ) {
    return Column(
      children: [
        _buildSectionHeader(title, 'ดูทั้งหมด', isTablet, size),
        const SizedBox(height: 16),
        builder(size, isTablet),
        const SizedBox(height: 32),
        _buildDivider(),
        const SizedBox(height: 32),
      ],
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
            onPressed: () => _navigateToSection(title),
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

  // ============ Categories Section ============
  Widget _buildCategoriesSection(Size size, bool isTablet) {
    return FutureBuilder<http.Response>(
      future: http.get(Uri.parse('${ApiConfig.baseUrl}/categories')),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: isTablet ? 175 : size.width * 0.38,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.statusCode != 200) {
          return SizedBox(
            height: isTablet ? 175 : size.width * 0.38,
            child: const Center(child: Text('ไม่พบหมวดหมู่')),
          );
        }

        final jsonData = json.decode(snapshot.data!.body);
        final List<dynamic> categories = jsonData['data'] ?? [];

        return SizedBox(
          height: isTablet ? 175 : size.width * 0.38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _buildCategoryItem(
                size,
                isTablet,
                cat['cate_image_url'] ?? '',
                cat['name'] ?? '',
                cat['id'] ?? 0,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(
    Size size,
    bool isTablet,
    String iconUrl,
    String label,
    int categoryId,
  ) {
    return Padding(
      padding: EdgeInsets.only(right: isTablet ? 20 : 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FoodListByCategoryPage(
                categoryId: categoryId,
                categoryName: label,
              ),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isTablet ? 100 : size.width * 0.22,
              height: isTablet ? 100 : size.width * 0.22,
              decoration: BoxDecoration(
                color: Colors.white,
                // shape: BoxShape.circle, // <-- ลบ property นี้ออก
                borderRadius: BorderRadius.circular(
                  12.0,
                ), // <-- เพิ่มเข้ามาเพื่อให้ขอบมน
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              // เพิ่ม ClipRRect เพื่อตัดขอบรูปภาพให้มนตาม Container
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  12.0,
                ), // <-- ใช้ค่าเดียวกับ Container
                child: iconUrl.isNotEmpty
                    ? Image.network(
                        iconUrl,
                        // width และ height ไม่ต้องกำหนดที่นี่แล้ว เพราะจะเต็มกรอบของ Container
                        fit: BoxFit
                            .cover, // <-- เปลี่ยนเป็น cover เพื่อให้รูปเต็มและคงสัดส่วน
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.broken_image,
                              size: 32,
                              color: Colors.grey,
                            ),
                      )
                    : Image.asset(
                        'assets/menus/fast1.png',
                        fit: BoxFit.cover, // <-- เปลี่ยนเป็น cover เช่นกัน
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
      ),
    );
  }

  // ============ Stores Sections ============
  Widget _buildStoresSection(Size size, bool isTablet) {
    final displayMarkets = _allMarkets
        .where((market) => market['is_admin'] == false)
        .take(10)
        .toList();

    return _buildStoresList(size, isTablet, displayMarkets);
  }

  Widget _buildStoresAdminSection(Size size, bool isTablet) {
    final displayMarkets = _adminMarkets.take(10).toList();
    return _buildStoresList(size, isTablet, displayMarkets);
  }

  Widget _buildStoresList(Size size, bool isTablet, List<dynamic> markets) {
    return SizedBox(
      height: isTablet ? 160 : size.width * 0.35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
        itemCount: markets.length,
        itemBuilder: (context, index) {
          final market = markets[index];
          return Padding(
            padding: EdgeInsets.only(right: isTablet ? 20 : 16),
            child: _buildStoreItem(
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

  Widget _buildStoreItem(
    Size size,
    bool isTablet,
    int marketId,
    String shopName,
    String imageUrl,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RouteWrapper(
              child: StoreMenuPage(marketID: marketId),
              routeName: '/storeMenu',
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: isTablet ? 120 : size.width * 0.22,
            height: isTablet ? 120 : size.width * 0.22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                isTablet ? 60 : size.width * 0.11,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 8 : size.height * 0.01),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 4),
            child: Text(
              shopName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  // ============ Menu Sections ============
  Widget _buildRecommendedMenusGrid(Size size, bool isTablet) {
    final recommendedFoods = _allFoods
        .where((food) {
          final rating =
              double.tryParse(food['rating_avg']?.toString() ?? '0') ?? 0.0;
          return rating >= 3;
        })
        .take(20)
        .toList();

    return _buildMenuGrid(size, isTablet, recommendedFoods);
  }

  Widget _buildAllMenusGrid(Size size, bool isTablet) {
    final displayFoods = _allFoods.take(20).toList();
    return _buildMenuGrid(size, isTablet, displayFoods);
  }

  Widget _buildMenuGrid(Size size, bool isTablet, List<dynamic> foods) {
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
        itemCount: foods.length,
        itemBuilder: (context, index) {
          final food = foods[index];
          return _buildMenuCard(size, isTablet, food);
        },
      ),
    );
  }

  Widget _buildMenuCard(Size size, bool isTablet, Map<String, dynamic> food) {
    final title = food['food_name'] ?? '';
    final shop = food['shop_name'] ?? '';
    final price = double.tryParse(food['sell_price']?.toString() ?? '0') ?? 0.0;
    final imagePath = food['image_url'] ?? '';
    final rating =
        double.tryParse(food['rating_avg']?.toString() ?? '0') ?? 0.0;
    final foodId = food['food_id'] ?? 0;

    return GestureDetector(
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
              color: const Color.fromARGB(255, 114, 114, 114).withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildMenuImage(size, isTablet, imagePath, rating),
            SizedBox(height: isTablet ? 12 : size.height * 0.01),
            _buildMenuTitle(size, isTablet, title),
            SizedBox(height: isTablet ? 6 : size.height * 0.005),
            _buildMenuShop(size, isTablet, shop),
            const Spacer(),
            _buildMenuPrice(size, isTablet, price),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuImage(
    Size size,
    bool isTablet,
    String imagePath,
    double rating,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isTablet ? 12 : size.width * 0.02),
      child: Stack(
        children: [
          Image.network(
            imagePath,
            height: isTablet ? 120 : size.width * 0.25,
            width: double.infinity,
            fit: BoxFit.cover,
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
              return Container(
                height: isTablet ? 120 : size.width * 0.25,
                width: double.infinity,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, size: 50),
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
                color: const Color(0xFF34C759).withOpacity(0.8),
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
    );
  }

  Widget _buildMenuTitle(Size size, bool isTablet, String title) {
    return Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: isTablet ? 18 : size.width * 0.04,
      ),
    );
  }

  Widget _buildMenuShop(Size size, bool isTablet, String shop) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        shop,
        style: TextStyle(
          fontSize: isTablet ? 14 : size.width * 0.03,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMenuPrice(Size size, bool isTablet, double price) {
    return Row(
      children: [
        const Spacer(),
        Text(
          '\฿ $price.-',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
            fontSize: isTablet ? 16 : size.width * 0.035,
          ),
        ),
      ],
    );
  }
}
