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
    'confirmed': 'กำลังทำ', // ร้านยืนยันแล้ว กำลังเตรียมอาหาร/พร้อมส่ง
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

    // Count orders by status for all orders
    final statusCounts = <String, int>{};
    for (var status in _statusTabs.keys) {
      statusCounts[status] = controller.orders
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
                      // Text(
                      //   'รายได้วันนี้',
                      //   style: TextStyle(
                      //     fontSize: 16,
                      //     color: Colors.grey.shade700,
                      //     fontWeight: FontWeight.w500,
                      //   ),
                      // ),
                      // const SizedBox(height: 4),
                      // Text(
                      //   '฿${todayEarnings.toStringAsFixed(2)}',
                      //   style: TextStyle(
                      //     fontSize: 24,
                      //     fontWeight: FontWeight.bold,
                      //     color: Colors.green.shade700,
                      //   ),
                      // ),
                      // Text(
                      //   '${todayOrders.length} ออเดอร์ (ทั้งหมด ${controller.orders.length})',
                      //   style: TextStyle(
                      //     fontSize: 14,
                      //     color: Colors.grey.shade600,
                      //   ),
                      // ),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order ID + Status
          Container(
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: order.statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(order.statusIcon, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.orderId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _formatDateTime(order.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: order.statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop name & Payment
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.shopName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            order.paymentMethod.toLowerCase().contains('เงินสด')
                                ? Icons.payments
                                : Icons.credit_card,
                            size: 14,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.paymentMethod,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Order Items
                if (order.items.isNotEmpty) ...[
                  ...order.items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Quantity
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Food name
                              Expanded(
                                child: Text(
                                  item.foodName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Pricing comparison - เน้นที่เงินที่ร้านได้
                          Row(
                            children: [
                              // รายได้ร้าน (ราคาต้นทุน) - เด่นกว่า
                              Expanded(
                                flex: 3,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green.shade400,
                                        Colors.green.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.account_balance_wallet,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'รายได้ร้าน',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '฿${(item.originalSubtotal ?? 0).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'ไม่รวมตัวเลือก ฿${item.originalPrice!.toStringAsFixed(0)} × ${item.quantity} = ${(item.originalPrice! * item.quantity).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      if (item.originalPrice != null &&
                                          item.originalPrice! > 0)
                                        Builder(
                                          builder: (context) {
                                            double originalOptionsTotal = 0.0;
                                            if (item.originalOptions != null) {
                                              for (var option
                                                  in item.originalOptions!) {
                                                if (option is Map &&
                                                    option['extraPrice'] !=
                                                        null) {
                                                  originalOptionsTotal +=
                                                      (option['extraPrice']
                                                              as num)
                                                          .toDouble();
                                                }
                                              }
                                            }
                                            return Text(
                                              'รวมตัวเลือก ฿${(item.originalPrice! + originalOptionsTotal).toStringAsFixed(0)} × ${item.quantity} = ${(item.originalPrice! + originalOptionsTotal) * item.quantity}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white70,
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // ราคาลูกค้าจ่าย - รอง
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ลูกค้าจ่าย',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '฿${item.subtotal.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      Text(
                                        'ไม่รวมตัวเลือก ฿${item.sellPrice.toStringAsFixed(0)} × ${item.quantity} = ${(item.sellPrice * item.quantity).toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      if (item.sellPrice != null &&
                                          item.sellPrice > 0)
                                        Builder(
                                          builder: (context) {
                                            double sellOptionsTotal = 0.0;
                                            if (item.selectedOptions != null) {
                                              for (var option
                                                  in item.selectedOptions) {
                                                if (option is Map &&
                                                    option['extraPrice'] !=
                                                        null) {
                                                  sellOptionsTotal +=
                                                      (option['extraPrice']
                                                              as num)
                                                          .toDouble();
                                                }
                                              }
                                            }
                                            return Text(
                                              'รวมตัวเลือก ฿${(item.sellPrice + sellOptionsTotal).toStringAsFixed(0)} × ${item.quantity} = ${(item.sellPrice + sellOptionsTotal) * item.quantity}',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey.shade600,
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Selected Options
                          if (item.selectedOptions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.amber.shade200,
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.tune,
                                        size: 12,
                                        color: Colors.amber.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ตัวเลือกเพิ่มเติม',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ..._buildFormattedOptionsWithCost(
                                    item.selectedOptions,
                                    item.originalOptions,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),

                  const Divider(height: 24),
                ],

                // Delivery Address - Compact
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ที่อยู่จัดส่ง',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const Spacer(),
                          if (order.distanceKm != null &&
                              order.distanceKm! > 0) ...[
                            Icon(
                              Icons.straighten,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${order.distanceKm!.toStringAsFixed(1)} กม.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.address.isNotEmpty
                            ? order.address
                            : 'กำลังโหลดที่อยู่...',
                        style: TextStyle(
                          fontSize: 12,
                          color: order.address.isNotEmpty
                              ? Colors.grey.shade700
                              : Colors.orange.shade600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Special Note
                if (order.note != null && order.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.sticky_note_2,
                          size: 16,
                          color: Colors.purple.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.note!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Price Summary - เน้นรายได้ร้าน
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.green.shade100],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade300, width: 2),
                  ),
                  child: Column(
                    children: [
                      // รายได้ร้านจากอาหาร (ไฮไลท์)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.store,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'รายได้ร้าน (อาหาร)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '฿${_calculateShopRevenue(order).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ข้อมูลเพิ่มเติม
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // ลูกค้าจ่าย (อาหาร)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ลูกค้าจ่าย (อาหาร)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '฿${(order.totalPrice - order.deliveryFee).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // ส่วนต่างที่บริษัทได้
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business,
                                      size: 12,
                                      color: Colors.blue.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ค่าบริการแพลตฟอร์ม 15%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '฿${((order.totalPrice - order.deliveryFee) - _calculateShopRevenue(order)).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            // ค่าจัดส่ง
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ค่าจัดส่ง',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  '฿${order.deliveryFee.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            // ยอดรวมทั้งหมด
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ยอดรวมทั้งหมด',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '฿${order.totalPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                _buildActionButtons(order, controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Calculate shop revenue from original subtotals
  double _calculateShopRevenue(Order order) {
    if (order.originalTotalPrice != null && order.originalTotalPrice! > 0) {
      return order.originalTotalPrice!;
    }

    // Calculate from original subtotals of items
    double totalOriginalSubtotal = 0.0;
    for (var item in order.items) {
      if (item.originalSubtotal != null && item.originalSubtotal! > 0) {
        totalOriginalSubtotal += item.originalSubtotal!;
      } else {
        // Fallback: calculate based on sell price (assuming 85% of sell price is original)
        totalOriginalSubtotal += (item.subtotal * 0.85);
      }
    }

    return totalOriginalSubtotal;
  }

  // Enhanced function to format selected options with cost comparison
  List<Widget> _buildFormattedOptionsWithCost(
    List<dynamic> selectedOptions,
    List<dynamic>? originalOptions,
  ) {
    if (selectedOptions.isEmpty) return [];

    // สร้าง map ของราคาต้นทุนจาก originalOptions
    Map<String, double> costMap = {};
    if (originalOptions != null) {
      for (var origOption in originalOptions) {
        if (origOption is Map) {
          String name =
              origOption['label']?.toString() ??
              origOption['name']?.toString() ??
              '';
          double cost = (origOption['extraPrice'] as num?)?.toDouble() ?? 0.0;
          if (name.isNotEmpty) {
            costMap[name.toLowerCase()] = cost;
          }
        }
      }
    }

    return selectedOptions.map((option) {
      if (option is Map) {
        String name =
            option['label']?.toString() ?? option['name']?.toString() ?? '';
        String value = option['value']?.toString() ?? '';
        String sellPrice =
            option['extraPrice']?.toString() ??
            option['price']?.toString() ??
            '';

        // หาราคาต้นทุนที่ตรงกัน
        double costPrice = costMap[name.toLowerCase()] ?? 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.amber.shade300, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      name + (value.isNotEmpty ? ': $value' : ''),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // แสดงราคาขายและราคาต้นทุน
              Row(
                children: [
                  const SizedBox(width: 14),
                  if (sellPrice.isNotEmpty) ...[
                    Text(
                      'ราคาขาย: +฿$sellPrice',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade600,
                      ),
                    ),
                    if (costPrice > 0) ...[
                      Text(
                        ' | ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        'ต้นทุน: +฿${costPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ] else if (costPrice > 0) ...[
                    Text(
                      'ต้นทุน: +฿${costPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ],
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
      case 'confirmed':
        buttonText = 'เริ่มทำอาหาร';
        buttonColor = Colors.blue;
        onPressed = () => _startPreparing(order, controller);
        break;
      case 'preparing':
        buttonText = 'อาหารพร้อม';
        buttonColor = Colors.orange;
        onPressed = () => _markReady(order, controller);
        break;
      case 'ready_for_pickup':
        buttonText = 'รอไรเดอร์มารับ';
        buttonColor = Colors.purple;
        onPressed = null; // ร้านรอไรเดอร์มารับ
        break;
      case 'rider_assigned':
      case 'going_to_shop':
        buttonText = 'ไรเดอร์กำลังมา';
        buttonColor = Colors.indigo;
        onPressed = null; // Read only
        break;
      case 'arrived_at_shop':
        buttonText = 'ไรเดอร์ถึงร้านแล้ว';
        buttonColor = Colors.indigo;
        onPressed = null; // Read only
        break;
      case 'picked_up':
      case 'delivering':
      case 'arrived_at_customer':
        buttonText = 'กำลังส่ง...';
        buttonColor = Colors.teal;
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
    final success = await controller.updateOrderStatus(
      order.orderId,
      'confirmed',
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

  Future<void> _startPreparing(Order order, OrderController controller) async {
    final success = await controller.updatePreparationStatus(
      order.orderId,
      'preparing',
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เริ่มเตรียมอาหารแล้ว 👨‍🍳'),
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

  Future<void> _markReady(Order order, OrderController controller) async {
    final success = await controller.updatePreparationStatus(
      order.orderId,
      'ready_for_pickup',
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อาหารพร้อมแล้ว รอไรเดอร์มารับ 🍽️'),
          backgroundColor: Colors.orange,
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

  Widget _buildPriceSummaryRow(
    String label,
    String amount,
    Color color, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
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
