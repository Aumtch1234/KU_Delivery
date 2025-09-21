import 'package:delivery/APIs/Orders/OrdersSocket.dart';
import 'package:delivery/pages/order/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrdersListPage extends StatefulWidget {
  final int? marketId;

  const OrdersListPage({Key? key, this.marketId}) : super(key: key);

  @override
  State<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends State<OrdersListPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Updated status tabs for shop workflow
  final Map<String, String> _statusTabs = {
    'waiting': 'รอยืนยัน', // ออเดอร์ใหม่ที่รอร้านรับ
    'accepted': 'กำลังทำ', // ร้านรับแล้ว กำลังเตรียมอาหาร
    'delivering': 'กำลังส่ง', // ไรเดอร์รับไปส่งแล้ว
    'completed': 'เสร็จแล้ว', // ส่งเสร็จแล้ว
    'cancelled': 'ปฏิเสธ',
  };

  String get userType {
    if (widget.marketId != null) return 'shop';
    return 'customer';
  }

  int? get currentUserId {
    switch (userType) {
      case 'shop':
        return widget.marketId;
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    final controller = context.read<OrderController>();

    print('🏪 Initializing data for market: ${widget.marketId}');

    if (!controller.isSocketConnected) {
      await controller.initializeSocket();
    }

    if (widget.marketId != null) {
      await controller.fetchOrdersByMarket(marketId: widget.marketId!);
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
      backgroundColor: Colors.white,
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
      backgroundColor: Colors.green,
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
                child: Text(
                  userType == 'shop' ? 'ออเดอร์ร้านอาหาร' : 'ออเดอร์ของฉัน',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Connection status with order count
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
                          ? Icons.wifi
                          : Icons.wifi_off,
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

    final todayEarnings = todayOrders
        .where((order) => order.status == 'completed')
        .fold(0.0, (sum, order) => sum + order.totalPrice);

    // Count orders by status for today
    final statusCounts = <String, int>{};
    for (var status in _statusTabs.keys) {
      statusCounts[status] = todayOrders
          .where((order) => order.status == status)
          .length;
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade50, Colors.green.shade100],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade200),
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
                    color: Colors.green.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: Colors.green.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'รายได้วันนี้',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '฿${todayEarnings.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
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
                  ),
                ),
                // Refresh button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
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
                  switch (status) {
                    case 'waiting':
                      color = Colors.orange;
                      break;
                    case 'accepted':
                      color = Colors.blue;
                      break;
                    case 'delivering':
                      color = Colors.purple;
                      break;
                    case 'completed':
                      color = Colors.green;
                      break;
                    default:
                      color = Colors.grey;
                  }

                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
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
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
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
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: order.statusColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Status Header - Clean design
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: order.statusColor.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: order.statusColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      order.statusIcon,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.statusText,
                          style: TextStyle(
                            color: order.statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade600,
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
                  // Payment method badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          order.paymentMethod.toLowerCase().contains('เงินสด')
                              ? Icons.payments
                              : Icons.credit_card,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order.paymentMethod,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Order Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Header: ID and Total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'หมายเลขออเดอร์',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '#${order.orderId}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                order.shopName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade500,
                                Colors.green.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.receipt_long,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '฿${order.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'ยอดรวม',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Order Items Section - Redesigned
                  if (order.items.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          // Items Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
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
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.restaurant_menu,
                                    size: 20,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'รายการอาหาร',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${order.items.length} รายการ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Items List
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: order.items.asMap().entries.map((
                                entry,
                              ) {
                                int index = entry.key;
                                OrderItem item = entry.value;

                                return Container(
                                  margin: EdgeInsets.only(
                                    bottom: index < order.items.length - 1
                                        ? 16
                                        : 0,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Food Name and Quantity
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Quantity Badge
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.green.shade500,
                                                  Colors.green.shade600,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${item.quantity}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Food Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.foodName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                // Price breakdown
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        '฿${item.sellPrice.toStringAsFixed(0)}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      Text(
                                                        ' × ${item.quantity} = ',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                        ),
                                                      ),
                                                      Text(
                                                        '฿${item.subtotal.toStringAsFixed(0)}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.green,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Selected Options - Enhanced display
                                      if (item.selectedOptions.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.amber.shade200,
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.tune,
                                                    size: 16,
                                                    color:
                                                        Colors.amber.shade700,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'ตัวเลือกเพิ่มเติม:',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.amber.shade800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              ..._buildFormattedOptions(
                                                item.selectedOptions,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],

                  // Delivery Address Section - Cleaner design
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'ที่อยู่จัดส่ง',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            order.address.isNotEmpty
                                ? order.address
                                : 'กำลังโหลดที่อยู่...',
                            style: TextStyle(
                              fontSize: 14,
                              color: order.address.isNotEmpty
                                  ? Colors.grey.shade700
                                  : Colors.orange.shade600,
                              height: 1.4,
                            ),
                          ),
                        ),

                        // Distance and Delivery Fee
                        if (order.distanceKm != null &&
                            order.distanceKm! > 0) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.straighten,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${order.distanceKm!.toStringAsFixed(1)} กม.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.local_shipping,
                                      size: 16,
                                      color: Colors.blue.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '฿${order.deliveryFee.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Special Note Section
                  if (order.note != null && order.note!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.sticky_note_2,
                                size: 18,
                                color: Colors.purple.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'หมายเหตุพิเศษ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.note!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

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

  // Enhanced function to format selected options
  List<Widget> _buildFormattedOptions(List<dynamic> options) {
    if (options.isEmpty) return [];

    return options.map((option) {
      if (option is Map) {
        String name =
            option['label']?.toString() ?? option['name']?.toString() ?? '';
        String value = option['value']?.toString() ?? '';
        String price =
            option['extraPrice']?.toString() ??
            option['price']?.toString() ??
            '';

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.amber.shade600,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (value.isNotEmpty)
                        TextSpan(
                          text: ': $value',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      if (price.isNotEmpty)
                        TextSpan(
                          text: ' (+฿$price)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.amber.shade600,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                option.toString(),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Keep the original _formatSelectedOptions for backward compatibility
  String _formatSelectedOptions(List<dynamic> options) {
    if (options.isEmpty) return '';

    return options
        .map((option) {
          if (option is Map) {
            String name =
                option['label']?.toString() ?? option['name']?.toString() ?? '';
            String value = option['value']?.toString() ?? '';
            String price =
                option['extraPrice']?.toString() ??
                option['price']?.toString() ??
                '';

            if (name.isNotEmpty) {
              if (price.isNotEmpty) {
                return '$name${value.isNotEmpty ? ": $value" : ""} (+฿$price)';
              }
              return '$name${value.isNotEmpty ? ": $value" : ""}';
            }
            return option.toString();
          }
          return option.toString();
        })
        .join(', ');
  }

  Widget _buildActionButtons(Order order, OrderController controller) {
    return Row(
      children: [
        // Reject button (only for waiting orders)
        if (order.status == 'waiting') ...[
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _showRejectDialog(order, controller),
              child: const Text(
                'ปฏิเสธ',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],

        // Main action button
        Expanded(
          flex: order.status == 'waiting' ? 2 : 1,
          child: _buildMainActionButton(order, controller),
        ),
      ],
    );
  }

  Widget _buildMainActionButton(Order order, OrderController controller) {
    String buttonText;
    Color buttonColor;
    VoidCallback? onPressed;

    switch (order.status) {
      case 'waiting':
        buttonText = 'รับออเดอร์';
        buttonColor = Colors.green;
        onPressed = () => _acceptOrder(order, controller);
        break;
      case 'accepted':
        buttonText = 'พร้อมส่ง';
        buttonColor = Colors.blue;
        onPressed = () => _markReady(order, controller);
        break;
      case 'delivering':
        buttonText = 'กำลังส่ง...';
        buttonColor = Colors.purple;
        onPressed = null; // Read only
        break;
      case 'completed':
        buttonText = 'เสร็จแล้ว';
        buttonColor = Colors.grey;
        onPressed = null; // Read only
        break;
      default:
        buttonText = order.status;
        buttonColor = Colors.grey;
        onPressed = null;
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: onPressed != null ? 2 : 0,
      ),
      onPressed: onPressed,
      child: Text(
        buttonText,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _acceptOrder(Order order, OrderController controller) async {
    final success = await controller.acceptOrder(
      order.orderId,
      widget.marketId!,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รับออเดอร์เรียบร้อย ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: ${controller.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markReady(Order order, OrderController controller) async {
    final success = await controller.updateOrderStatus(
      order.orderId,
      'delivering',
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('แจ้งพร้อมส่งเรียบร้อย 🚀'),
          backgroundColor: Colors.blue,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: ${controller.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRejectDialog(Order order, OrderController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ปฏิเสธออเดอร์'),
        content: Text('คุณต้องการปฏิเสธออเดอร์ #${order.orderId} หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await controller.updateOrderStatus(
                order.orderId,
                'cancelled',
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ปฏิเสธออเดอร์เรียบร้อย'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('ปฏิเสธ', style: TextStyle(color: Colors.white)),
          ),
        ],
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

    switch (status) {
      case 'waiting':
        message = 'ไม่มีออเดอร์ที่รอยืนยัน';
        icon = Icons.access_time;
        break;
      case 'accepted':
        message = 'ไม่มีออเดอร์ที่กำลังทำ';
        icon = Icons.restaurant;
        break;
      case 'delivering':
        message = 'ไม่มีออเดอร์ที่กำลังส่ง';
        icon = Icons.delivery_dining;
        break;
      case 'completed':
        message = 'ไม่มีออเดอร์ที่เสร็จแล้ว';
        icon = Icons.done_all;
        break;
      default:
        message = 'ไม่มีออเดอร์';
        icon = Icons.receipt_long;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => _initializeData(),
              child: const Text('รีเฟรช'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
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
