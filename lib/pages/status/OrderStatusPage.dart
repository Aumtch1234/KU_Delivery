import 'package:delivery/pages/status/TakingStatusPage.dart';
import 'package:flutter/material.dart';

class OrderStatusPage extends StatelessWidget {
  const OrderStatusPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final greenColor = const Color(0xFF3EC876);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Header Section + ปุ่ม
          Stack(
            children: [
              Container(
                color: greenColor,
                height: 220,
                width: double.infinity,
                child: Stack(
                  children: const [
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Image(
                        image: AssetImage('assets/status_img/rider.png'),
                        height: 160,
                        width: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              // ปุ่มกากบาท
              Positioned(
                top: 60,
                left: 16,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
              // ปุ่มยกเลิกออเดอร์
              Positioned(
                top: 65,
                right: 12,
                child: Container(
                  width: 120,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(90, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // action ยกเลิกออเดอร์
                    },
                    child: const Text(
                      'ยกเลิกออเดอร์',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Status Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'กำลังหาไรเดอร์ให้คุณอยู่',
                  style: TextStyle(
                    color: greenColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'กำลังดำเนินการ...',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'เลขคำสั่งซื้อ A-123456789',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                // Status Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusIcon(Icons.person_search, false),
                    _buildLine(),
                    _buildStatusIcon(Icons.perm_phone_msg, false),
                    _buildLine(),
                    _buildStatusIcon(Icons.fastfood, false),
                    _buildLine(),
                    _buildStatusIcon(Icons.delivery_dining, false),
                    _buildLine(),
                    _buildStatusIcon(Icons.location_on, false),
                  ],
                ),
              ],
            ),
          ),

          // Order Detail Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCard(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ร้านที่ 1',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('ทั้งหมด'),
                            Text(
                              '\$768',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('วิธีชำระเงิน'),
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  size: 20,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 4),
                                Text('เงินสด'),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'ชื่อเมนู',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'จำนวน',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildFoodItem(
                          1,
                          'ยำทะเลรวม',
                          '1',
                          'เผ็ดมาก ไม่ใส่ผัก',
                        ),
                        _buildFoodItem(2, 'ข้าวกะเพรา', '2', 'ไม่ใส่ไข่ดาว'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCard(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.location_on,
                              size: 20,
                              color: Colors.black,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'ฮองเจา 0999999999',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 26),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('หอ HD'),
                              SizedBox(height: 4),
                              Text(
                                '99 บ้านกอกเมืองสกลนคร สกลนคร 47000 ประเทศไทย',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TakingStatusPage()),
          );
        },
        backgroundColor: greenColor,
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }

  // Status Icon
  static Widget _buildStatusIcon(IconData icon, bool active) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF3EC876) : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 35),
    );
  }

  static Widget _buildLine() {
    return Expanded(child: Container(height: 1.5, color: Colors.grey.shade300));
  }

  // Card
  static Widget _buildCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  // Food Item + รายละเอียด
  static Widget _buildFoodItem(
    int index,
    String name,
    String quantity,
    String note,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3EC876),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      index.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(name),
                ],
              ),
              Text(quantity),
            ],
          ),
          if (note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Text(
                note,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
