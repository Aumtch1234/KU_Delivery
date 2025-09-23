// widgets/order_timeline_widget.dart
import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrderTimelineWidget extends StatelessWidget {
  final Order order;

  const OrderTimelineWidget({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final steps = _getOrderSteps();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'สถานะการจัดส่ง',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == steps.length - 1;

              return _buildTimelineItem(
                step: step,
                isLast: isLast,
                context: context,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  List<TimelineStep> _getOrderSteps() {
    final steps = <TimelineStep>[
      TimelineStep(
        title: 'ได้รับออเดอร์',
        subtitle: 'ระบบได้รับออเดอร์เรียบร้อย',
        icon: Icons.receipt_long,
        status: TimelineStatus.completed,
        time: order.createdAt,
      ),
    ];

    // Shop confirmation
    if (order.isConfirmed ||
        order.isPreparing ||
        order.isReadyForPickup ||
        order.isRiderAssigned ||
        order.isGoingToShop ||
        order.isArrivedAtShop ||
        order.isPickedUp ||
        order.isDelivering ||
        order.isArrivedAtCustomer ||
        order.isCompleted) {
      steps.add(
        TimelineStep(
          title: 'ร้านยืนยันออเดอร์',
          subtitle: 'ร้านค้ารับออเดอร์แล้ว',
          icon: Icons.store_mall_directory,
          status: TimelineStatus.completed,
          time: order.updatedAt,
        ),
      );
    } else if (order.isPending) {
      steps.add(
        TimelineStep(
          title: 'รอร้านยืนยัน',
          subtitle: 'กำลังรอร้านค้ายืนยันออเดอร์',
          icon: Icons.store_mall_directory,
          status: TimelineStatus.current,
        ),
      );
    }

    // Order preparation
    if (order.isPreparing) {
      steps.add(
        TimelineStep(
          title: 'กำลังเตรียมอาหาร',
          subtitle: 'ร้านค้ากำลังเตรียมอาหาร',
          icon: Icons.restaurant,
          status: TimelineStatus.current,
          time: order.updatedAt,
        ),
      );
    } else if (order.isReadyForPickup ||
        order.isRiderAssigned ||
        order.isGoingToShop ||
        order.isArrivedAtShop ||
        order.isPickedUp ||
        order.isDelivering ||
        order.isArrivedAtCustomer ||
        order.isCompleted) {
      steps.add(
        TimelineStep(
          title: 'เตรียมอาหารเสร็จ',
          subtitle: 'อาหารเตรียมเสร็จแล้ว',
          icon: Icons.restaurant,
          status: TimelineStatus.completed,
        ),
      );
    } else if (order.isConfirmed) {
      steps.add(
        TimelineStep(
          title: 'รอเตรียมอาหาร',
          subtitle: 'รอร้านเตรียมอาหาร',
          icon: Icons.restaurant,
          status: TimelineStatus.pending,
        ),
      );
    }

    // Ready for pickup
    if (order.isReadyForPickup) {
      steps.add(
        TimelineStep(
          title: 'พร้อมให้รับ',
          subtitle: 'อาหารพร้อมให้ไรเดอร์รับ',
          icon: Icons.shopping_bag,
          status: TimelineStatus.current,
          time: order.updatedAt,
        ),
      );
    } else if (order.isRiderAssigned ||
        order.isGoingToShop ||
        order.isArrivedAtShop ||
        order.isPickedUp ||
        order.isDelivering ||
        order.isArrivedAtCustomer ||
        order.isCompleted) {
      steps.add(
        TimelineStep(
          title: 'ไรเดอร์รับแล้ว',
          subtitle: 'ไรเดอร์รับอาหารแล้ว',
          icon: Icons.shopping_bag,
          status: TimelineStatus.completed,
        ),
      );
    }

    // Rider assignment
    if (order.isRiderAssigned && !order.isGoingToShop) {
      steps.add(
        TimelineStep(
          title: 'มีไรเดอร์รับงาน',
          subtitle: 'ไรเดอร์รับงานแล้ว',
          icon: Icons.delivery_dining,
          status: TimelineStatus.current,
          time: order.updatedAt,
        ),
      );
    } else if (order.isGoingToShop ||
        order.isArrivedAtShop ||
        order.isPickedUp ||
        order.isDelivering ||
        order.isArrivedAtCustomer ||
        order.isCompleted) {
      steps.add(
        TimelineStep(
          title: 'ไรเดอร์เดินทางไปร้าน',
          subtitle: 'ไรเดอร์กำลังไปรับอาหาร',
          icon: Icons.delivery_dining,
          status: TimelineStatus.completed,
        ),
      );
    } else if (order.isReadyForPickup) {
      steps.add(
        TimelineStep(
          title: 'กำลังหาไรเดอร์',
          subtitle: 'กำลังค้นหาไรเดอร์',
          icon: Icons.delivery_dining,
          status: TimelineStatus.current,
        ),
      );
    } else if (order.isPreparing || order.isConfirmed) {
      steps.add(
        TimelineStep(
          title: 'รอไรเดอร์',
          subtitle: 'รออาหารเตรียมเสร็จก่อน',
          icon: Icons.delivery_dining,
          status: TimelineStatus.pending,
        ),
      );
    }

    // Going to shop
    if (order.isGoingToShop) {
      steps.add(
        TimelineStep(
          title: 'ไรเดอร์เดินทางไปร้าน',
          subtitle: 'ไรเดอร์กำลังไปรับอาหาร',
          icon: Icons.directions_bike,
          status: TimelineStatus.current,
          time: order.updatedAt,
        ),
      );
    } else if (order.isArrivedAtShop ||
        order.isPickedUp ||
        order.isDelivering ||
        order.isArrivedAtCustomer ||
        order.isCompleted) {
      steps.add(
        TimelineStep(
          title: 'ไรเดอร์ถึงร้านแล้ว',
          subtitle: 'ไรเดอร์มาถึงร้านแล้ว',
          icon: Icons.directions_bike,
          status: TimelineStatus.completed,
        ),
      );
    }

    // Arrived at shop
    if (order.isArrivedAtShop) {
      steps.add(
        TimelineStep(
          title: 'ไรเดอร์ถึงร้านแล้ว',
          subtitle: 'ไรเดอร์มาถึงร้านแล้ว',
          icon: Icons.location_on,
          status: TimelineStatus.current,
          time: order.updatedAt,
        ),
      );
    } else if (order.isPickedUp ||
        order.isDelivering ||
        order.isArrivedAtCustomer ||
        order.isCompleted) {
      steps.add(
        TimelineStep(
          title: 'รับอาหารแล้ว',
          subtitle: 'ไรเดอร์รับอาหารจากร้านแล้ว',
          icon: Icons.location_on,
          status: TimelineStatus.completed,
        ),
      );
    }

    // Picked up
    if (order.isPickedUp) {
      steps.add(
        TimelineStep(
          title: 'รับอาหารแล้ว',
          subtitle: 'ไรเดอร์รับอาหารจากร้านแล้ว',
          icon: Icons.takeout_dining,
          status: TimelineStatus.current,
          time: order.updatedAt,
        ),
      );
    } else if (order.isDelivering ||
        order.isArrivedAtCustomer ||
        order.isCompleted) {
      steps.add(
        TimelineStep(
          title: 'กำลังจัดส่ง',
          subtitle: 'ไรเดอร์กำลังจัดส่งอาหาร',
          icon: Icons.takeout_dining,
          status: TimelineStatus.completed,
        ),
      );
    }

    // Delivering
    if (order.isDelivering) {
      steps.add(
        TimelineStep(
          title: 'กำลังจัดส่ง',
          subtitle: 'ไรเดอร์กำลังจัดส่งอาหาร',
          icon: Icons.local_shipping,
          status: TimelineStatus.current,
          time: order.updatedAt,
        ),
      );
    } else if (order.isArrivedAtCustomer || order.isCompleted) {
      steps.add(
        TimelineStep(
          title: 'จัดส่งเสร็จ',
          subtitle: 'จัดส่งอาหารเสร็จเรียบร้อย',
          icon: Icons.local_shipping,
          status: TimelineStatus.completed,
        ),
      );
    }

    // Arrived at customer
    if (order.isArrivedAtCustomer) {
      steps.add(
        TimelineStep(
          title: 'ไรเดอร์ถึงแล้ว',
          subtitle: 'ไรเดอร์มาถึงที่จัดส่งแล้ว',
          icon: Icons.home,
          status: TimelineStatus.current,
          time: order.updatedAt,
        ),
      );
    } else if (order.isCompleted) {
      steps.add(
        TimelineStep(
          title: 'ส่งมอบเสร็จ',
          subtitle: 'ส่งมอบอาหารเสร็จเรียบร้อย',
          icon: Icons.home,
          status: TimelineStatus.completed,
        ),
      );
    }

    // Completed
    if (order.isCompleted) {
      steps.add(
        TimelineStep(
          title: 'เสร็จสิ้น',
          subtitle: 'ออเดอร์เสร็จสมบูรณ์',
          icon: Icons.check_circle,
          status: TimelineStatus.completed,
          time: order.updatedAt,
        ),
      );
    }

    // Cancelled
    if (order.isCancelled) {
      steps.add(
        TimelineStep(
          title: 'ยกเลิกออเดอร์',
          subtitle: 'ออเดอร์ถูกยกเลิก',
          icon: Icons.cancel,
          status: TimelineStatus.cancelled,
          time: order.updatedAt,
        ),
      );
    }

    return steps;
  }

  Widget _buildTimelineItem({
    required TimelineStep step,
    required bool isLast,
    required BuildContext context,
  }) {
    Color getStatusColor() {
      switch (step.status) {
        case TimelineStatus.completed:
          return Colors.green;
        case TimelineStatus.current:
          return Theme.of(context).primaryColor;
        case TimelineStatus.pending:
          return Colors.grey;
        case TimelineStatus.cancelled:
          return Colors.red;
      }
    }

    Widget getStatusIcon() {
      switch (step.status) {
        case TimelineStatus.completed:
          return Icon(Icons.check_circle, color: Colors.green, size: 20);
        case TimelineStatus.current:
          return Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        case TimelineStatus.pending:
          return Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 2),
              shape: BoxShape.circle,
            ),
          );
        case TimelineStatus.cancelled:
          return Icon(Icons.cancel, color: Colors.red, size: 20);
      }
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: getStatusColor().withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(step.icon, color: getStatusColor(), size: 20),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: step.status == TimelineStatus.completed
                      ? Colors.green.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: step.status == TimelineStatus.pending
                                ? Colors.grey.shade600
                                : Colors.black87,
                          ),
                        ),
                      ),
                      getStatusIcon(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  if (step.time != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(step.time!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  // Current step animation
                  if (step.status == TimelineStatus.current) ...[
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else {
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

class TimelineStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final TimelineStatus status;
  final DateTime? time;

  TimelineStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
    this.time,
  });
}

enum TimelineStatus { pending, current, completed, cancelled }
