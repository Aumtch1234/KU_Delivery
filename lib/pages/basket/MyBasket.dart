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
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: items.isEmpty
                ? Center(
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
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final item = items[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            item.foodName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
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
                                                      (e) => DropdownMenuItem(
                                                        value: e,
                                                        child: Text(e),
                                                      ),
                                                    )
                                                    .toList(),
                                            onChanged:
                                                null, // Disable change in basket
                                            isExpanded: true,
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
                                                  item.quantity > 1 && !isEdit
                                                  ? () => basket.updateQuantity(
                                                      i,
                                                      item.quantity - 1,
                                                    )
                                                  : null,
                                            ),
                                            Text(
                                              '${item.quantity}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle,
                                                color: Colors.green,
                                              ),
                                              onPressed: !isEdit
                                                  ? () => basket.updateQuantity(
                                                      i,
                                                      item.quantity + 1,
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
                          },
                        ),
                      ),
                      // Bottom bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: basket.allSelected,
                              activeColor: Colors.green,
                              onChanged: (v) =>
                                  basket.toggleSelectAll(v ?? false),
                            ),
                            const Text('ทั้งหมด'),
                            const Spacer(),
                            const Text(
                              'รวม',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${basket.totalSelectedPrice.toStringAsFixed(0)} บาท',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!isEdit)
                              ElevatedButton(
                                onPressed: basket.selectedCount > 0
                                    ? () {}
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: basket.selectedCount > 0
                                      ? const Color(0xFF34C759)
                                      : Colors.grey,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'ชำระเงิน (${basket.selectedCount})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            else
                              OutlinedButton(
                                onPressed: basket.items.any((e) => e.selected)
                                    ? basket.removeSelected
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'ลบ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
