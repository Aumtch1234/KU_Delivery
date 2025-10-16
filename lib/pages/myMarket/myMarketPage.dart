import 'package:delivery/APIs/Markets/updateManualOverride.dart';
import 'package:delivery/pages/bottom/MainNavigation.dart';
import 'package:delivery/pages/myMarket/OrdersListPage.dart';
import 'package:flutter/material.dart';
import 'package:delivery/APIs/Markets/FetchFoodsForMarket.dart';
import 'package:delivery/APIs/Markets/FetchMarket.dart';
import 'package:delivery/APIs/Markets/MarketStatusToggleAPI.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class Mymarketpage extends StatefulWidget {
  const Mymarketpage({Key? key}) : super(key: key);

  @override
  _MymarketpageState createState() => _MymarketpageState();
}

class _MymarketpageState extends State<Mymarketpage> {
  List<dynamic> foodList = [];
  List<dynamic> filteredFoodList = [];
  String marketId = '';
  String storeName = '';
  String imageStoreURL = '';
  String storeDescription = '';
  String opened = '';
  String closed = '';
  bool isLoading = true;
  bool isManualOverride = false;
  bool isOpen = true;
  bool is_visible = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ตัวแปรสำหรับ Filter และ Search
  String selectedFilter = 'ทั้งหมด'; // ทั้งหมด, พร้อมขาย, ไม่พร้อมขาย
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadMarket();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadMarket() async {
    try {
      print('⏳ เรียก fetchMyMarket...');
      final market = await fetchMyMarket();
      print('✅ market: $market');
      final fetchedFoods = await FetchFoodsForMarket();
      print('✅ foods: $fetchedFoods');

      // 🧩 Log ค่า is_visible ของแต่ละเมนู
      if (fetchedFoods != null) {
        for (var f in fetchedFoods) {
          print('🍽️ ${f['food_name']} | is_visible = ${f['is_visible']}');
        }
      }

      setState(() {
        if (market != null && fetchedFoods != null) {
          marketId = market['market_id'].toString();
          storeName = market['shop_name'] ?? 'ไม่มีชื่อร้าน';
          imageStoreURL = market['shop_logo_url'] ?? '';
          storeDescription = market['shop_description'] ?? '';
          opened = market['open_time'] ?? 'ไม่ได้ตั้งเวลาเปิดร้าน';
          closed = market['close_time'] ?? 'ไม่ได้ตั้งเวลาปิดร้าน';
          isOpen = market['is_open'] ?? true;
          isManualOverride = market['is_manual_override'] ?? false;
          foodList = fetchedFoods;
          is_visible = market['is_visible'] ?? true;
          _filterFoodList(); // กรองข้อมูลหลังโหลด
        } else {
          storeName = 'ไม่พบข้อมูลร้านค้า';
          storeDescription = '';
          foodList = [];
          filteredFoodList = [];
        }
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error in loadMarket: $e');
      setState(() {
        storeName = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
        storeDescription = '';
        foodList = [];
        filteredFoodList = [];
        isLoading = false;
      });
    }
  }

  // ฟังก์ชันกรองข้อมูล
  void _filterFoodList() {
    List<dynamic> result = foodList.where((food) {
      // กรองตามหมวดหมู่
      bool matchesCategory = true;
      if (selectedFilter == 'พร้อมขาย') {
        matchesCategory = food['is_visible'] == true;
      } else if (selectedFilter == 'ไม่พร้อมขาย') {
        matchesCategory = food['is_visible'] == false;
      }

      // กรองตามชื่อเมนู
      bool matchesSearch = true;
      if (searchController.text.isNotEmpty) {
        String foodName = (food['food_name'] ?? '').toString().toLowerCase();
        String searchText = searchController.text.toLowerCase();
        matchesSearch = foodName.contains(searchText);
      }

      return matchesCategory && matchesSearch;
    }).toList();

    filteredFoodList = result;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      key: _scaffoldKey,
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
                        // ข้อมูลร้าน + ปุ่มเปิดปิด
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
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
                                  const SizedBox(height: 8),
                                  Text(
                                    storeName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    storeDescription,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "ร้านเปิด $opened - $closed น.",
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
                              onTap: () async {
                                if (!isManualOverride) {
                                  AwesomeDialog(
                                    context: context,
                                    dialogType: DialogType.warning,
                                    animType: AnimType.bottomSlide,
                                    title: 'ไม่ได้เปิดโหมดควบคุมร้านเอง',
                                    desc:
                                        'กรุณาเปิด "ควบคุมร้านด้วยตนเอง" ก่อนจึงจะสามารถสั่งเปิด/ปิดร้านได้',
                                    btnOkText: 'เปิดเมนู',
                                    btnOkOnPress: () {
                                      _scaffoldKey.currentState?.openDrawer();
                                    },
                                    btnCancelOnPress: () {},
                                  ).show();
                                  return;
                                }

                                if (marketId.isEmpty) return;
                                setState(() => isLoading = true);
                                bool newStatus = !isOpen;

                                try {
                                  bool success = await toggleMarketStatus(
                                    newStatus,
                                    marketId,
                                  );
                                  if (success) {
                                    await loadMarket();

                                    if (isManualOverride) {
                                      AwesomeDialog(
                                        context: context,
                                        dialogType: DialogType.success,
                                        animType: AnimType.bottomSlide,
                                        title: 'สำเร็จ',
                                        desc:
                                            'เปลี่ยนสถานะร้านเรียบร้อยแล้ว\n\nอย่าลืมปิด "ควบคุมร้านด้วยตนเอง" เมื่อจะปิดร้าน ^^',
                                        btnOkOnPress: () {},
                                      ).show();
                                    }
                                  } else {
                                    setState(() => isLoading = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'ไม่สามารถอัปเดตสถานะร้านได้',
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print('Error during toggle: $e');
                                  setState(() => isLoading = false);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isOpen
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isOpen
                                          ? Colors.green.withOpacity(0.4)
                                          : Colors.red.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isOpen
                                          ? Icons.storefront
                                          : Icons.store_mall_directory,
                                      color: isOpen
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isOpen ? 'เปิดอยู่' : 'ปิดอยู่',
                                      style: TextStyle(
                                        color: isOpen
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // 🔍 ช่องค้นหา
                        TextField(
                          controller: searchController,
                          onChanged: (value) {
                            setState(() {
                              _filterFoodList(); // กรองทันทีเมื่อพิมพ์
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'ค้นหาชื่อเมนู...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        searchController.clear();
                                        _filterFoodList(); // กรองใหม่หลังลบ
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 🏷️ ปุ่มหมวดหมู่
                        Row(
                          children: [
                            _buildCategoryChip('ทั้งหมด', foodList.length),
                            const SizedBox(width: 8),
                            _buildCategoryChip(
                              'พร้อมขาย',
                              foodList.where((f) => f['is_visible'] == true).length,
                            ),
                            const SizedBox(width: 8),
                            _buildCategoryChip(
                              'ไม่พร้อมขาย',
                              foodList.where((f) => f['is_visible'] == false).length,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // แสดงจำนวนผลลัพธ์
                        Text(
                          'พบ ${filteredFoodList.length} เมนู',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Grid แสดงเมนู
                        filteredFoodList.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'ไม่พบเมนูที่ค้นหา',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : GridView.count(
                                crossAxisCount: isTablet ? 3 : 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: filteredFoodList.map((food) {
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

  // Widget สำหรับปุ่มหมวดหมู่
  Widget _buildCategoryChip(String label, int count) {
    bool isSelected = selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = label;
            _filterFoodList();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF34C759) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF34C759).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '($count)',
                style: TextStyle(
                  color: isSelected ? Colors.white70 : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
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
                leading: const Icon(Icons.bar_chart, color: Colors.white),
                title: const Text(
                  'สรุปยอดขาย',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.pushNamed(
                    context,
                    '/dashboard-sales',
                    arguments: {'marketId': int.tryParse(marketId) ?? 0},
                  );
                  if (result == true) {
                    await loadMarket();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.add, color: Colors.white),
                title: const Text(
                  'เพิ่มอาหาร',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/addFood').then((onValue) {
                    if (onValue == true) {
                      setState(() {
                        isLoading = true;
                      });
                      loadMarket().then((_) {
                        setState(() {
                          isLoading = false;
                        });
                      });
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_attributes, color: Colors.white),
                title: const Text(
                  'แก้ไขข้อมูลร้านค้า',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.pushNamed(
                    context,
                    '/myMarket/edit',
                  );
                  if (result == true) {
                    await loadMarket();
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.work_off_outlined,
                  color: Colors.white,
                ),
                title: const Text(
                  'รับงาน',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OrdersListPage(marketId: int.tryParse(marketId)),
                    ),
                  );
                  if (result == true) {
                    await loadMarket();
                  }
                },
              ),
              SwitchListTile(
                title: const Text(
                  'ควบคุมร้านด้วยตนเอง',
                  style: TextStyle(color: Colors.white),
                ),
                value: isManualOverride,
                activeColor: Colors.white,
                onChanged: (bool value) async {
                  setState(() => isLoading = true);
                  bool success = await updateManualOverrideAPI(
                    marketId,
                    value,
                    isOpen,
                  );

                  if (success) {
                    setState(() {
                      isManualOverride = value;
                    });
                    await loadMarket();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ไม่สามารถอัปเดต Manual Override ได้'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  setState(() => isLoading = false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text(
                  'ออกจากร้านค้า',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MainNavigation(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
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
    print(
      '🧾 สร้างการ์ด: ${foodData['food_name']} | is_visible = ${foodData['is_visible']}',
    );

    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final price = double.tryParse(foodData['price'].toString()) ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/editFood', arguments: foodData).then((
          onValue,
        ) {
          if (onValue == true) {
            setState(() {
              isLoading = true;
            });
            loadMarket().then((_) {
              setState(() {
                isLoading = false;
              });
            });
          }
        });
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    foodData['image_url'] ?? 'https://via.placeholder.com/150',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (foodData['is_visible'] == true)
                          ? Colors.green.withOpacity(0.8)
                          : Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (foodData['is_visible'] == true)
                          ? 'พร้อมขาย'
                          : 'ไม่พร้อมขาย',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
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
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                const SizedBox(width: 4),
                Text(
                  (() {
                    final rating =
                        double.tryParse(
                          foodData['rating_avg']?.toString() ?? '0',
                        ) ??
                        0;
                    return rating > 0
                        ? rating.toStringAsFixed(1)
                        : 'ยังไม่มีรีวิว';
                  })(),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
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