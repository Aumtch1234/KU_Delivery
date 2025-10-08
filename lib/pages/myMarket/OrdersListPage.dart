import 'dart:async';

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
    'rider_assigned': 'รอรับ', // ออเดอร์ที่รอรับงาน (status=rider_assigned)
    'accepted':
        'รับแล้ว', // ออเดอร์ที่รับแล้ว (confirmed + going_to_shop + arrived_at_shop)
    'completed':
        'เสร็จแล้ว', // ออเดอร์เสร็จแล้ว (ready_for_pickup + picked_up + delivering + completed)
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

    // 🔁 เริ่มจับตา socket ทุก ๆ 10 วินาที
    _startAutoReconnect();
  }

  Timer? _reconnectTimer;

  void _startAutoReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      final controller = context.read<OrderController>();
      if (!controller.isSocketConnected) {
        print('⚠️ Socket disconnected. Trying to reconnect...');
        await controller.reconnectSocket();
        await controller.fetchOrdersByMarket(marketId: widget.marketId!);
      }
    });
  }

  Future<void> _initializeData() async {
    final controller = context.read<OrderController>();

    print('🏪 Initializing data for market: ${widget.marketId}');

    if (!controller.isSocketConnected) {
      await controller.initializeSocket(marketId: widget.marketId);
    }

    if (widget.marketId != null) {
      await controller.fetchOrdersByMarket(marketId: widget.marketId!);
    }

    // Debug socket status
    controller.debugSocketStatus();
  }

  // เพิ่ม method สำหรับ refresh และ debug
  Future<void> _refreshWithSocketDebug() async {
    final controller = context.read<OrderController>();

    print('🔄 Refreshing with socket debug...');
    controller.debugSocketStatus();

    if (!controller.isSocketConnected) {
      print('🔌 Socket not connected, reconnecting...');
      await controller.reconnectSocket();
    }

    await _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reconnectTimer?.cancel();
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Debug button
              IconButton(
                icon: const Icon(Icons.bug_report, color: Colors.white),
                onPressed: () {
                  controller.debugPrintOrdersState();
                  controller.forceRefreshOrders();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🐛 Debug info printed to console'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
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
      statusCounts[status] = controller.getOrdersByStatus(status).length;
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
                    case 'confirmed':
                      // case 'going_to_shop':
                      // case 'arrived_at_shop':
                      // case 'picked_up':
                      // case 'delivered':
                      // case 'arrived_at_customer':
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
        border: Border.all(color: Colors.grey.shade300, width: 1),
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
                // ข้อมูลออเดอร์และเวลา
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.orderId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _formatDateTime(order.createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // ข้อมูลลูกค้าชิดขวา
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.customerName.isNotEmpty
                              ? order.customerName
                              : 'ไม่ระบุ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.customerPhone.isNotEmpty
                              ? order.customerPhone
                              : 'ไม่ระบุ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Items
                if (order.items.isNotEmpty) ...[
                  // แสดงรายการอาหารแบบแถว
                  ...order.items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ส่วนซ้าย: ชื่ออาหาร + จำนวน + ตัวเลือก
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ชื่ออาหาร
                                  Text(
                                    item.foodName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),

                                  // จำนวน
                                  Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade500,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'จำนวน',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // ตัวเลือกเพิ่มเติม (ถ้ามี)
                                  if (item.selectedOptions.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(6),
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
                                          const SizedBox(height: 4),
                                          ...item.selectedOptions.map((option) {
                                            String optionText = '';
                                            if (option is Map) {
                                              String name =
                                                  option['label']?.toString() ??
                                                  option['name']?.toString() ??
                                                  '';
                                              String value =
                                                  option['value']?.toString() ??
                                                  '';
                                              optionText =
                                                  name +
                                                  (value.isNotEmpty
                                                      ? ': $value'
                                                      : '');
                                            } else {
                                              optionText = option.toString();
                                            }

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 2,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 4,
                                                    height: 4,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.amber.shade600,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      optionText,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey
                                                            .shade700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // แสดง additionalDetailsNote ถ้ามี
                                  if (item
                                      .additionalDetailsNote
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.orange.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.note_alt,
                                                size: 14,
                                                color: Colors.orange.shade700,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'เพิ่มเติม:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item.additionalDetailsNote,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // ส่วนขวา: กรอบราคาใหญ่ (ยาวลงถึงระดับตัวเลือก)
                            Container(
                              width: 90,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade500,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '฿${(item.originalSubtotal ?? 0).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  // const SizedBox(height: 5),
                ],

                // Delivery Address - Compact
                // Container(
                //   padding: const EdgeInsets.all(12),
                //   decoration: BoxDecoration(
                //     color: Colors.red.shade50,
                //     borderRadius: BorderRadius.circular(8),
                //     border: Border.all(color: Colors.red.shade200),
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Row(
                //         children: [
                //           Icon(
                //             Icons.location_on,
                //             size: 16,
                //             color: Colors.red.shade700,
                //           ),
                //           const SizedBox(width: 6),
                //           Text(
                //             'ที่อยู่จัดส่ง',
                //             style: TextStyle(
                //               fontSize: 13,
                //               fontWeight: FontWeight.bold,
                //               color: Colors.red.shade700,
                //             ),
                //           ),
                //           const Spacer(),
                //           if (order.distanceKm != null &&
                //               order.distanceKm! > 0) ...[
                //             Icon(
                //               Icons.straighten,
                //               size: 14,
                //               color: Colors.grey.shade600,
                //             ),
                //             const SizedBox(width: 4),
                //             Text(
                //               '${order.distanceKm!.toStringAsFixed(1)} กม.',
                //               style: TextStyle(
                //                 fontSize: 12,
                //                 fontWeight: FontWeight.w600,
                //                 color: Colors.grey.shade700,
                //               ),
                //             ),
                //           ],
                //         ],
                //       ),
                //       const SizedBox(height: 8),
                //       Text(
                //         order.address.isNotEmpty
                //             ? order.address
                //             : 'กำลังโหลดที่อยู่...',
                //         style: TextStyle(
                //           fontSize: 12,
                //           color: order.address.isNotEmpty
                //               ? Colors.grey.shade700
                //               : Colors.orange.shade600,
                //           height: 1.3,
                //         ),
                //         maxLines: 2,
                //         overflow: TextOverflow.ellipsis,
                //       ),
                //     ],
                //   ),
                // ),

                // Special Note
                if (order.note != null && order.note!.isNotEmpty) ...[
                  // const SizedBox(height: 12),
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

                const SizedBox(height: 8),

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
                                  'รายได้ร้าน',
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

                      // const SizedBox(height: 12),

                      // ข้อมูลเพิ่มเติม
                      // Container(
                      //   padding: const EdgeInsets.all(10),
                      //   decoration: BoxDecoration(
                      //     color: Colors.white,
                      //     borderRadius: BorderRadius.circular(8),
                      //   ),
                      //   child: Column(
                      //     children: [
                      //       // Use helper to build price rows
                      //       _buildPriceSummaryRow(
                      //         'ลูกค้าจ่าย (อาหาร)',
                      //         '฿${(order.totalPrice - order.deliveryFee).toStringAsFixed(0)}',
                      //         Colors.grey.shade700,
                      //       ),
                      //       const SizedBox(height: 6),
                      //       _buildPriceSummaryRow(
                      //         'ค่าบริการแพลตฟอร์ม 15%',
                      //         '฿${((order.totalPrice - order.deliveryFee) - _calculateShopRevenue(order)).toStringAsFixed(0)}',
                      //         Colors.blue.shade600,
                      //       ),
                      //       const Divider(height: 16),
                      //       _buildPriceSummaryRow(
                      //         'ค่าจัดส่ง',
                      //         '฿${order.deliveryFee.toStringAsFixed(0)}',
                      //         Colors.orange.shade600,
                      //       ),
                      //       const Divider(height: 16),
                      //       _buildPriceSummaryRow(
                      //         'ยอดรวมทั้งหมด',
                      //         '฿${order.totalPrice.toStringAsFixed(0)}',
                      //         Colors.grey.shade800,
                      //         isTotal: true,
                      //       ),
                      //     ],
                      //   ),
                      // ),
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

  Widget _buildActionButtons(Order order, OrderController controller) {
    return Row(
      children: [
        // Reject button (only for rider_assigned orders)
        if (order.status == 'rider_assigned') ...[
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
          flex: order.status == 'rider_assigned' ? 2 : 1,
          child: _buildMainActionButton(order, controller),
        ),
      ],
    );
  }

  Widget _buildMainActionButton(Order order, OrderController controller) {
    // แสดงปุ่มตามสถานะของออเดอร์ตาม flow ที่ต้องการ
    if (order.status == 'rider_assigned') {
      // แท็บรอรับ: มีไรเดอร์รับแล้ว รอร้านยืนยัน
      return ElevatedButton(
        onPressed: () => _acceptOrder(order, controller),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        child: const Text('ยืนยันรับออเดอร์'),
      );
    } else if (order.status == 'confirmed') {
      // แท็บรับแล้ว: ร้านยืนยันแล้ว
      if (order.shopStatus == null || order.shopStatus == 'preparing') {
        // ยังไม่เริ่มทำอาหารหรือกำลังทำอาหาร
        if (order.shopStatus == null) {
          return ElevatedButton(
            onPressed: () => _startPreparing(order, controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('เริ่มทำอาหาร'),
          );
        } else {
          return ElevatedButton(
            onPressed: () => _markReady(order, controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('อาหารพร้อม'),
          );
        }
      } else {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            'กำลังเตรียมอาหาร',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
    } else if (order.status == 'preparing') {
      // แท็บรับแล้ว: กำลังเตรียมอาหาร - ตรวจสอบสถานะไรเดอร์ปัจจุบัน
      String buttonText = 'อาหารพร้อม';

      // ตรวจสอบสถานะไรเดอร์เพื่อแสดงข้อความที่เหมาะสม
      if (order.riderStatus == 'going_to_shop') {
        buttonText = 'อาหารพร้อม (ไรเดอร์กำลังมา)';
      } else if (order.riderStatus == 'arrived_at_shop') {
        buttonText = 'อาหารพร้อม (ไรเดอร์ถึงร้านแล้ว)';
      }

      return ElevatedButton(
        onPressed: () => _markReady(order, controller),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        child: Text(buttonText),
      );
    } else if (order.status == 'going_to_shop') {
      // แท็บรับแล้ว: ไรเดอร์กำลังไปร้าน
      if (order.shopStatus == null) {
        // ไรเดอร์กำลังไปร้านแต่ร้านยังไม่เริ่มทำอาหาร
        return ElevatedButton(
          onPressed: () => _startPreparing(order, controller),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('เริ่มทำอาหาร (ไรเดอร์กำลังมา)'),
        );
      } else if (order.shopStatus == 'preparing') {
        return ElevatedButton(
          onPressed: () => _markReady(order, controller),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('อาหารพร้อม (ไรเดอร์กำลังมา)'),
        );
      } else {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            'ไรเดอร์กำลังมาร้าน',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
    } else if (order.status == 'arrived_at_shop') {
      // แท็บรับแล้ว: ไรเดอร์ถึงร้านแล้ว
      if (order.shopStatus == null) {
        // ไรเดอร์ถึงร้านแล้วแต่ร้านยังไม่เริ่มทำอาหาร
        return ElevatedButton(
          onPressed: () => _startPreparing(order, controller),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('เริ่มทำอาหาร (ไรเดอร์ถึงร้านแล้ว)'),
        );
      } else if (order.shopStatus == 'preparing') {
        return ElevatedButton(
          onPressed: () => _markReady(order, controller),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('อาหารพร้อม (ไรเดอร์ถึงร้านแล้ว)'),
        );
      } else {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Text(
            'ไรเดอร์ถึงร้านแล้ว',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
    } else if (order.status == 'picked_up') {
      // แท็บเสร็จแล้ว: ไรเดอร์รับของแล้ว
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Text(
          'ไรเดอร์รับของแล้ว',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else if (order.status == 'delivering') {
      // แท็บเสร็จแล้ว: ไรเดอร์กำลังส่งของ
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Text(
          'ไรเดอร์กำลังส่งของ',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else if (order.status == 'arrived_at_customer') {
      // แท็บเสร็จแล้ว: ส่งสำเร็จ
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Text(
          'ถึงที่หมายแล้ว',
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else if (order.status == 'completed') {
      // แท็บเสร็จแล้ว: ส่งสำเร็จ
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Text(
          'ส่งสำเร็จ',
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else if (order.shopStatus == 'ready_for_pickup') {
      // แท็บเสร็จแล้ว: อาหารพร้อมแล้ว รอไรเดอร์รับ (เฉพาะกรณีที่ยังไม่มีการ pickup)
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Text(
          'อาหารพร้อมแล้ว รอไรเดอร์รับ',
          style: TextStyle(
            color: Colors.orange.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          order.statusText,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
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
    final success = await controller.markFoodReady(order.orderId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อาหารพร้อมแล้ว ✅ ย้ายไปแท็บเสร็จแล้ว'),
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
      case 'rider_assigned':
        message = 'ไม่มีออเดอร์ที่รอรับ';
        icon = Icons.motorcycle;
        break;
      case 'accepted':
        message = 'ไม่มีออเดอร์ที่รับแล้ว';
        icon = Icons.check_circle;
        break;
      case 'completed':
        message = 'ไม่มีออเดอร์ที่เสร็จแล้ว';
        icon = Icons.done_all;
        break;
      case 'cancelled':
        message = 'ไม่มีออเดอร์ที่ปฏิเสธ';
        icon = Icons.cancel;
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
