// pages/customer_orders_simple_page.dart - Enhanced Customer Order Tracking
import 'package:delivery/APIs/Orders/OrdersSocket.dart';
import 'package:delivery/pages/order/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class CustomerOrderPage extends StatefulWidget {
  final int? userId;

  const CustomerOrderPage({Key? key, this.userId}) : super(key: key);

  @override
  State<CustomerOrderPage> createState() => _CustomerOrderPageState();
}

class _CustomerOrderPageState extends State<CustomerOrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Updated status tabs with better naming
  final Map<String, Map<String, dynamic>> _statusTabs = {
    'all': {'name': 'ทั้งหมด', 'icon': Icons.list_alt},
    'waiting': {'name': 'รอยืนยัน', 'icon': Icons.schedule},
    'accepted': {'name': 'กำลังทำ', 'icon': Icons.restaurant_menu},
    'delivering': {'name': 'กำลังส่ง', 'icon': Icons.delivery_dining},
    'completed': {'name': 'เสร็จแล้ว', 'icon': Icons.check_circle},
    'cancelled': {'name': 'ยกเลิก', 'icon': Icons.cancel},
  };

  // Modern color scheme
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color backgroundColor = Color(0xFFF8FAFB);

  String _currentStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentStatus = _statusTabs.keys.elementAt(_tabController.index);
      });
    });
    _loadCustomerOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerOrders() async {
    final controller = context.read<OrderController>();

    if (!controller.isSocketConnected) {
      await controller.initializeSocket(userId: widget.userId);
    }

    if (widget.userId != null) {
      await controller.fetchOrdersByCustomer(userId: widget.userId!);
    }
  }

  List<Order> _getFilteredOrders(OrderController controller, String status) {
    List<Order> filteredOrders;

    if (status == 'all') {
      filteredOrders = controller.orders;
    } else {
      filteredOrders = controller.orders
          .where((order) => order.status == status)
          .toList();
    }

    // เรียงออเดอร์ตาม priority: active orders ก่อน แล้วเรียงตามวันที่
    filteredOrders.sort((a, b) {
      final aActive = ['waiting', 'accepted', 'preparing', 'delivering'].contains(a.status);
      final bActive = ['waiting', 'accepted', 'preparing', 'delivering'].contains(b.status);

      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;

      return b.createdAt.compareTo(a.createdAt);
    });

    return filteredOrders;
  }

  int _getOrderCountByStatus(OrderController controller, String status) {
    if (status == 'all') return controller.orders.length;
    return controller.orders.where((order) => order.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'ออเดอร์ของฉัน',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          Consumer<OrderController>(
            builder: (context, controller, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: controller.isSocketConnected 
                    ? successColor.withOpacity(0.1)
                    : errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: controller.isSocketConnected 
                      ? successColor.withOpacity(0.3)
                      : errorColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.isSocketConnected ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: controller.isSocketConnected ? successColor : errorColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${controller.orders.length}',
                      style: TextStyle(
                        color: controller.isSocketConnected ? successColor : errorColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 60,
            color: Colors.white,
            child: Consumer<OrderController>(
              builder: (context, controller, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicator: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorPadding: const EdgeInsets.all(4),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    tabs: _statusTabs.entries.map((entry) {
                      final count = _getOrderCountByStatus(controller, entry.key);
                      return Tab(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                entry.value['icon'],
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(entry.value['name']),
                              if (count > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _currentStatus == entry.key 
                                      ? Colors.white.withOpacity(0.3)
                                      : primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _currentStatus == entry.key 
                                        ? Colors.white
                                        : primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: Consumer<OrderController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          }

          if (controller.error != null) {
            return _buildErrorState(controller);
          }

          return TabBarView(
            controller: _tabController,
            children: _statusTabs.keys.map((status) {
              final filteredOrders = _getFilteredOrders(controller, status);

              if (filteredOrders.isEmpty) {
                return _buildEmptyState(status);
              }

              return RefreshIndicator(
                onRefresh: _loadCustomerOrders,
                color: primaryColor,
                child: _buildOrdersList(filteredOrders),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    final isActive = ['waiting', 'accepted', 'preparing', 'delivering'].contains(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: isActive 
          ? Border.all(color: order.statusColor.withOpacity(0.3), width: 1)
          : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Status Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    order.statusColor.withOpacity(0.1),
                    order.statusColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: order.statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      order.statusIcon,
                      color: order.statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.statusText,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: order.statusColor,
                                ),
                              ),
                            ),
                            if (isActive) 
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: order.statusColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'กำลังดำเนินการ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ออเดอร์ #${order.orderId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Order Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Shop and Time Info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (order.shopName.isNotEmpty) ...[
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.restaurant,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      order.shopName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _formatDateTime(order.createdAt),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '฿${order.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${order.items.length} รายการ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Progress Bar for Active Orders
                  if (isActive) ...[
                    const SizedBox(height: 20),
                    _buildProgressBar(order.status),
                  ],

                  // Estimated Time for Active Orders
                  if (isActive) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: successColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 18,
                            color: successColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ประมาณ 25-30 นาที',
                            style: TextStyle(
                              fontSize: 14,
                              color: successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Action Button for Waiting Orders
                  if (order.status == 'waiting') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showCancelDialog(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: errorColor,
                          side: BorderSide(color: errorColor.withOpacity(0.3)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.cancel_outlined, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'ยกเลิกออเดอร์',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String status) {
    final steps = ['waiting', 'accepted', 'preparing', 'delivering', 'completed'];
    final stepNames = ['รับออเดอร์', 'ยืนยัน', 'เตรียม', 'จัดส่ง', 'เสร็จสิ้น'];
    final currentIndex = steps.indexOf(status);

    return Column(
      children: [
        Row(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final isActive = index <= currentIndex;
            final isCurrent = index == currentIndex;

            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(
                  right: index < steps.length - 1 ? 4 : 0,
                ),
                decoration: BoxDecoration(
                  color: isActive 
                    ? (isCurrent ? primaryColor : successColor)
                    : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: stepNames.asMap().entries.map((entry) {
            final index = entry.key;
            final isActive = index <= currentIndex;
            final isCurrent = index == currentIndex;

            return Text(
              entry.value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isActive 
                  ? (isCurrent ? primaryColor : successColor)
                  : Colors.grey.shade500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showCancelDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: errorColor, size: 24),
            const SizedBox(width: 12),
            const Text(
              'ยกเลิกออเดอร์',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'คุณต้องการยกเลิกออเดอร์ #${order.orderId} หรือไม่?\n\nหมายเหตุ: หากร้านยืนยันออเดอร์แล้ว อาจจะไม่สามารถยกเลิกได้',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'ไม่ยกเลิก',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              final controller = context.read<OrderController>();
              final success = await controller.cancelOrder(
                order.orderId,
                "Canceled Order From Customer.",
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'ยกเลิกออเดอร์เรียบร้อย'
                          : 'ไม่สามารถยกเลิกได้: ${controller.error}',
                    ),
                    backgroundColor: success ? successColor : errorColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                if (success) {
                  _loadCustomerOrders();
                }
              }
            },
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(OrderController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: errorColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              controller.error ?? 'ไม่สามารถโหลดข้อมูลได้',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadCustomerOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text(
                'ลองใหม่',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String title, subtitle;
    IconData iconData;

    switch (status) {
      case 'waiting':
        title = 'ไม่มีออเดอร์ที่รอยืนยัน';
        subtitle = 'ออเดอร์ใหม่ที่รอร้านยืนยันจะปรากฏที่นี่';
        iconData = Icons.schedule;
        break;
      case 'accepted':
        title = 'ไม่มีออเดอร์ที่กำลังทำ';
        subtitle = 'ออเดอร์ที่ร้านกำลังเตรียมจะปรากฏที่นี่';
        iconData = Icons.restaurant_menu;
        break;
      case 'delivering':
        title = 'ไม่มีออเดอร์ที่กำลังส่ง';
        subtitle = 'ออเดอร์ที่กำลังส่งจะปรากฏที่นี่';
        iconData = Icons.delivery_dining;
        break;
      case 'completed':
        title = 'ไม่มีออเดอร์ที่เสร็จแล้ว';
        subtitle = 'ออเดอร์ที่เสร็จสิ้นแล้วจะปรากฏที่นี่';
        iconData = Icons.check_circle;
        break;
      case 'cancelled':
        title = 'ไม่มีออเดอร์ที่ยกเลิก';
        subtitle = 'ออเดอร์ที่ถูกยกเลิกจะปรากฏที่นี่';
        iconData = Icons.cancel;
        break;
      default:
        title = 'ยังไม่มีออเดอร์';
        subtitle = 'เมื่อคุณสั่งอาหาร ออเดอร์จะปรากฏที่นี่';
        iconData = Icons.receipt_long;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                size: 72,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadCustomerOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'รีเฟรช',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'อาทิตย์'];
      final weekday = weekdays[dateTime.weekday - 1];
      return '$weekday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}