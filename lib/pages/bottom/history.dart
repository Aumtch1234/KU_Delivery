// pages/customer_orders_page.dart - Customer Order Tracking
import 'package:delivery/APIs/Orders/OrdersSocket.dart';
import 'package:delivery/pages/order/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomerOrdersPage extends StatefulWidget {
  final int? customerId;

  const CustomerOrdersPage({Key? key, this.customerId}) : super(key: key);

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Updated status tabs for customer workflow
  final Map<String, String> _statusTabs = {
    'waiting': 'รอร้านยืนยัน',     // รอร้านรับออเดอร์
    'accepted': 'กำลังเตรียม',     // ร้านยืนยันแล้ว กำลังทำอาหาร
    'delivering': 'กำลังส่ง',      // ไรเดอร์กำลังส่งมา
    'completed': 'เสร็จสิ้น',      // ส่งถึงแล้ว
    'cancelled': 'ยกเลิกแล้ว'      // ออเดอร์ถูกยกเลิก
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    final controller = context.read<OrderController>();

    print('👤 Initializing data for customer: ${widget.customerId}');

    if (!controller.isSocketConnected) {
      await controller.initializeSocket();
    }

    if (widget.customerId != null) {
      await controller.fetchOrdersByCustomer(customerId: widget.customerId!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Consumer<OrderController>(
        builder: (context, controller, child) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(controller),
              _buildSummaryCard(controller),
              _buildTabBar(),
              _buildOrdersList(controller),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(OrderController controller) {
    return SliverAppBar(
      backgroundColor: Colors.blue.shade600,
      elevation: 0,
      pinned: false,
      expandedHeight: 100,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: const Text(
                  'ออเดอร์ของฉัน',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Connection status and notification
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: controller.isSocketConnected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.isSocketConnected
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${controller.orders.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(OrderController controller) {
    final today = DateTime.now();
    final todayOrders = controller.orders.where((order) {
      return order.createdAt.day == today.day &&
          order.createdAt.month == today.month &&
          order.createdAt.year == today.year;
    }).toList();

    final todaySpent = todayOrders
        .where((order) => order.status == 'completed')
        .fold(0.0, (sum, order) => sum + order.totalPrice);

    // Count orders by status for today
    final statusCounts = <String, int>{};
    for (var status in _statusTabs.keys) {
      statusCounts[status] = todayOrders.where((order) => order.status == status).length;
    }

    // Find active orders
    final activeOrders = controller.orders.where((order) => 
      ['waiting', 'accepted', 'delivering'].contains(order.status)
    ).toList();

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            // Error display
            if (controller.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Main summary row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    color: Colors.blue.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeOrders.isNotEmpty ? 'ออเดอร์ที่กำลังดำเนินการ' : 'ยอดใช้จ่ายวันนี้',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (activeOrders.isNotEmpty) ...[
                        Text(
                          '${activeOrders.length} ออเดอร์',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade600,
                          ),
                        ),
                        Text(
                          'กำลังดำเนินการ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        Text(
                          '฿${todaySpent.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          '${todayOrders.length} ออเดอร์ (ทั้งหมด ${controller.orders.length})',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Refresh button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: controller.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.refresh, color: Colors.white),
                    onPressed: controller.isLoading
                        ? null
                        : () => _initializeData(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            
            // Status breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: _statusTabs.entries.map((entry) {
                  final status = entry.key;
                  final label = entry.value;
                  final count = statusCounts[status] ?? 0;
                  
                  Color color;
                  IconData icon;
                  switch (status) {
                    case 'waiting':
                      color = Colors.orange;
                      icon = Icons.access_time;
                      break;
                    case 'accepted':
                      color = Colors.blue;
                      icon = Icons.restaurant;
                      break;
                    case 'delivering':
                      color = Colors.purple;
                      icon = Icons.delivery_dining;
                      break;
                    case 'completed':
                      color = Colors.green;
                      icon = Icons.done_all;
                      break;
                    default:
                      color = Colors.grey;
                      icon = Icons.cancel;
                  }

                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(icon, color: color, size: 16),
                              const SizedBox(height: 2),
                              Text(
                                count.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.blue.shade600,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue.shade600,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          tabs: _statusTabs.entries.map((entry) {
            final status = entry.key;
            final label = entry.value;
            
            return Consumer<OrderController>(
              builder: (context, controller, child) {
                final count = controller.getOrdersByStatus(status).length;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: status == 'waiting' || status == 'accepted' || status == 'delivering'
                                ? Colors.orange
                                : Colors.blue.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildOrdersList(OrderController controller) {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: _statusTabs.entries.map((entry) {
          final status = entry.key;
          return _buildOrdersForStatus(controller, status);
        }).toList(),
      ),
    );
  }

  Widget _buildOrdersForStatus(OrderController controller, String status) {
    if (controller.isLoading) {
      return _buildLoadingState();
    }

    if (controller.error != null) {
      return _buildErrorState(controller);
    }

    final orders = controller.getOrdersByStatus(status);

    if (orders.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: () => _initializeData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order, controller);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order, OrderController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: order.statusColor.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Status header with progress indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: order.statusColor.withOpacity(0.1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: order.statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.statusText,
                        style: TextStyle(
                          color: order.statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.paymentMethod,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress indicator
                  _buildProgressIndicator(order.status),
                ],
              ),
            ),

            // Order content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID, Restaurant, and Amount
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ออเดอร์ #${order.orderId}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (order.restaurantName != null) ...[
                              const SizedBox(height: 4),
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
                                      order.restaurantName!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '฿${order.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Order time and delivery info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'สั่งเมื่อ: ${_formatDateTime(order.createdAt)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const Spacer(),
                            if (order.estimatedDeliveryTime != null) ...[
                              Icon(
                                Icons.delivery_dining,
                                size: 16,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '~${order.estimatedDeliveryTime} นาที',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (order.distanceKm != null && order.distanceKm! > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ระยะทาง: ${order.distanceKm!.toStringAsFixed(1)} กม.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'ค่าส่ง: ฿${order.deliveryFee.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Order Items
                  if (order.items.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.restaurant_menu,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'รายการอาหาร',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${order.items.length} รายการ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...order.items.take(3).map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${item.quantity}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.foodName,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    '฿${item.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (order.items.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'และอีก ${order.items.length - 3} รายการ...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Action Buttons
                  _buildActionButtons(order, controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(String status) {
    final steps = ['waiting', 'accepted', 'delivering', 'completed'];
    final currentIndex = steps.indexOf(status);
    final isCancelled = status == 'cancelled';

    if (isCancelled) {
      return Container(
        height: 4,
        decoration: BoxDecoration(
          color: Colors.red.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

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
                        ? Colors.green.shade400 
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

  Widget _buildActionButtons(Order order, OrderController controller) {
    switch (order.status) {
      case 'waiting':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _showCancelDialog(order, controller),
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
        );
      case 'delivering':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _trackDelivery(order),
                icon: const Icon(Icons.location_on, color: Colors.white),
                label: const Text(
                  'ติดตามออเดอร์',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      case 'completed':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue.shade600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _reorder(order),
                icon: Icon(Icons.refresh, color: Colors.blue.shade600),
                label: Text(
                  'สั่งซ้ำ',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _rateOrder(order),
                icon: const Icon(Icons.star, color: Colors.orange),
                label: const Text(
                  'รีวิว',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showCancelDialog(Order order, OrderController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยกเลิกออเดอร์'),
        content: Text('คุณต้องการยกเลิกออเดอร์ #${order.orderId} หรือไม่?\n\nหมายเหตุ: หากร้านยืนยันออเดอร์แล้ว อาจจะไม่สามารถยกเลิกได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ไม่ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await controller.cancelOrder(order.orderId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ยกเลิกออเดอร์เรียบร้อย'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ไม่สามารถยกเลิกได้: ${controller.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _trackDelivery(Order order) {
    // Navigate to tracking page or show tracking info
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.delivery_dining,
                          color: Colors.purple.shade600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ออเดอร์ #${order.orderId}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'กำลังเดินทางมาส่ง',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.purple.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'ไรเดอร์: ',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(order.riderName ?? 'กำลังจัดหาไรเดอร์...'),
                          ],
                        ),
                        if (order.riderPhone != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.phone, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text(
                                'โทรศัพท์: ',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(order.riderPhone!),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Call rider
                                },
                                icon: const Icon(Icons.call, size: 16),
                                label: const Text('โทร'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(80, 32),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Text(
                              'เวลาโดยประมาณ: ',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text('${order.estimatedDeliveryTime ?? 20-30} นาที'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to map view
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ดูแผนที่',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reorder(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('สั่งซ้ำ'),
        content: Text('คุณต้องการสั่งรายการเดิมจากออเดอร์ #${order.orderId} อีกครั้งหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to restaurant with pre-filled cart
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('เพิ่มรายการลงตะกร้าแล้ว'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('สั่งซ้ำ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _rateOrder(Order order) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('รีวิวออเดอร์ #${order.orderId}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ให้คะแนนการบริการ:'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => rating = index + 1),
                    child: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'แสดงความคิดเห็น (ไม่บังคับ)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                Navigator.of(context).pop();
                // Submit rating
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ขอบคุณสำหรับรีวิว!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('ส่งรีวิว', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
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
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
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
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _initializeData(),
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;
    String description;

    switch (status) {
      case 'waiting':
        message = 'ไม่มีออเดอร์ที่รอยืนยัน';
        icon = Icons.access_time;
        description = 'ออเดอร์ที่สั่งแล้วรอร้านยืนยัน';
        break;
      case 'accepted':
        message = 'ไม่มีออเดอร์ที่กำลังเตรียม';
        icon = Icons.restaurant;
        description = 'ออเดอร์ที่ร้านกำลังเตรียมอาหาร';
        break;
      case 'delivering':
        message = 'ไม่มีออเดอร์ที่กำลังส่ง';
        icon = Icons.delivery_dining;
        description = 'ออเดอร์ที่ไรเดอร์กำลังส่งมา';
        break;
      case 'completed':
        message = 'ไม่มีออเดอร์ที่เสร็จสิ้น';
        icon = Icons.done_all;
        description = 'ออเดอร์ที่ส่งถึงแล้ว';
        break;
      case 'cancelled':
        message = 'ไม่มีออเดอร์ที่ยกเลิก';
        icon = Icons.cancel;
        description = 'ออเดอร์ที่ถูกยกเลิก';
        break;
      default:
        message = 'ไม่มีออเดอร์';
        icon = Icons.receipt_long;
        description = '';
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
              child: Icon(icon, size: 64, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _initializeData(),
              icon: const Icon(Icons.refresh),
              label: const Text('รีเฟรช'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade600,
                side: BorderSide(color: Colors.blue.shade600),
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

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}