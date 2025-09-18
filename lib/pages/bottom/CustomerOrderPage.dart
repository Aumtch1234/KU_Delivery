// pages/customer_orders_simple_page.dart - Customer Order Tracking with Status Tabs
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

class _CustomerOrderPageState extends State<CustomerOrderPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Updated status tabs for customer workflow
  final Map<String, String> _statusTabs = {
    'all': 'ทั้งหมด',         // แสดงออเดอร์ทั้งหมด
    'waiting': 'รอยืนยัน',      // ออเดอร์ใหม่ที่รอร้านรับ
    'accepted': 'กำลังทำ',      // ร้านรับแล้ว กำลังเตรียมอาหาร
    'delivering': 'กำลังส่ง',    // ไรเดอร์รับไปส่งแล้ว
    'completed': 'เสร็จแล้ว',    // ส่งเสร็จแล้ว
    'cancelled': 'ยกเลิกแล้ว'
  };

  // ธีมสีหลัก
  static const Color primaryColor = Color(0xFF34C759);
  static const Color primaryLight = Color(0xFF66D47A);
  static const Color primaryDark = Color(0xFF28A745);

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
      await controller.initializeSocket();
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
      filteredOrders = controller.orders.where((order) => order.status == status).toList();
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
    if (status == 'all') {
      return controller.orders.length;
    }
    return controller.orders.where((order) => order.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'ออเดอร์ของฉัน',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF34C759),
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          Consumer<OrderController>(
            builder: (context, controller, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.isSocketConnected 
                          ? Icons.wifi 
                          : Icons.wifi_off,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${controller.orders.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF34C759),
                  const Color(0xFF28A745),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Consumer<OrderController>(
              builder: (context, controller, child) {
                return TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                  tabs: _statusTabs.entries.map((entry) {
                    final count = _getOrderCountByStatus(controller, entry.key);
                    return Tab(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(entry.value),
                            if (count > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
              child: CircularProgressIndicator(),
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
                child: Column(
                  children: [
                    if (status == 'all') _buildSummaryCard(controller),
                    Expanded(
                      child: _buildOrdersList(filteredOrders),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(OrderController controller) {
    final activeOrders = controller.orders.where((order) => 
      ['waiting', 'accepted', 'delivering'].contains(order.status)
    ).length;

    final completedToday = controller.orders.where((order) {
      final today = DateTime.now();
      return order.status == 'completed' &&
          order.createdAt.day == today.day &&
          order.createdAt.month == today.month &&
          order.createdAt.year == today.year;
    }).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: activeOrders > 0 ? Colors.orange.shade100 : primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              activeOrders > 0 ? Icons.shopping_bag : Icons.check_circle,
              color: activeOrders > 0 ? Colors.orange.shade600 : primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activeOrders > 0) ...[
                  Text(
                    'ออเดอร์ที่กำลังดำเนินการ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '$activeOrders ออเดอร์',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ] else ...[
                  Text(
                    'ออเดอร์ที่เสร็จสิ้นวันนี้',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '$completedToday ออเดอร์',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
                Text(
                  'ทั้งหมด ${controller.orders.length} ออเดอร์',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: controller.isLoading ? null : _loadCustomerOrders,
            icon: controller.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            color: Colors.blue.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isActive 
            ? Border.all(color: order.statusColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: order.statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    order.statusIcon,
                    color: order.statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.statusText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: order.statusColor,
                        ),
                      ),
                      Text(
                        'ออเดอร์ #${order.orderId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: order.statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'กำลังดำเนินการ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Order Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (order.shopName != "") ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.restaurant,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    order.shopName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateTime(order.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
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
                          '฿${order.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          '${order.items.length} รายการ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Progress Bar for Active Orders
                if (isActive) ...[
                  const SizedBox(height: 16),
                  _buildProgressBar(order.status),
                ],

                // Estimated Time for Active Orders
                if (isActive && order.createdAt != "") ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ประมาณ ${order.createdAt} นาที',
                          style: TextStyle(
                            fontSize: 12,
                            color: primaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Button for Waiting Orders
                if (order.status == 'waiting') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showCancelDialog(order),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ยกเลิกออเดอร์',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String status) {
    final steps = ['waiting', 'accepted', 'preparing', 'delivering', 'completed'];
    final currentIndex = steps.indexOf(status);
    
    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final isActive = index <= currentIndex;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive 
                        ? primaryColor 
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (!isLast) const SizedBox(width: 2),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showCancelDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยกเลิกออเดอร์'),
        content: Text(
          'คุณต้องการยกเลิกออเดอร์ #${order.orderId} หรือไม่?\n\nหมายเหตุ: หากร้านยืนยันออเดอร์แล้ว อาจจะไม่สามารถยกเลิกได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ไม่ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              final controller = context.read<OrderController>();
              final success = await controller.cancelOrder(order.orderId, "Canceled Order From Customer.");
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                          ? 'ยกเลิกออเดอร์เรียบร้อย' 
                          : 'ไม่สามารถยกเลิกได้: ${controller.error}',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                if (success) {
                  _loadCustomerOrders(); // Refresh orders
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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.error ?? 'ไม่สามารถโหลดข้อมูลได้',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadCustomerOrders,
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String title, subtitle;
    
    switch (status) {
      case 'waiting':
        title = 'ไม่มีออเดอร์ที่รอยืนยัน';
        subtitle = 'ออเดอร์ใหม่ที่รอร้านยืนยันจะปรากฏที่นี่';
        break;
      case 'accepted':
        title = 'ไม่มีออเดอร์ที่กำลังทำ';
        subtitle = 'ออเดอร์ที่ร้านกำลังเตรียมจะปรากฏที่นี่';
        break;
      case 'delivering':
        title = 'ไม่มีออเดอร์ที่กำลังส่ง';
        subtitle = 'ออเดอร์ที่กำลังส่งจะปรากฏที่นี่';
        break;
      case 'completed':
        title = 'ไม่มีออเดอร์ที่เสร็จแล้ว';
        subtitle = 'ออเดอร์ที่เสร็จสิ้นแล้วจะปรากฏที่นี่';
        break;
      case 'cancelled':
        title = 'ไม่มีออเดอร์ที่ยกเลิก';
        subtitle = 'ออเดอร์ที่ถูกยกเลิกจะปรากฏที่นี่';
        break;
      default:
        title = 'ยังไม่มีออเดอร์';
        subtitle = 'เมื่อคุณสั่งอาหาร ออเดอร์จะปรากฏที่นี่';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadCustomerOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('รีเฟรช'),
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