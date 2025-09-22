import 'dart:convert';

import 'package:delivery/APIs/GoogleMap/DistanceAPI.dart';
import 'package:delivery/APIs/Orders/OrdersAPI.dart';
import 'package:delivery/APIs/SOCKET_IO/SocketService.dart';
import 'package:delivery/APIs/Users/AddAddressAPI.dart';
import 'package:delivery/main.dart';
import 'package:delivery/pages/LoadingOverlay/LoadingOverlay.dart';
import 'package:delivery/pages/basket/models/basket_item.dart';
import 'package:delivery/pages/bottom/CustomerOrderPage.dart';
import 'package:delivery/pages/bottom/MainNavigation.dart';
import 'package:delivery/pages/my_Address/models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../basket/providers/basket_provider.dart';

class OrderNowPage extends StatefulWidget {
  static const routeName = '/order-now';
  const OrderNowPage({super.key});

  @override
  State<OrderNowPage> createState() => _OrderNowPageState();
}

class _OrderNowPageState extends State<OrderNowPage> {
  int? userId;
  bool isLoading = true; // 🔥 state สำหรับโหลด

  String deliveryType = 'แบบ/วางไว้จุดที่ระบุ';
  String paymentMethod = 'เงินสด';
  TextEditingController noteController = TextEditingController();

  ShippingAddress? defaultAddress; // <-- เก็บ address หลัก
  double? distanceInKm; // ระยะทางจากร้านไปที่อยู่ลูกค้า

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => isLoading = true);
    await _loadUserId();
    await _loadDefaultAddress();
    final basket = Provider.of<BasketProvider>(context, listen: false);
    final selectedItems = basket.items.where((e) => e.selected).toList();
    await _calculateDistances(selectedItems);
    setState(() => isLoading = false); // ✅ เสร็จแล้วค่อยปิดโหลด
  }

  Map<int, double> distanceMap = {}; // marketId -> distance
  Map<int, double> durationMap = {}; // marketId -> distance

  Future<void> _calculateDistances(List<BasketItem> items) async {
    if (defaultAddress == null || items.isEmpty) return;

    final basketForAPI = items
        .map((item) => {'marketId': item.marketId})
        .toList();

    try {
      // เรียก API สำหรับ basket ทั้งหมด
      final distances = await DistanceAPI.getDistanceByBasket(
        basket: basketForAPI,
      );

      setState(() {
        distanceMap.clear();
        durationMap.clear(); // เพิ่ม map สำหรับเวลา
        for (var d in distances) {
          final marketId = d['marketId'];
          // distance (km)
          distanceMap[marketId] =
              double.tryParse(d['distance'].toString().replaceAll(' km', '')) ??
              0.0;
          // duration (นาที)
          durationMap[marketId] =
              double.tryParse(
                d['duration'].toString().replaceAll(' นาที', ''),
              ) ??
              0.0;
        }
      });

      print("📍 Distances by store: $distanceMap");
      print("⏱ Duration by store: $durationMap");
    } catch (e) {
      print("❌ Error calculating distances: $e");
    }
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      final userData = jsonDecode(userStr);
      setState(() {
        userId = userData['user_id'];
      });
    }
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final result =
          await DeliveryAddressAPI.GetDefaultAddress(); // เรียก API ใหม่

      if (result['success'] == true &&
          result['data'] != null &&
          result['data'].isNotEmpty) {
        // มี address หลัก
        setState(() {
          defaultAddress = ShippingAddress.fromJson(result['data'][0]);
          addressInfo = {
            'place': defaultAddress!.address,
            'notes': defaultAddress!.notes ?? '',
          };
        });
        print("📦 Address: ${defaultAddress!.address}");
        print("👤 Name: ${defaultAddress!.name}");
        print("📞 Phone: ${defaultAddress!.phone}");
        print("📝 Notes: ${defaultAddress!.notes ?? 'ไม่มีหมายเหตุ'}");
      } else {
        setState(() {
          defaultAddress = null;
          addressInfo = null;
        });
        print("⚠️ ไม่มีที่อยู่ในระบบ");
      }
    } catch (e) {
      print("❌ Error loading default address: $e");
      setState(() {
        defaultAddress = null;
        addressInfo = null;
      });
    }
  }

  Map<String, dynamic>? addressInfo;

  @override
  Widget build(BuildContext context) {
    final basket = Provider.of<BasketProvider>(context);
    final items = basket.items.where((e) => e.selected).toList();
    final total = basket.totalSelectedPrice;

    return LoadingOverlay(
      isLoading: isLoading, // ✅ ใช้ state
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildCustomAppBar(),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ส่วนที่อยู่จัดส่ง
                      _buildAddressSection(),

                      // ส่วนรูปแบบการจัดส่ง
                      _buildDeliveryTypeSection(),

                      // ส่วนรายการอาหาร
                      _buildFoodItemsSection(items),

                      // ส่วนการชำระเงิน
                      _buildPaymentSection(),

                      //
                      _buildOrderReceipt(items),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Bottom Bar
              _buildBottomBar(items, total),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Expanded(
            child: Text(
              'ยืนยันออเดอร์',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    if (defaultAddress != null) {
      print("📦 Address: ${defaultAddress!.address}");
      print("👤 Name: ${defaultAddress!.name}");
      print("📞 Phone: ${defaultAddress!.phone}");
      print("📝 Notes: ${defaultAddress!.notes ?? 'ไม่มีหมายเหตุ'}");

      // ถ้า lat/lng มีค่า ให้คำนวณระยะทาง
      if (defaultAddress!.latitude != null &&
          defaultAddress!.longitude != null) {}
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF34C759),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'ที่อยู่จัดส่ง',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        defaultAddress?.address ?? "ยังไม่ได้เลือกที่อยู่",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        defaultAddress != null
                            ? "${defaultAddress!.name} - ${defaultAddress!.phone}"
                            : "ไม่มีข้อมูลผู้รับ",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (defaultAddress?.notes != null &&
                          defaultAddress!.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            defaultAddress!.notes!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      const SizedBox(height: 6),
                      // แสดงระยะทางถ้ามีค่า
                      if (distanceInKm != null)
                        Text(
                          "ระยะทางจากร้าน: ${distanceInKm!.toStringAsFixed(2)} กม.",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        const Text(
                          "ระยะทางจากร้าน: ไม่สามารถคำนวณได้",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // ปุ่มแก้ไข
                _buildEditAddressButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditAddressButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2EAD4D), Color(0xFF2EAD4D)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () async {
            final result = await Navigator.pushNamed(context, '/myaddress');
            if (result != null && result is Map<String, dynamic>) {
              setState(() {
                addressInfo = result;
              });
            }
            await _loadDefaultAddress(); // โหลด default address ใหม่

            // คำนวณระยะทางใหม่
            final basket = Provider.of<BasketProvider>(context, listen: false);
            final selectedItems = basket.items
                .where((e) => e.selected)
                .toList();
            await _calculateDistances(selectedItems);
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'แก้ไข',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryTypeSection() {
    final basket = Provider.of<BasketProvider>(context);
    final items = basket.items.where((e) => e.selected).toList();

    // คำนวณเวลาเฉลี่ยจาก durationMap
    double totalMinutes = 0;
    int count = 0;
    Map<int, double> durationMapLocal = durationMap;

    final Map<int, List<BasketItem>> itemsByMarket = {};
    for (var item in items) {
      itemsByMarket.putIfAbsent(item.marketId, () => []);
      itemsByMarket[item.marketId]!.add(item);
    }

    itemsByMarket.forEach((marketId, marketItems) {
      final mins = durationMapLocal[marketId] ?? 0.0;
      if (mins > 0) {
        totalMinutes += mins;
        count++;
      }
    });

    final averageMinutes = count > 0 ? (totalMinutes / count).round() : 35;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'รูปแบบการจัดส่ง',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _deliveryTypeButton(
                    'แนะนำ',
                    'แบบ/วางไว้จุดที่ระบุ',
                    deliveryType == 'แบบ/วางไว้จุดที่ระบุ',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _deliveryTypeButton(
                    '', // ไม่มี label
                    'ส่งถึงมือ/ออกมารับเอง',
                    deliveryType == 'ส่งถึงมือ/ออกมารับเอง',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Note Input
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'รายละเอียดเพิ่มเติม... (เช่น ห้องเลขที่ หรือชื่อผู้รับ)',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF34C759),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(18),
            ),
          ),

          const SizedBox(height: 20),

          // Delivery Time Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF34C759).withOpacity(0.12),
                  const Color(0xFF34C759).withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF34C759).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: const Color(0xFF34C759),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  'ส่งปกติ ประมาณ $averageMinutes นาที',
                  style: const TextStyle(
                    color: Color(0xFF34C759),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double calculateDeliveryFee(double km) {
    if (km <= 1) return 5;
    return (km * 5).floorToDouble(); // 5 บาท/กม. ปัดลง
  }

  // ใช้ map จาก state โดยตรง
  Widget _buildFoodItemsSection(List<BasketItem> items) {
    final Map<int, double> distanceMapLocal = distanceMap;
    final Map<int, double> durationMapLocal = durationMap;

    final Map<String, List<BasketItem>> itemsByStore = {};
    for (var item in items) {
      if (!itemsByStore.containsKey(item.storeName)) {
        itemsByStore[item.storeName] = [];
      }
      itemsByStore[item.storeName]!.add(item);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: Colors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'รายการอาหารที่สั่ง',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${items.length} รายการ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          ...itemsByStore.entries.map((entry) {
            final storeName = entry.key;
            final storeItems = entry.value;
            final storeTotal = storeItems.fold<double>(
              0,
              (sum, i) => sum + i.total,
            );

            final marketId = storeItems[0].marketId;
            final km = distanceMapLocal[marketId] ?? 0.0;
            final mins = durationMapLocal[marketId] ?? 0.0;

            final deliveryFee = calculateDeliveryFee(km);

            final distanceText = km > 0
                ? "ระยะทาง: ${km.toStringAsFixed(2)} กม. | ${mins.toStringAsFixed(0)} นาที"
                : "ไม่สามารถคำนวณระยะทางได้";

            final totalWithDelivery = storeTotal + deliveryFee;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    storeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    distanceText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ...storeItems.map(_orderItem).toList(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "รวมอาหาร: ${storeTotal.toStringAsFixed(0)} บาท",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF34C759),
                        ),
                      ),
                      Text(
                        "ค่าจัดส่ง: ${deliveryFee.toStringAsFixed(0)} บาท",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        "รวมทั้งหมด: ${totalWithDelivery.toStringAsFixed(0)} บาท",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF34C759),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(thickness: 1, height: 30),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payment,
                  color: Colors.purple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'ชำระเงินโดย',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: paymentMethod,
                borderRadius: BorderRadius.circular(14),
                icon: const Icon(Icons.expand_more, size: 22),
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: 'เงินสด',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34C759).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.attach_money,
                            color: Color(0xFF34C759),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'เงินสด',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'โอน',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34C759).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Color(0xFF34C759),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'โอน',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    paymentMethod = value!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(List<BasketItem> items, double totalFood) {
    // คำนวณค่าจัดส่งรวมทุกร้าน
    double totalDeliveryFee = 0;
    Map<int, List<BasketItem>> itemsByMarket = {};
    for (var item in items) {
      itemsByMarket.putIfAbsent(item.marketId, () => []);
      itemsByMarket[item.marketId]!.add(item);
    }

    itemsByMarket.forEach((marketId, marketItems) {
      final km = distanceMap[marketId] ?? 0.0;
      totalDeliveryFee += calculateDeliveryFee(km);
    });
    final totalAll = totalFood + totalDeliveryFee;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF34C759), Color(0xFF2EAD4D)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF34C759).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),

                  // Replace the order creation logic in your _buildBottomBar onTap method:
                  onTap: () async {
                    try {
                      // Group items by market and calculate totals per market
                      Map<int, List<BasketItem>> itemsByMarket = {};
                      Map<String, double> distancesByMarket = {};
                      Map<String, double> deliveryFeesByMarket = {};
                      Map<String, double> totalPricesByMarket = {};

                      // Group items by market
                      for (var item in items) {
                        itemsByMarket.putIfAbsent(item.marketId, () => []);
                        itemsByMarket[item.marketId]!.add(item);
                      }

                      // Calculate per-market data
                      itemsByMarket.forEach((marketId, marketItems) {
                        final km = distanceMap[marketId] ?? 0.0;
                        final deliveryFee = calculateDeliveryFee(km);
                        final foodTotal = marketItems.fold<double>(
                          0,
                          (sum, item) => sum + item.total,
                        );

                        distancesByMarket[marketId.toString()] = km;
                        deliveryFeesByMarket[marketId.toString()] = deliveryFee;
                        totalPricesByMarket[marketId.toString()] =
                            foodTotal + deliveryFee;
                      });

                      final basketForAPI = items.map((item) {
                        return {
                          "cart_id": item.cartId,
                          "food_id": item.foodId,
                          "food_name": item.foodName,
                          "market_id": item.marketId,
                          "shop_name": item.storeName,
                          "quantity": item.quantity,
                          "sell_price": item.sell_price,
                          "total": item.total, // Keep individual item total
                          "selected_options": item.selectedOptions,
                          "note": item.note,
                        };
                      }).toList();

                      final result = await OrdersAPI.createOrder(
                        basket: basketForAPI,
                        address: defaultAddress!.address,
                        note: noteController.text,
                        paymentMethod: paymentMethod,
                        deliveryType: deliveryType,
                        distances:
                            distancesByMarket, // Object with marketId keys
                        deliveryFees:
                            deliveryFeesByMarket, // Object with marketId keys
                        totalPrices:
                            totalPricesByMarket, // Object with marketId keys
                      );

                      print("✅ Order created: $result");
                      print("🛒 basketForAPI: $basketForAPI");
                      print("📍 distancesByMarket: $distancesByMarket");
                      print("🚚 deliveryFeesByMarket: $deliveryFeesByMarket");
                      print("💰 totalPricesByMarket: $totalPricesByMarket");

                      if (result['success'] == true &&
                          result['orders'] != null &&
                          result['orders'].isNotEmpty) {
                        final orderId = result['orders'][0]['order_id'];
                        print("✅ Order created with ID: $orderId");

                        // เรียก getOrderStatus ด้วย orderId จริง
                        await OrdersAPI.getOrderStatus(orderId);

                        SocketService().emitNewOrder(result);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "สั่งอาหารเรียบร้อย! รอร้านค้ารับงาน...",
                            ),
                          ),
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RouteWrapper(
                              child: CustomerOrderPage(userId: userId),
                              routeName: 'customer_order',
                            ),
                          ),
                        ).then((_) {
                          // เวลากด back ออกจาก CustomerOrderPage ให้ไป ShopPage
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RouteWrapper(
                                child: MainNavigation(),
                                routeName: 'main_navigation',
                              ),
                            ),
                          );
                        });
                      } else {
                        print("❌ Failed to create order: ${result['message']}");
                      }
                    } catch (e) {
                      print("❌ Order error: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("เกิดข้อผิดพลาดในการสั่งซื้อ"),
                        ),
                      );
                    }
                  },

                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '${items.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Text(
                          'สั่งเลย',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          '${totalAll.toStringAsFixed(0)} บาท',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderItem(BasketItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // รูปอาหาร
          if (item.imagePath.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  item.imagePath,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (item.imagePath.isNotEmpty) const SizedBox(width: 18),

          // ข้อมูลอาหาร
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.foodName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.black87,
                  ),
                ),
                if (item.optionsText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      item.optionsText,
                      style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                    ),
                  ),
                if (item.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Text(
                        "หมายเหตุ: ${item.note}",
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // จำนวนและราคา
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "x${item.quantity}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "${item.total.toStringAsFixed(0)} บาท",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Color(0xFF34C759),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deliveryTypeButton(String label, String value, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          deliveryType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF34C759), Color(0xFF2EAD4D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF34C759).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // เว้นช่องว่างให้เท่ากัน
            label.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withOpacity(0.25)
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? Colors.white : Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : SizedBox(height: 22), // fix height ของ label
            const SizedBox(height: 10),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black87,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderReceipt(List<BasketItem> items) {
    final Map<int, double> distanceMapLocal = distanceMap;

    final Map<String, List<BasketItem>> itemsByStore = {};
    for (var item in items) {
      itemsByStore.putIfAbsent(item.storeName, () => []);
      itemsByStore[item.storeName]!.add(item);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'บิลรายการสั่งซื้อ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          ...itemsByStore.entries.map((entry) {
            final storeName = entry.key;
            final storeItems = entry.value;
            final storeTotal = storeItems.fold<double>(
              0,
              (sum, i) => sum + i.total,
            );

            final marketId = storeItems[0].marketId;
            final km = distanceMapLocal[marketId] ?? 0.0;
            final deliveryFee = calculateDeliveryFee(km);
            final totalWithDelivery = storeTotal + deliveryFee;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                ...storeItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "${item.foodName} x${item.quantity}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              "${item.total.toStringAsFixed(0)} บาท",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF34C759),
                              ),
                            ),
                          ],
                        ),
                        if (item.optionsText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Text(
                              item.optionsText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("รวมอาหาร"),
                    Text("${storeTotal.toStringAsFixed(0)} บาท"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("ค่าจัดส่ง"),
                    Text("${deliveryFee.toStringAsFixed(0)} บาท"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "รวมทั้งหมด",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${totalWithDelivery.toStringAsFixed(0)} บาท",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF34C759),
                      ),
                    ),
                  ],
                ),
                const Divider(thickness: 1, height: 30),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }
}
