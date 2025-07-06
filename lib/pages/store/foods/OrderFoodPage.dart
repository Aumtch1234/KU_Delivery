import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/basket_item.dart';
import '../../../providers/basket_provider.dart';

class OrderFoodPage extends StatefulWidget {
  final String foodName;
  final String imagePath;
  final double rating;
  final String storeName;
  final double price;
  final String description;

  const OrderFoodPage({
    Key? key,
    required this.foodName,
    required this.imagePath,
    this.rating = 5.0,
    required this.storeName,
    required this.price,
    required this.description,
  }) : super(key: key);

  @override
  State<OrderFoodPage> createState() => _OrderFoodPageState();
}

class _OrderFoodPageState extends State<OrderFoodPage> {
  int quantity = 1;
  int selectedSpicy = 2;
  final spicyLevels = [
    {'label': 'เผ็ดน้อย', 'price': 59},
    {'label': 'เผ็ดปานกลาง', 'price': 90},
    {'label': 'เผ็ดมาก', 'price': 169},
  ];
  final TextEditingController noteController = TextEditingController();

  double get totalPrice =>
      ((spicyLevels[selectedSpicy]['price'] as int) * quantity).toDouble();

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.foodName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  widget.storeName,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.rating.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                ),
                const Icon(Icons.star, color: Colors.amber, size: 16),
              ],
            ),
          ],
        ),
        centerTitle: false,
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
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.shopping_cart, color: Colors.black),
                      ),
                      if (count > 0)
                        Positioned(
                          right: -7,
                          top: -10,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: ClampingScrollPhysics(),
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
                      child: Image.asset(
                        widget.imagePath,
                        width: double.infinity,
                        height: isTablet ? 320 : size.width * 0.5,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Food Name, Description, Price & Quantity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.foodName,
                                style: TextStyle(
                                  fontSize: isTablet ? 24 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.description,
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '฿${widget.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
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
                    Divider(),
                    // Spicy Level
                    Text(
                      'ระดับความเผ็ด',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 18 : 16,
                      ),
                    ),
                    const Text(
                      'กรุณาเลือก 1 ข้อ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(spicyLevels.length, (i) {
                      return RadioListTile<int>(
                        value: i,
                        groupValue: selectedSpicy,
                        onChanged: (val) =>
                            setState(() => selectedSpicy = val!),
                        title: Text(
                          spicyLevels[i]['label'] as String,
                          style: TextStyle(fontSize: isTablet ? 16 : 15),
                        ),
                        secondary: Text(
                          '${spicyLevels[i]['price']} \$',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ราคารวมทั้งสิ้น',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${totalPrice.toStringAsFixed(0)} \$',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Note
                    const Text(
                      'รายละเอียดเพิ่มเติม',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        hintText: 'เช่น ไม่เอาผัก',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[700],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'สั่งเลย',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final basket = Provider.of<BasketProvider>(
                                context,
                                listen: false,
                              );
                              // ตรวจสอบว่ามีอาหารนี้ในตะกร้าอยู่แล้วหรือไม่
                              final already = basket.items.any(
                                (e) =>
                                    e.foodName == widget.foodName &&
                                    e.storeName == widget.storeName &&
                                    e.spicyLevel ==
                                        spicyLevels[selectedSpicy]['label'] &&
                                    e.note == noteController.text,
                              );
                              if (!already) {
                                basket.addItem(
                                  BasketItem(
                                    storeName: widget.storeName,
                                    foodName: widget.foodName,
                                    imagePath: widget.imagePath,
                                    spicyLevel:
                                        spicyLevels[selectedSpicy]['label']
                                            as String,
                                    note: noteController.text,
                                    price:
                                        (spicyLevels[selectedSpicy]['price']
                                                as int)
                                            .toDouble(),
                                    quantity: quantity,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('เพิ่มลงตะกร้าแล้ว'),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('เมนูนี้อยู่ในตะกร้าแล้ว'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'ใส่ตะกร้า',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
