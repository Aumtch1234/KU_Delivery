import 'dart:convert';
import 'package:delivery/APIs/Reviews/PostReview/PostReviewAPI.dart';
import 'package:delivery/APIs/Users/historyAPI.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List _orders = [];
  late TabController _tabController;
  List get _reviewableOrders =>
      _orders.where((o) => o['status'] == 'completed').toList();
  List get _cancelledOrders =>
      _orders.where((o) => o['status'] == 'cancelled').toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await HistoryAPI.getOrderHistory();
      setState(() {
        _orders = data;
        _loading = false;
      });
    } catch (e) {
      print("⚠️ Error: $e");
      setState(() => _loading = false);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'วันนี้ ${DateFormat('HH:mm').format(date)} น.';
      } else if (difference.inDays == 1) {
        return 'เมื่อวาน ${DateFormat('HH:mm').format(date)} น.';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} วันที่แล้ว';
      } else {
        return DateFormat('d MMM yyyy', 'th').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildStatusBadge(String status) {
    final isCompleted = status == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isCompleted ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isCompleted ? 'สำเร็จ' : 'ยกเลิก',
            style: TextStyle(
              color: isCompleted ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _openReviewDialog(Map order) {
    final items = order['items'] as List;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReviewOrderSheet(
        orderId: order['order_id'],
        shopName: order['shop_name'] ?? 'ไม่ทราบชื่อร้าน',
        items: items,
        onReviewSubmitted: () {
          // Refresh หลังจากรีวิวเสร็จ
          _loadHistory();
        },
      ),
    );
  }

  void _openMarketReviewDialog(Map order) {
    // ✅ เก็บ context หลักไว้
    final pageContext = context;

    showModalBottomSheet(
      context: pageContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SimpleReviewSheet(
        title: 'รีวิวร้านค้า',
        subtitle: '${order['shop_name']} (คำสั่งซื้อ #${order['order_id']})',
        onSubmit: (rating, comment) async {
          try {
            final res = await PostReviewApi.postMarketReview(
              orderId: order['order_id'],
              marketId: order['market_id'],
              rating: rating,
              comment: comment,
            );
            print("✅ Market review success: $res");

            // ✅ ปิด BottomSheet ก่อน
            if (sheetContext.mounted) Navigator.pop(sheetContext);

            // ✅ หน่วงเล็กน้อยเพื่อให้ปิดเรียบร้อย
            await Future.delayed(const Duration(milliseconds: 300));

            // ✅ แสดง Alert แบบสวย ๆ
            AwesomeDialog(
              context: pageContext,
              dialogType: DialogType.success,
              animType: AnimType.scale,
              title: 'รีวิวสำเร็จ!',
              desc: 'ขอบคุณสำหรับรีวิวร้านค้าของคุณ 💚',
              btnOkColor: const Color(0xFF34C759),
              btnOkText: 'ตกลง',
              btnOkOnPress: () {
                setState(() {
                  order['has_unreviewed_market'] = false;
                });
                _loadHistory(); // ถ้าจะรีเฟรชจาก backend ด้วยก็ยังคงไว้
              },
            ).show();
          } catch (e) {
            // ❌ แสดง dialog แจ้งเตือน error
            AwesomeDialog(
              context: pageContext,
              dialogType: DialogType.error,
              animType: AnimType.bottomSlide,
              title: 'เกิดข้อผิดพลาด',
              desc: '❌ ไม่สามารถส่งรีวิวร้านค้าได้\n$e',
              btnOkText: 'ตกลง',
              btnOkColor: Colors.red,
              btnOkOnPress: () {},
            ).show();
          }
        },
      ),
    );
  }

  void _openRiderReviewDialog(Map order) {
    final pageContext = context; // ✅ เก็บ context หลักไว้ก่อน
    final riderName = order['rider_name'] ?? 'ไม่ทราบชื่อไรเดอร์';

    showModalBottomSheet(
      context: pageContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SimpleReviewSheet(
        title: 'รีวิวไรเดอร์',
        subtitle: 'ไรเดอร์: $riderName (คำสั่งซื้อ #${order['order_id']})',
        onSubmit: (rating, comment) async {
          try {
            final res = await PostReviewApi.postRiderReview(
              orderId: order['order_id'],
              riderId: order['rider_id'],
              rating: rating,
              comment: comment,
            );
            print("✅ Rider review success: $res");

            // ✅ ปิด BottomSheet ก่อน
            if (sheetContext.mounted) Navigator.pop(sheetContext);

            // ✅ รอให้ปิดเรียบร้อย แล้วค่อยเปิด dialog บน context หลัก
            await Future.delayed(const Duration(milliseconds: 300));

            AwesomeDialog(
              context: pageContext,
              dialogType: DialogType.success,
              animType: AnimType.scale,
              title: 'รีวิวสำเร็จ!',
              desc: 'ขอบคุณสำหรับรีวิวไรเดอร์ของคุณ 🛵💙',
              btnOkColor: Colors.blueAccent,
              btnOkText: 'ตกลง',
              btnOkOnPress: () {
                // ✅ แค่รีเฟรชหน้า ไม่ต้องเปลี่ยนหน้า
                _loadHistory();
              },
            ).show();
          } catch (e) {
            // ❌ แสดง dialog แจ้งเตือน error
            AwesomeDialog(
              context: pageContext,
              dialogType: DialogType.error,
              animType: AnimType.bottomSlide,
              title: 'เกิดข้อผิดพลาด',
              desc: '❌ ไม่สามารถส่งรีวิวไรเดอร์ได้\n$e',
              btnOkText: 'ตกลง',
              btnOkColor: Colors.red,
              btnOkOnPress: () {},
            ).show();
          }
        },
      ),
    );
  }

  Widget _buildOrderCard(Map order, {bool showReviewButton = false}) {
    final items = order['items'] as List;
    final subtotal = double.tryParse(order['subtotal'].toString()) ?? 0;
    final deliveryFee = double.tryParse(order['delivery_fee'].toString()) ?? 0;
    final total = subtotal + deliveryFee;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: Color(0xFF34C759),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['shop_name'] ?? 'ไม่ทราบชื่อร้าน',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'คำสั่งซื้อ #${order['order_id']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(order['status']),
              ],
            ),
          ),

          // Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final item = items[index];
              final options = item['selected_options'] as List;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      image: item['image_url'] != null
                          ? DecorationImage(
                              image: NetworkImage(item['image_url']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: item['image_url'] == null
                        ? const Icon(
                            Icons.restaurant,
                            color: Color(0xFF34C759),
                            size: 24,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['food_name'] ?? 'ไม่ระบุชื่อ',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ราคา ${item['sell_price']} บาท',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (options.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: options.map((opt) {
                              if (opt is Map) {
                                final label = (opt['label'] ?? '')
                                    .toString()
                                    .trim();
                                final price = opt['extraPrice'] ?? 0;

                                String display = "";
                                if (label.isNotEmpty) display = label;
                                if (price != 0) display += " (+${price}฿)";
                                if (display.isEmpty)
                                  display = "ตัวเลือกเพิ่มเติม";

                                return Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    display,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                );
                              } else {
                                return Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    opt.toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                );
                              }
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '×${item['quantity']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item['subtotal']}฿',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF34C759),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ยอดรวมอาหาร',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${subtotal.toStringAsFixed(2)} ฿',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ค่าจัดส่ง',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${deliveryFee.toStringAsFixed(2)} ฿',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ยอดรวมทั้งหมด',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${total.toStringAsFixed(2)} ฿',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF34C759),
                      ),
                    ),
                  ],
                ),
                // ✅ แสดงเฉพาะออเดอร์ที่สำเร็จ
                if (order['status'] == 'completed') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // 🏪 ปุ่มรีวิวร้านค้า
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (order['has_unreviewed_market'] == false)
                              ? null // ❌ ปิดปุ่มถ้ารีวิวแล้ว
                              : () {
                                  _openMarketReviewDialog(order);
                                },
                          icon: Icon(
                            order['has_unreviewed_market'] == false
                                ? Icons.check_circle_outline
                                : Icons.storefront_outlined,
                            size: 18,
                          ),
                          label: Text(
                            order['has_unreviewed_market'] == false
                                ? 'รีวิวร้านค้าแล้ว'
                                : 'รีวิวร้านค้า',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                order['has_unreviewed_market'] == false
                                ? Colors.grey.shade400
                                : Colors.orange.shade400,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 🛵 ปุ่มรีวิวไรเดอร์
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (order['has_unreviewed_rider'] == false)
                              ? null
                              : () {
                                  _openRiderReviewDialog(order);
                                },
                          icon: Icon(
                            order['has_unreviewed_rider'] == false
                                ? Icons.check_circle_outline
                                : Icons.pedal_bike_outlined,
                            size: 18,
                          ),
                          label: Text(
                            order['has_unreviewed_rider'] == false
                                ? 'รีวิวไรเดอร์แล้ว'
                                : 'รีวิวไรเดอร์',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                order['has_unreviewed_rider'] == false
                                ? Colors.grey.shade400
                                : Colors.blue.shade500,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // ปุ่มรีวิว (แสดงเฉพาะคำสั่งซื้อที่สำเร็จ)
                if (showReviewButton && order['status'] == 'completed') ...[
                  const SizedBox(height: 16),

                  // ✅ ตรวจสอบว่าทุกเมนูรีวิวแล้วหรือยัง
                  Builder(
                    builder: (context) {
                      final allReviewed = items.every(
                        (item) => item['is_reviewed'] == true,
                      );

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: allReviewed
                              ? null
                              : () => _openReviewDialog(order),
                          icon: Icon(
                            allReviewed
                                ? Icons.visibility_outlined
                                : Icons.star_outline,
                            size: 18,
                          ),
                          label: Text(
                            allReviewed
                                ? 'รีวิวแล้ว'
                                : 'รีวิวออร์เดอร์นี้ (${items.length} เมนู)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: allReviewed
                                ? Colors.grey.shade400
                                : const Color(0xFF34C759),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List orders, {bool showReviewButton = false}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีคำสั่งซื้อ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ประวัติการสั่งซื้อจะแสดงที่นี่',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) =>
          _buildOrderCard(orders[index], showReviewButton: showReviewButton),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF34C759),
        title: const Text(
          "ประวัติการสั่งซื้อ",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            width: double.infinity,
            color: const Color(0xFF34C759),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),

              // ✅ ให้แท็บเต็มความกว้าง (ไม่ scroll)
              isScrollable: false,

              // ✅ padding ให้พอดีขอบซ้ายขวา
              labelPadding: const EdgeInsets.symmetric(vertical: 8.0),
              indicatorPadding: EdgeInsets.zero,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_outline, size: 16),
                      const SizedBox(width: 6),
                      Text('สำเร็จ (${_reviewableOrders.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cancel_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text('ยกเลิก (${_cancelledOrders.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34C759)),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_reviewableOrders, showReviewButton: true),
                _buildOrderList(_cancelledOrders),
              ],
            ),
    );
  }
}

// Widget สำหรับแสดงหน้ารีวิว
class ReviewOrderSheet extends StatefulWidget {
  final int orderId;
  final String shopName;
  final List items;
  final VoidCallback onReviewSubmitted;

  const ReviewOrderSheet({
    super.key,
    required this.orderId,
    required this.shopName,
    required this.items,
    required this.onReviewSubmitted,
  });

  @override
  State<ReviewOrderSheet> createState() => _ReviewOrderSheetState();
}

class _SimpleReviewSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final Function(int rating, String comment) onSubmit;

  const _SimpleReviewSheet({
    required this.title,
    required this.subtitle,
    required this.onSubmit,
  });

  @override
  State<_SimpleReviewSheet> createState() => _SimpleReviewSheetState();
}

class _SimpleReviewSheetState extends State<_SimpleReviewSheet> {
  int _rating = 5;
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!mounted) return; // ✅ ป้องกันตั้งแต่ต้น

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(_rating, _controller.text);

      if (mounted)
        Navigator.pop(context); // ✅ ปิดก่อนที่ setState จะถูกเรียกอีกครั้ง
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false); // ✅ ปลอดภัย
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'ให้คะแนน',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFA500),
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'แสดงความคิดเห็น...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34C759),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'ส่งรีวิว',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewOrderSheetState extends State<ReviewOrderSheet> {
  final Map<int, int> _ratings = {}; // index -> rating
  final Map<int, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.items.length; i++) {
      _ratings[i] = 5; // Default 5 stars
      _controllers[i] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitReviews() async {
    setState(() => _isSubmitting = true);

    try {
      // ✅ เตรียมข้อมูลรีวิวตามโครงสร้าง backend
      List<Map<String, dynamic>> reviews = [];

      for (int i = 0; i < widget.items.length; i++) {
        final item = widget.items[i];
        reviews.add({
          "order_item_id": item['order_item_id'], // ✅ ใหม่: ส่งให้ backend ใช้
          "food_id": item['food_id'], // ✅ ถ้ายังไม่มีใน API ก็ส่ง null ไปได้
          "rating": _ratings[i] ?? 5,
          "comment": _controllers[i]?.text ?? '',
        });
      }

      print("📤 Sending reviews for order ${widget.orderId}");
      print(jsonEncode({"order_id": widget.orderId, "reviews": reviews}));

      // ✅ เรียก API จริง
      final result = await PostReviewApi.postAllReviewFood(
        orderId: widget.orderId,
        reviews: reviews,
      );

      print("✅ Review response: $result");

      if (mounted) {
        Navigator.pop(context);
        widget.onReviewSubmitted();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ขอบคุณสำหรับรีวิวของคุณ'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
      }
    } catch (e) {
      print("⚠️ Review error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'รีวิวอาหาร',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.shopName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Review List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food info
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            image: item['image_url'] != null
                                ? DecorationImage(
                                    image: NetworkImage(item['image_url']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: item['image_url'] == null
                              ? const Icon(
                                  Icons.restaurant,
                                  color: Color(0xFF34C759),
                                  size: 30,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['food_name'] ?? 'ไม่ระบุชื่อ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'ราคา ${item['sell_price']} บาท',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Rating
                    const Text(
                      'ให้คะแนน',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (starIndex) {
                        return IconButton(
                          onPressed: () {
                            setState(() {
                              _ratings[index] = starIndex + 1;
                            });
                          },
                          icon: Icon(
                            starIndex < (_ratings[index] ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFFFFA500),
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),

                    // Comment
                    const Text(
                      'แสดงความคิดเห็น (ไม่บังคับ)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controllers[index],
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'บอกเราเกี่ยวกับเมนูนี้...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF34C759),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Submit Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReviews,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34C759),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'ส่งรีวิว',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
