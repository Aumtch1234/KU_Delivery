// pages/order_tracking_page.dart
import 'package:delivery/APIs/Orders/OrdersSocket.dart';
import 'package:delivery/pages/order/models/OrderTimelinePage.dart';
import 'package:delivery/pages/order/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderTrackingPage extends StatefulWidget {
  final int orderId;

  const OrderTrackingPage({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeOrder();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  Future<void> _initializeOrder() async {
    final controller = context.read<OrderController>();
    
    // Initialize socket connection if not connected
    if (!controller.isSocketConnected) {
      await controller.initializeSocket();
    }
    
    // Watch the specific order
    controller.watchOrder(widget.orderId);
    
    // Fetch initial order data
    await controller.fetchOrderById(widget.orderId);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    context.read<OrderController>().stopWatchingOrder();
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
              _buildAppBar(context, controller),
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildOrderContent(context, controller),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, OrderController controller) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ติดตามออเดอร์',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '#${widget.orderId}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        // Connection status indicator
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: Stack(
            children: [
              Icon(
                controller.isSocketConnected ? Icons.wifi : Icons.wifi_off,
                color: controller.isSocketConnected ? Colors.green : Colors.red,
              ),
              if (controller.isSocketConnected)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Debug menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(value, controller),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'debug',
              child: Row(
                children: [
                  Icon(Icons.bug_report, size: 20),
                  SizedBox(width: 8),
                  Text('Debug Info'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('รีเฟรช'),
                ],
              ),
            ),
              PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.cancel, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('ยกเลิกออเดอร์', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderContent(BuildContext context, OrderController controller) {
    if (controller.isLoading) {
      return _buildLoadingState();
    }

    if (controller.error != null) {
      return _buildErrorState(controller);
    }

    final order = controller.currentOrder;
    if (order == null) {
      return _buildNotFoundState();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          _buildStatusHeader(order),
          const SizedBox(height: 20),
          
          // Timeline
          OrderTimelineWidget(order: order),
          const SizedBox(height: 20),
          
          // Status cards
          _buildStatusCards(order),
          const SizedBox(height: 20),
          
          // Order details
          _buildOrderDetails(order),
          const SizedBox(height: 20),
          
          // Action buttons
          _buildActionButtons(order, controller),
          
          // Test buttons (for debugging)
            const SizedBox(height: 20),
            _buildTestButtons(controller),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                    strokeWidth: 3,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'กำลังโหลดข้อมูลออเดอร์...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(OrderController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
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
            ElevatedButton.icon(
              onPressed: () {
                controller.clearError();
                _initializeOrder();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'ไม่พบออเดอร์',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ออเดอร์ #${widget.orderId} ไม่พบในระบบ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('กลับ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Order order) {
    return Container(
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  size: 24,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: order.statusColor,
                      ),
                    ),
                    Text(
                      'อัปเดตล่าสุด: ${_formatTime(order.updatedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards(Order order) {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            '🏪 ร้านค้า',
            order.isAccepted || order.isRiderAssigned || order.isDelivering || order.isCompleted 
              ? 'รับออเดอร์แล้ว' 
              : 'รอการยืนยัน',
            order.isAccepted || order.isRiderAssigned || order.isDelivering || order.isCompleted,
            Icons.store,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            '🏍️ ไรเดอร์',
            order.hasRider ? 'รับงานแล้ว' : 'กำลังหาไรเดอร์',
            order.hasRider,
            Icons.delivery_dining,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(String title, String subtitle, bool isCompleted, IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green.shade200 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.access_time,
                color: isCompleted ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(Order order) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'รายละเอียดออเดอร์',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('เลขที่ออเดอร์', '#${order.orderId}'),
            _buildDetailRow('วันที่สั่ง', _formatDateTime(order.createdAt)),
            if (order.address.isNotEmpty)
              _buildDetailRow('ที่อยู่จัดส่ง', order.address),
            _buildDetailRow('ประเภทการจัดส่ง', order.deliveryType),
            _buildDetailRow('วิธีการชำระเงิน', order.paymentMethod),
            if (order.riderId != null)
              _buildDetailRow('ไรเดอร์', 'ID: ${order.riderId}'),
            const Divider(height: 20),
            _buildDetailRow(
              'ค่าจัดส่ง', 
              '฿${order.deliveryFee.toStringAsFixed(2)}',
              isAmount: true,
            ),
            _buildDetailRow(
              'ยอดรวม', 
              '฿${order.totalPrice.toStringAsFixed(2)}',
              isAmount: true,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAmount = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isAmount ? Colors.green.shade700 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Order order, OrderController controller) {
    List<Widget> buttons = [];

    // Customer buttons
      if (order.isPending || order.isAccepted) {
        buttons.add(
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showCancelDialog(order, controller),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('ยกเลิกออเดอร์'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        );
      }

    // Shop buttons
      if (order.isPending) {
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => controller.acceptOrder(order.orderId, order.marketId),
              icon: const Icon(Icons.check),
              label: const Text('รับออเดอร์'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        );
      } else if (order.isAccepted && !order.hasRider) {
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => controller.updateOrderStatus(order.orderId, 'preparing'),
              icon: const Icon(Icons.restaurant),
              label: const Text('เริ่มเตรียมอาหาร'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        );
      }

    // Rider buttons
      if (order.isAccepted && !order.hasRider) {
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => controller.assignRider(order.orderId, 1), // Replace with actual rider ID
              icon: const Icon(Icons.delivery_dining),
              label: const Text('รับงาน'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        );
      }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(
      children: buttons,
    );
  }

  Widget _buildTestButtons(OrderController controller) {
    return Card(
      elevation: 0,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Test Functions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTestButton('Shop Accept', () {
                  controller.acceptOrder(widget.orderId, 1);
                }, Colors.green),
                _buildTestButton('Rider Accept', () {
                  controller.assignRider(widget.orderId, 1);
                }, Colors.blue),
                _buildTestButton('Preparing', () {
                  controller.updateOrderStatus(widget.orderId, 'preparing');
                }, Colors.orange),
                _buildTestButton('Ready', () {
                  controller.updateOrderStatus(widget.orderId, 'ready_for_pickup');
                }, Colors.purple),
                _buildTestButton('Delivering', () {
                  controller.updateOrderStatus(widget.orderId, 'delivering');
                }, Colors.teal),
                _buildTestButton('Complete', () {
                  controller.updateOrderStatus(widget.orderId, 'completed');
                }, Colors.green.shade700),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed, Color color) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 12),
        ),
        child: Text(label),
      ),
    );
  }

  void _handleMenuAction(String action, OrderController controller) {
    switch (action) {
      case 'debug':
        _showDebugDialog(controller);
        break;
      case 'refresh':
        _initializeOrder();
        break;
      case 'cancel':
        if (controller.currentOrder != null) {
          _showCancelDialog(controller.currentOrder!, controller);
        }
        break;
    }
  }

  void _showDebugDialog(OrderController controller) {
    final connectionStatus = controller.isSocketConnected;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Order ID: ${widget.orderId}'),
              Text('Socket Connected: $connectionStatus'),
              Text('Is Loading: ${controller.isLoading}'),
              Text('Has Error: ${controller.error != null}'),
              if (controller.error != null)
                Text('Error: ${controller.error}'),
              if (controller.currentOrder != null) ...[
                const Divider(),
                Text('Current Status: ${controller.currentOrder!.status}'),
                Text('Has Shop: ${!controller.currentOrder!.isPending}'),
                Text('Has Rider: ${controller.currentOrder!.hasRider}'),
                Text('Rider ID: ${controller.currentOrder!.riderId ?? 'None'}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(Order order, OrderController controller) {
    String reason = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยกเลิกออเดอร์'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('คุณต้องการยกเลิกออเดอร์นี้หรือไม่?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'เหตุผลในการยกเลิก (ไม่บังคับ)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) => reason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ไม่ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await controller.cancelOrder(order.orderId, reason);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ยกเลิกออเดอร์เรียบร้อยแล้ว'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}