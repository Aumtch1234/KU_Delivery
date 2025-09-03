import 'package:delivery/APIs/Foods/OrderFoodAPI.dart';
import 'package:delivery/models/basket_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/basket_provider.dart';
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
  int selectedOption = 0;
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
      isLoading = false;
    });
  }

  double get totalPrice {
    if (foodDetail == null) return 0.0;
    double optionPrice = 0.0;
    if (foodDetail!.options.isNotEmpty) {
      optionPrice = foodDetail!.options[selectedOption].extraPrice;
    }
    return (foodDetail!.price + optionPrice) * quantity;
  }

  void _orderNow(BuildContext context) {
    final basket = Provider.of<BasketProvider>(context, listen: false);
    basket.clear();
    basket.addItem(
      BasketItem(
        storeName: foodDetail!.shopName,
        foodName: foodDetail!.foodName,
        imagePath: foodDetail!.imageUrl,
        spicyLevel: foodDetail!.options.isNotEmpty
            ? foodDetail!.options[selectedOption].label
            : 'ปกติ',
        note: noteController.text,
        price: totalPrice / quantity,
        quantity: quantity,
        selected: true,
      ),
    );
    Navigator.pushNamed(context, '/order-now');
  }

  void _addToBasket(BuildContext context) {
    final basket = Provider.of<BasketProvider>(context, listen: false);
    basket.addItem(
      BasketItem(
        storeName: foodDetail!.shopName,
        foodName: foodDetail!.foodName,
        imagePath: foodDetail!.imageUrl,
        spicyLevel: foodDetail!.options.isNotEmpty
            ? foodDetail!.options[selectedOption].label
            : 'ปกติ',
        note: noteController.text,
        price: totalPrice / quantity,
        quantity: quantity,
        selected: true,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เพิ่มลงตะกร้าแล้ว')),
    );
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
                  int count = basket.items.fold(0, (sum, e) => sum + e.quantity);
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
                            constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                            child: Center(
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
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
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.green),
                                    onPressed: quantity > 1
                                        ? () => setState(() => quantity--)
                                        : null,
                                  ),
                                  Text(
                                    '$quantity',
                                    style: TextStyle(
                                        fontSize: isTablet ? 20 : 18, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                    onPressed: () => setState(() => quantity++),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(),
                          // Options
                          if (foodDetail!.options.isNotEmpty) ...[
                            const Text('ตัวเลือกเพิ่มเติม', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...List.generate(foodDetail!.options.length, (i) {
                              return RadioListTile<int>(
                                value: i,
                                groupValue: selectedOption,
                                activeColor: Colors.green,
                                onChanged: (val) => setState(() => selectedOption = val!),
                                title: Text(foodDetail!.options[i].label),
                                secondary: Text(
                                  '+${foodDetail!.options[i].extraPrice.toStringAsFixed(0)} \$',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              );
                            }),
                            Divider(),
                          ],
                          // Total Price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ราคารวมทั้งหมด', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('${totalPrice.toStringAsFixed(0)} \$',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Note
                          const Text('รายละเอียดเพิ่มเติม', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: noteController,
                            decoration: InputDecoration(
                              hintText: 'เช่น ไม่เอาผัก',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _orderNow(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[700],
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text(
                                    'สั่งเลย',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _addToBasket(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text(
                                    'ใส่ตะกร้า',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
