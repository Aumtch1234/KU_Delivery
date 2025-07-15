import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/basket_provider.dart';
import 'RecipientAddress.dart';

class OrderNowPage extends StatefulWidget {
  static const routeName = '/order-now';
  const OrderNowPage({super.key});

  @override
  State<OrderNowPage> createState() => _OrderNowPageState();
}

class _OrderNowPageState extends State<OrderNowPage> {
  String deliveryType = 'แบบ/วางไว้จุดที่ระบุ';
  String paymentMethod = 'เงินสด';
  TextEditingController noteController = TextEditingController();

  Map<String, dynamic>? addressInfo;

  @override
  Widget build(BuildContext context) {
    final basket = Provider.of<BasketProvider>(context);
    final items = basket.items.where((e) => e.selected).toList();
    final total = basket.totalSelectedPrice;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ร้านที่ 1', style: TextStyle(color: Colors.black)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF34C759)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addressInfo != null && addressInfo!['place'] != ''
                                ? addressInfo!['place']
                                : 'หอ HD',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            addressInfo != null &&
                                    addressInfo!['name'] != '' &&
                                    addressInfo!['phone'] != ''
                                ? '${addressInfo!['name']} - ${addressInfo!['phone']}'
                                : 'ฮองเชา - 099 999 9999',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          if (addressInfo != null &&
                              addressInfo!['address'] != '')
                            Text(
                              addressInfo!['address'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          if (addressInfo != null &&
                              addressInfo!['mapLocation'] != null)
                            Text(
                              'ตำแหน่ง: ${addressInfo!['mapLocation']}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipientAddressPage(initialAddress: addressInfo),
                        ),
                      );
                      if (result != null && result is Map) {
                        setState(() {
                          addressInfo = Map<String, dynamic>.from(result);
                        });
                      }
                    },
                    child: const Text(
                      'แก้ไข',
                      style: TextStyle(color: Color(0xFF34C759)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'รูปแบบการจัดส่ง',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: _deliveryTypeButton(
                        '',
                        'ส่งถึงมือ/ออกมารับเอง',
                        deliveryType == 'ส่งถึงมือ/ออกมารับเอง',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _deliveryTypeButton(
                        '',
                        'ฝากไว้กับคนที่ระบุ',
                        deliveryType == 'ฝากไว้กับคนที่ระบุ',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  hintText:
                      'รายละเอียดเพิ่มเติม... (เช่น ห้องเลขที่ หรือชื่อผู้รับ)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF34C759)),
                ),
                child: const Text(
                  'ส่งปกติ เวลา 35 นาที',
                  style: TextStyle(color: Color(0xFF34C759)),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'รายการอาหารที่สั่ง',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...items.map((item) => _orderItem(item)).toList(),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'ชำระเงินโดย',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: paymentMethod,
                    borderRadius: BorderRadius.circular(10),
                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: 'เงินสด',
                        child: Row(
                          children: [
                            Icon(Icons.attach_money, color: Color(0xFF34C759)),
                            const SizedBox(width: 8),
                            Text('เงินสด'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'โอน',
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Color(0xFF34C759),
                            ),
                            const SizedBox(width: 8),
                            Text('โอน'),
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34C759),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${items.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'สั่งเลย',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderItem(item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.quantity}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.foodName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (item.spicyLevel != null && item.spicyLevel != '')
                  Text(
                    item.spicyLevel,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                if (item.note != null && item.note != '')
                  Text(
                    item.note,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${item.price.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _deliveryTypeButton(String tag, String label, bool selected) {
    IconData? icon;
    if (label.contains('วางไว้')) {
      icon = Icons.table_restaurant_sharp;
    } else if (label.contains('ถึงมือ') || label.contains('รับเอง')) {
      icon = Icons.person;
    } else if (label.contains('ฝากไว้')) {
      icon = Icons.group;
    }

    return GestureDetector(
      onTap: () => setState(() => deliveryType = label),
      child: SizedBox.expand(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF34C759) : Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: const Color(0xFF34C759), width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // จัดกลางแนวตั้ง
            crossAxisAlignment: CrossAxisAlignment.center, // จัดกลางแนวนอน
            mainAxisSize: MainAxisSize.max, // ให้ขยายเต็ม container
            children: [
              if (tag.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Icon(
                    icon,
                    color: selected ? Colors.white : Colors.black54,
                    size: 20,
                  ),
                ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
