import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/basket_provider.dart';

class MyBasketPage extends StatelessWidget {
  static const routeName = '/basket';
  const MyBasketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BasketProvider>(
      builder: (context, basket, _) {
        final items = basket.items;
        final isEdit = basket.isEditMode;
        return Scaffold(
          backgroundColor: const Color(0xFF34C759),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'ตะกร้าของฉัน (${items.length})',
              style: const TextStyle(color: Colors.black),
            ),
            actions: [
              TextButton(
                onPressed: () => basket.toggleEditMode(),
                child: Text(
                  isEdit ? 'เสร็จสิ้น' : 'แก้ไข',
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          AppBar().preferredSize.height -
                          MediaQuery.of(context).padding.top -
                          100, // ลบพื้นที่สำหรับ bottom bar
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: items.isEmpty
                        ? Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.2,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'ยังไม่มีสินค้าในตะกร้า',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                ...List.generate(items.length, (i) {
                                  final item = items[i];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            children: [
                                              Checkbox(
                                                value: item.selected,
                                                activeColor: Colors.green,
                                                onChanged: (v) =>
                                                    basket.toggleItemSelected(
                                                      i,
                                                      v ?? false,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              SizedBox(
                                                width: 80,
                                                height: 80,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.asset(
                                                    item.imagePath,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.storeName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  item.foodName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                DropdownButton<String>(
                                                  value: item.spicyLevel,
                                                  items:
                                                      [
                                                            'เผ็ดน้อย',
                                                            'เผ็ดปานกลาง',
                                                            'เผ็ดมาก',
                                                          ]
                                                          .map(
                                                            (e) =>
                                                                DropdownMenuItem(
                                                                  value: e,
                                                                  child: Text(
                                                                    e,
                                                                  ),
                                                                ),
                                                          )
                                                          .toList(),
                                                  onChanged:
                                                      null, // Disable change in basket
                                                  isExpanded: true,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  '${item.price.toStringAsFixed(0)} บาท',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            children: [
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.remove_circle,
                                                      color: Colors.green,
                                                    ),
                                                    onPressed:
                                                        item.quantity > 1 &&
                                                            !isEdit
                                                        ? () => basket
                                                              .updateQuantity(
                                                                i,
                                                                item.quantity -
                                                                    1,
                                                              )
                                                        : null,
                                                  ),
                                                  Text(
                                                    '${item.quantity}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.add_circle,
                                                      color: Colors.green,
                                                    ),
                                                    onPressed: !isEdit
                                                        ? () => basket
                                                              .updateQuantity(
                                                                i,
                                                                item.quantity +
                                                                    1,
                                                              )
                                                        : null,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                // เพิ่ม padding ด้านล่างเพื่อให้มีพื้นที่สำหรับ bottom bar
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              // Bottom bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  // borderRadius: const BorderRadius.vertical(
                  //   top: Radius.circular(16),
                  // ),
                ),
                child: SafeArea(
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Checkbox(
                          value: basket.allSelected,
                          activeColor: Colors.green,
                          onChanged: (v) => basket.toggleSelectAll(v ?? false),
                        ),
                        const Text('ทั้งหมด'),
                        const SizedBox(width: 8),
                        const Text(
                          'รวม',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 5),
                        // ราคา - ใช้ Expanded แทน Flexible
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${basket.totalSelectedPrice.toStringAsFixed(0)} บาท',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // ปุ่ม - ใช้ Expanded แทน Flexible
                        if (!isEdit)
                          Expanded(
                            flex: 3,
                            child: ElevatedButton(
                              onPressed: basket.selectedCount > 0
                                  ? () {
                                      Navigator.pushNamed(
                                        context,
                                        '/order-now',
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: basket.selectedCount > 0
                                    ? const Color(0xFF34C759)
                                    : Colors.grey,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.81,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: const Size(0, 44),
                              ),
                              child: Text(
                                'ชำระเงิน (${basket.selectedCount})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                        else
                          Expanded(
                            flex: 2,
                            child: OutlinedButton(
                              onPressed: basket.items.any((e) => e.selected)
                                  ? basket.removeSelected
                                  : null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: const Size(0, 44),
                              ),
                              child: const Text(
                                'ลบ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
