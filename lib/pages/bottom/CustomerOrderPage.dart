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

  // Updated status tabs with all 11 statuses
  final Map<String, Map<String, dynamic>> _statusTabs = {
    'all': {'name': 'ทั้งหมด', 'icon': Icons.list_alt},
    'waiting': {'name': 'รอยืนยัน', 'icon': Icons.schedule},
    'confirmed': {'name': 'ยืนยันแล้ว', 'icon': Icons.check_circle},
    'preparing': {'name': 'กำลังทำ', 'icon': Icons.restaurant_menu},
    'ready_for_pickup': {'name': 'พร้อมส่ง', 'icon': Icons.shopping_bag},
    'rider_assigned': {'name': 'มีไรเดอร์', 'icon': Icons.motorcycle},
    'going_to_shop': {'name': 'ไปร้าน', 'icon': Icons.directions},
    'arrived_at_shop': {'name': 'ถึงร้าน', 'icon': Icons.store},
    'picked_up': {'name': 'รับแล้ว', 'icon': Icons.takeout_dining},
    'delivering': {'name': 'กำลังส่ง', 'icon': Icons.delivery_dining},
    'arrived_at_customer': {'name': 'ถึงแล้ว', 'icon': Icons.home},
    'completed': {'name': 'เสร็จแล้ว', 'icon': Icons.check_circle},
    'cancelled': {'name': 'ยกเลิก', 'icon': Icons.cancel},
  };

  // Green theme colors
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color primaryLight = Color(0xFF81C784);
  // static const Color primaryDark = Color(0xFF388E3C);
  // static const Color accentColor = Color(0xFF66BB6A);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color backgroundColor = Color(0xFFF1F8E9);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1B5E20);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color surfaceColor = Color(0xFFE8F5E8);

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
      final aActive = [
        'waiting',
        'confirmed',
        'preparing',
        'ready_for_pickup',
        'rider_assigned',
        'going_to_shop',
        'arrived_at_shop',
        'picked_up',
        'delivering',
        'arrived_at_customer',
      ].contains(a.status);
      final bActive = [
        'waiting',
        'confirmed',
        'preparing',
        'ready_for_pickup',
        'rider_assigned',
        'going_to_shop',
        'arrived_at_shop',
        'picked_up',
        'delivering',
        'arrived_at_customer',
      ].contains(b.status);

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
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: textPrimary,
          ),
        ),
        backgroundColor: cardColor,
        foregroundColor: textPrimary,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardColor, primaryColor.withOpacity(0.05)],
            ),
          ),
        ),
        actions: [
          Consumer<OrderController>(
            builder: (context, controller, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: controller.isSocketConnected
                        ? [successColor, primaryLight]
                        : [errorColor, errorColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (controller.isSocketConnected
                                  ? successColor
                                  : errorColor)
                              .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                    const SizedBox(width: 8),
                    Text(
                      '${controller.orders.length} ออเดอร์',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
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
          preferredSize: const Size.fromHeight(70),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Consumer<OrderController>(
              builder: (context, controller, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicator: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorPadding: const EdgeInsets.all(4),
                    labelColor: Colors.white,
                    unselectedLabelColor: textSecondary,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    tabs: _statusTabs.entries.map((entry) {
                      final count = _getOrderCountByStatus(
                        controller,
                        entry.key,
                      );
                      return Tab(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(entry.value['icon'], size: 16),
                              const SizedBox(width: 8),
                              Text(entry.value['name']),
                              if (count > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _currentStatus == entry.key
                                        ? Colors.white.withOpacity(0.25)
                                        : primaryColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'กำลังโหลดข้อมูลออเดอร์...',
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
                backgroundColor: cardColor,
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
    final isActive = [
      'waiting',
      'confirmed',
      'preparing',
      'ready_for_pickup',
      'rider_assigned',
      'going_to_shop',
      'arrived_at_shop',
      'picked_up',
      'delivering',
      'arrived_at_customer',
    ].contains(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
        border: isActive
            ? Border.all(color: primaryColor.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Enhanced Status Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    order.statusColor.withOpacity(0.15),
                    order.statusColor.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          order.statusColor.withOpacity(0.2),
                          order.statusColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: order.statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      order.statusIcon,
                      color: order.statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: order.statusColor,
                                ),
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      order.statusColor,
                                      order.statusColor.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: order.statusColor.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'กำลังดำเนินการ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ออเดอร์ #${order.orderId}',
                          style: TextStyle(
                            fontSize: 15,
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced Order Details
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Shop Info with enhanced design
                  if (order.shopName.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.restaurant,
                              size: 20,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ร้านอาหาร',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.shopName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Order Items Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.shopping_cart,
                                size: 18,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'รายการอาหาร (${order.items.length} รายการ)',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...order.items
                            .map((item) => _buildOrderItem(item))
                            .toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Delivery & Payment Info
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.location_on,
                          title: 'ที่อยู่จัดส่ง',
                          subtitle: _getShortAddress(order.address),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.payment,
                          title: 'ชำระเงิน',
                          subtitle: order.paymentMethod,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Distance & Delivery Type
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.directions,
                          title: 'ระยะทาง',
                          subtitle:
                              '${order.distanceKm?.toStringAsFixed(1) ?? 'N/A'} กม.',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.delivery_dining,
                          title: 'ประเภทจัดส่ง',
                          subtitle: order.deliveryType,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Time and Total Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.1),
                          primaryColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'เวลาสั่ง',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDateTime(order.createdAt),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'ยอดรวม',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '฿${order.totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            if (order.deliveryFee > 0)
                              Text(
                                'รวมค่าส่ง ฿${order.deliveryFee.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
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
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            successColor.withOpacity(0.15),
                            successColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: successColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule, size: 20, color: successColor),
                          const SizedBox(width: 10),
                          Text(
                            'เวลาโดยประมาณ: 25-30 นาที',
                            style: TextStyle(
                              fontSize: 15,
                              color: successColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Note if available
                  if (order.note != null && order.note!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: warningColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.note, size: 18, color: warningColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'หมายเหตุ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: warningColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.note!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Action Button for Waiting Orders
                  if (order.status == 'waiting') ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showCancelDialog(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: errorColor,
                          side: BorderSide(
                            color: errorColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.cancel_outlined, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'ยกเลิกออเดอร์',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
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

  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${item.quantity}x',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.foodName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                if (item.selectedOptions.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ตัวเลือก: ${item.selectedOptions.join(", ")}',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '฿${item.subtotal.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: primaryColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getShortAddress(String address) {
    final parts = address.split(' ');
    if (parts.length > 6) {
      return '${parts.take(6).join(' ')}...';
    }
    return address;
  }

  Widget _buildProgressBar(String status) {
    final steps = [
      'waiting',
      'rider_assigned',
      'confirmed',
      'preparing',
      'ready_for_pickup',
      'going_to_shop',
      'arrived_at_shop',
      'picked_up',
      'delivering',
      'arrived_at_customer',
      'completed',
    ];
    final stepNames = [
      'รอยืนยัน',
      'มีไรเดอร์',
      'ยืนยัน',
      'เตรียม',
      'พร้อม',
      'ไปร้าน',
      'ถึงร้าน',
      'รับแล้ว',
      'ส่ง',
      'ถึงแล้ว',
      'เสร็จ',
    ];

    // หาตำแหน่งปัจจุบัน
    int currentIndex = steps.indexOf(status);
    if (currentIndex == -1) {
      currentIndex = 0; // default to first step if status not found
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final isActive = index <= currentIndex;
              final isCurrent = index == currentIndex;

              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(
                    right: index < steps.length - 1 ? 2 : 0,
                  ),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: isCurrent
                                ? [primaryColor, primaryLight]
                                : [successColor, successColor.withOpacity(0.8)],
                          )
                        : null,
                    color: !isActive ? Colors.grey.shade300 : null,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: (isCurrent ? primaryColor : successColor)
                                  .withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stepNames.asMap().entries.map((entry) {
              final index = entry.key;
              final isActive = index <= currentIndex;
              final isCurrent = index == currentIndex;

              return Expanded(
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isActive
                        ? (isCurrent ? primaryColor : successColor)
                        : Colors.grey.shade500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.cancel_outlined, color: errorColor, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'ยกเลิกออเดอร์',
              style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'คุณต้องการยกเลิกออเดอร์ #${order.orderId} หรือไม่?\n\nหมายเหตุ: หากร้านยืนยันออเดอร์แล้ว อาจจะไม่สามารถยกเลิกได้',
            style: TextStyle(fontSize: 14, color: textSecondary, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'ไม่ยกเลิก',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    content: Row(
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            success
                                ? 'ยกเลิกออเดอร์เรียบร้อยแล้ว'
                                : 'ไม่สามารถยกเลิกได้: ${controller.error}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: success ? successColor : errorColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
                if (success) {
                  _loadCustomerOrders();
                }
              }
            },
            child: const Text(
              'ยกเลิก',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
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
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    errorColor.withOpacity(0.15),
                    errorColor.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 64, color: errorColor),
            ),
            const SizedBox(height: 32),
            const Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              controller.error ?? 'ไม่สามารถโหลดข้อมูลได้',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: textSecondary, height: 1.5),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _loadCustomerOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text(
                'ลองใหม่อีกครั้ง',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
      case 'confirmed':
        title = 'ไม่มีออเดอร์ที่ยืนยันแล้ว';
        subtitle = 'ออเดอร์ที่ร้านยืนยันรับแล้วจะปรากฏที่นี่';
        iconData = Icons.check_circle;
        break;
      case 'preparing':
        title = 'ไม่มีออเดอร์ที่กำลังทำ';
        subtitle = 'ออเดอร์ที่ร้านกำลังเตรียมจะปรากฏที่นี่';
        iconData = Icons.restaurant_menu;
        break;
      case 'ready_for_pickup':
        title = 'ไม่มีออเดอร์ที่พร้อมส่ง';
        subtitle = 'ออเดอร์ที่พร้อมให้ไรเดอร์รับจะปรากฏที่นี่';
        iconData = Icons.shopping_bag;
        break;
      case 'rider_assigned':
        title = 'ไม่มีออเดอร์ที่มีไรเดอร์';
        subtitle = 'ออเดอร์ที่มีไรเดอร์รับงานแล้วจะปรากฏที่นี่';
        iconData = Icons.motorcycle;
        break;
      case 'going_to_shop':
        title = 'ไม่มีไรเดอร์ที่กำลังไปร้าน';
        subtitle = 'ไรเดอร์ที่กำลังไปรับอาหารจะปรากฏที่นี่';
        iconData = Icons.directions;
        break;
      case 'arrived_at_shop':
        title = 'ไม่มีไรเดอร์ที่ถึงร้านแล้ว';
        subtitle = 'ไรเดอร์ที่ถึงร้านแล้วจะปรากฏที่นี่';
        iconData = Icons.store;
        break;
      case 'picked_up':
        title = 'ไม่มีออเดอร์ที่รับแล้ว';
        subtitle = 'ออเดอร์ที่ไรเดอร์รับจากร้านแล้วจะปรากฏที่นี่';
        iconData = Icons.takeout_dining;
        break;
      case 'delivering':
        title = 'ไม่มีออเดอร์ที่กำลังส่ง';
        subtitle = 'ออเดอร์ที่กำลังส่งจะปรากฏที่นี่';
        iconData = Icons.delivery_dining;
        break;
      case 'arrived_at_customer':
        title = 'ไม่มีไรเดอร์ที่ถึงแล้ว';
        subtitle = 'ไรเดอร์ที่มาถึงที่จัดส่งแล้วจะปรากฏที่นี่';
        iconData = Icons.home;
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
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade100, Colors.grey.shade50],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, size: 80, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(fontSize: 16, color: textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _loadCustomerOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor,
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'รีเฟรช',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
      return 'วันนี้ ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = [
        'จันทร์',
        'อังคาร',
        'พุธ',
        'พฤหัสบดี',
        'ศุกร์',
        'เสาร์',
        'อาทิตย์',
      ];
      final weekday = weekdays[dateTime.weekday - 1];
      return '$weekday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
