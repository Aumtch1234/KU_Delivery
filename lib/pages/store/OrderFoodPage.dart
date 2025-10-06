import 'package:delivery/APIs/Carts/Carts.dart';
import 'package:delivery/APIs/Foods/OrderFoodAPI.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../basket/providers/basket_provider.dart';
import '../store/models/food_detail_model.dart';
import 'dart:async';

class OrderFoodPage extends StatefulWidget {
  final int foodId;

  const OrderFoodPage({Key? key, required this.foodId}) : super(key: key);

  @override
  State<OrderFoodPage> createState() => _OrderFoodPageState();
}

class _OrderFoodPageState extends State<OrderFoodPage> {
  FoodDetail? foodDetail;
  bool isLoading = true;
  int quantity = 1;
  List<bool> selectedOptions = []; // เปลี่ยนจาก int เป็น List<bool>
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFood();
  }

  Future<void> _loadFood() async {
    final controller = FoodOrderController();
    final data = await controller.getFoodDetail(widget.foodId);
    setState(() {
      foodDetail = data;
      // สร้าง list ของ selectedOptions ตามจำนวนตัวเลือก
      selectedOptions = List.generate(
        data?.options.length ?? 0,
        (index) => false,
      );
      isLoading = false;
    });
  }

  double get totalPrice {
    if (foodDetail == null) return 0.0;
    double optionPrice = 0.0;

    // คำนวณราคาจากตัวเลือกที่เลือก
    for (int i = 0; i < selectedOptions.length; i++) {
      if (selectedOptions[i]) {
        optionPrice += foodDetail!.options[i].extraPrice;
      }
    }

    return (foodDetail!.sell_price + optionPrice) * quantity;
  }

  String get selectedOptionsText {
    List<String> selected = [];
    for (int i = 0; i < selectedOptions.length; i++) {
      if (selectedOptions[i]) {
        selected.add(foodDetail!.options[i].label);
      }
    }
    return selected.isEmpty ? 'ปกติ' : selected.join(', ');
  }

  void _orderNow(BuildContext context) async {
    if (foodDetail == null) return;

    final selectedOpts = <Map<String, dynamic>>[];
    for (int i = 0; i < selectedOptions.length; i++) {
      if (selectedOptions[i]) {
        selectedOpts.add({
          "label": foodDetail!.options[i].label,
          "extraPrice": foodDetail!.options[i].extraPrice,
        });
      }
    }

    final success = await CartAPI.addToCart(
      foodId: widget.foodId,
      quantity: quantity,
      selectedOptions: selectedOpts,
      note: noteController.text,
    );

    if (success) {
      Navigator.pushNamed(context, '/order-now');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('สั่งไม่สำเร็จ')));
    }
  }

  void _addToBasket(BuildContext context) async {
    if (foodDetail == null) return;

    // ✅ แปลง selectedOptions ให้เป็น List<Map>
    final selectedOpts = <Map<String, dynamic>>[];
    for (int i = 0; i < selectedOptions.length; i++) {
      if (selectedOptions[i]) {
        selectedOpts.add({
          "label": foodDetail!.options[i].label,
          "extraPrice": foodDetail!.options[i].extraPrice,
        });
      }
    }

    final success = await CartAPI.addToCart(
      foodId: widget.foodId,
      quantity: quantity,
      selectedOptions: selectedOpts,
      note: noteController.text,
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เพิ่มลงตะกร้าแล้ว')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เพิ่มตะกร้าไม่สำเร็จ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFF34C759),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: foodDetail != null
            ? Text(
                foodDetail!.foodName,
                style: const TextStyle(color: Colors.black),
              )
            : const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
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
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.shopping_cart, color: Colors.black),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : foodDetail == null
          ? const Center(child: Text('ไม่พบข้อมูลอาหาร'))
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 48 : 24,
                    vertical: isTablet ? 32 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          foodDetail!.imageUrl,
                          width: double.infinity,
                          height: isTablet ? 320 : size.width * 0.5,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Quantity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            foodDetail!.foodName,
                            style: TextStyle(
                              fontSize: isTablet ? 24 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.green,
                                ),
                                onPressed: quantity > 1
                                    ? () => setState(() => quantity--)
                                    : null,
                              ),
                              Text(
                                '$quantity',
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.green,
                                ),
                                onPressed: () => setState(() => quantity++),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(thickness: 1, color: Colors.grey),

                      // ส่วนตัวเลือกเพิ่มเติมที่ปรับปรุงแล้ว
                      if (foodDetail!.options.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.restaurant_menu,
                                    color: Colors.green[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ตัวเลือกเพิ่มเติม',
                                    style: TextStyle(
                                      fontSize: isTablet ? 18 : 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'เลือกได้หลายรายการ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...List.generate(foodDetail!.options.length, (i) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedOptions[i] = !selectedOptions[i];
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selectedOptions[i]
                                          ? Colors.green[50]
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: selectedOptions[i]
                                            ? Colors.green
                                            : Colors.grey[200]!,
                                        width: selectedOptions[i] ? 2 : 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: selectedOptions[i]
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.grey.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Custom Checkbox
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: selectedOptions[i]
                                                ? Colors.green
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: selectedOptions[i]
                                                  ? Colors.green
                                                  : Colors.grey[400]!,
                                              width: 2,
                                            ),
                                          ),
                                          child: selectedOptions[i]
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 14,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        // Option Label
                                        Expanded(
                                          child: Text(
                                            foodDetail!.options[i].label,
                                            style: TextStyle(
                                              fontWeight: selectedOptions[i]
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              fontSize: 15,
                                              color: selectedOptions[i]
                                                  ? Colors.green[700]
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        // Price Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: selectedOptions[i]
                                                ? Colors.green
                                                : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          child: Text(
                                            '+${foodDetail!.options[i].extraPrice.toStringAsFixed(0)} ฿',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: selectedOptions[i]
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(thickness: 1, color: Colors.grey),
                      ],

                      // Total Price
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ราคารวมทั้งหมด',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            Text(
                              '${totalPrice.toStringAsFixed(0)} ฿',
                              style: TextStyle(
                                fontSize: isTablet ? 22 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Note
                      Text(
                        'รายละเอียดเพิ่มเติม',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'เช่น ไม่เอาผัก, เอาน้ำแข็งเยอะๆ',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.green,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Buttons
                      Row(
                        children: [
                          // Expanded(
                          //   child: ElevatedButton.icon(
                          //     onPressed: () => _orderNow(context),
                          //     icon: const Icon(
                          //       Icons.flash_on,
                          //       color: Colors.white,
                          //     ),
                          //     label: const Text(
                          //       'สั่งเลย',
                          //       style: TextStyle(
                          //         fontSize: 18,
                          //         color: Colors.white,
                          //         fontWeight: FontWeight.w600,
                          //       ),
                          //     ),
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: Colors.grey[700],
                          //       padding: const EdgeInsets.symmetric(
                          //         vertical: 16,
                          //       ),
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(12),
                          //       ),
                          //       elevation: 2,
                          //     ),
                          //   ),
                          // ),
                          // const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _addToBasket(context),
                              icon: const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'ใส่ตะกร้า',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
