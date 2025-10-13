import 'package:delivery/APIs/Carts/Carts.dart';
import 'package:delivery/APIs/Foods/OrderFoodAPI.dart';
import 'package:delivery/APIs/Reviews/ReviewAPI.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../basket/providers/basket_provider.dart';
import '../store/models/food_detail_model.dart';
import 'dart:async';

class OrderFoodPage extends StatefulWidget {
  final int foodId;

  const OrderFoodPage({Key? key, required this.foodId}) : super(key: key);

  @override
  State<OrderFoodPage> createState() => _OrderFoodPageState();
}

class _OrderFoodPageState extends State<OrderFoodPage> {
  FoodDetail? foodDetail;
  bool isLoading = true;
  int quantity = 1;
  List<bool> selectedOptions = [];
  final TextEditingController noteController = TextEditingController();

  // Review data
  Map<String, dynamic>? reviewData;
  bool isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadFood();
    _loadReviews();
  }

  Future<void> _loadFood() async {
    final controller = FoodOrderController();
    final data = await controller.getFoodDetail(widget.foodId);
    setState(() {
      foodDetail = data;
      selectedOptions = List.generate(
        data?.options.length ?? 0,
        (index) => false,
      );
      isLoading = false;
    });
  }

  Future<void> _loadReviews() async {
    try {
      final data = await ReviewApi.getAllReviewFoods(widget.foodId);
      print('✅ Review Data Loaded: $data');
      print('✅ Items count: ${data['items']?.length}');
      setState(() {
        reviewData = data;
        isLoadingReviews = false;
      });
    } catch (e) {
      print('❌ Error loading reviews: $e');
      setState(() {
        isLoadingReviews = false;
      });
    }
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.85), // 🔥 พื้นหลังโปร่งดำสวยขึ้น
      pageBuilder: (_, __, ___) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // ✅ รูปภาพพร้อม pinch-zoom
                Center(
                  child: Hero(
                    tag: 'food_${widget.foodId}',
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 5.0,
                      boundaryMargin: const EdgeInsets.all(50),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),

                // ✅ ปุ่มปิดลอยอยู่ด้านบนขวา (ใหญ่และชัด)
                Positioned(
                  top: 50,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                // ✅ คำแนะนำด้านล่าง (Optional)
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.zoom_in,
                        color: Colors.white.withOpacity(0.8),
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'บีบนิ้วเพื่อซูม / ปัดเพื่อเลื่อน',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
  }

  void _showAllReviews(BuildContext context) {
    if (reviewData == null ||
        reviewData!['items'] == null ||
        (reviewData!['items'] as List).isEmpty)
      return;

    final items = reviewData!['items'] as List;
    final foodSummary = reviewData!['food_summary'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'รีวิวทั้งหมด (${foodSummary['reviews_count']})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Rating Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          foodSummary['rating_avg'] ?? '0.0',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${foodSummary['reviews_count']} รีวิว',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRatingBars(foodSummary),
                    const Divider(height: 24),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final review = items[index];
                    return _buildReviewItem(review);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBars(Map<String, dynamic> summary) {
    final totalRatings = int.parse(summary['reviews_count'] ?? '0');
    final maxCount = totalRatings > 0 ? totalRatings : 1;

    return Column(
      children: [
        _buildStarRow(5, int.parse(summary['rating_5'] ?? '0'), maxCount),
        _buildStarRow(4, int.parse(summary['rating_4'] ?? '0'), maxCount),
        _buildStarRow(3, int.parse(summary['rating_3'] ?? '0'), maxCount),
        _buildStarRow(2, int.parse(summary['rating_2'] ?? '0'), maxCount),
        _buildStarRow(1, int.parse(summary['rating_1'] ?? '0'), maxCount),
      ],
    );
  }

  Widget _buildStarRow(int stars, int count, int maxCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(
                  stars,
                  (index) =>
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Text(count.toString(), style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: maxCount > 0 ? count / maxCount : 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    review['reviewer_photo'] != null &&
                        review['reviewer_photo'].toString().isNotEmpty
                    ? NetworkImage(review['reviewer_photo'])
                    : null,
                backgroundColor: Colors.grey[300],
                child:
                    review['reviewer_photo'] == null ||
                        review['reviewer_photo'].toString().isEmpty
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['reviewer_name'] ?? 'ผู้ใช้งาน',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatDate(review['created_at']),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < (review['rating'] ?? 0) ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(review['comment'] ?? '', style: const TextStyle(fontSize: 14)),
          const Divider(height: 24),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 30) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (diff.inDays > 0) {
        return '${diff.inDays} วันที่แล้ว';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} ชั่วโมงที่แล้ว';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} นาทีที่แล้ว';
      } else {
        return 'เมื่อสักครู่';
      }
    } catch (e) {
      return '';
    }
  }

  double get totalPrice {
    if (foodDetail == null) return 0.0;
    double optionPrice = 0.0;

    for (int i = 0; i < selectedOptions.length; i++) {
      if (selectedOptions[i]) {
        optionPrice += foodDetail!.options[i].extraPrice;
      }
    }

    return (foodDetail!.sell_price + optionPrice) * quantity;
  }

  String get selectedOptionsText {
    List<String> selected = [];
    for (int i = 0; i < selectedOptions.length; i++) {
      if (selectedOptions[i]) {
        selected.add(foodDetail!.options[i].label);
      }
    }
    return selected.isEmpty ? '-' : selected.join(', ');
  }
  Future<void> _addToBasket(BuildContext context) async {
    if (foodDetail == null) return;

    final selectedOpts = <Map<String, dynamic>>[];
    for (int i = 0; i < selectedOptions.length; i++) {
      if (selectedOptions[i]) {
        selectedOpts.add({
          "label": foodDetail!.options[i].label,
          "extraPrice": foodDetail!.options[i].extraPrice,
        });
      }
    }

    // ✅ ตรวจสอบว่ามีเมนูซ้ำในตะกร้าหรือไม่
    final basket = Provider.of<BasketProvider>(context, listen: false);
    final hasDuplicate = basket.items.any((item) {
      if (item.foodId != widget.foodId) return false;
      
      // ตรวจสอบตัวเลือกว่าตรงกันหรือไม่
      if (item.selectedOptions.length != selectedOpts.length) return false;
      
      for (var opt in selectedOpts) {
        bool found = item.selectedOptions.any((itemOpt) => 
          itemOpt['label'] == opt['label']
        );
        if (!found) return false;
      }
      
      // ตรวจสอบ note ว่าตรงกันหรือไม่
      return (item.note ?? '') == noteController.text;
    });

    // ✅ ถ้าพบเมนูซ้ำ แสดง Dialog ให้เลือก
    if (hasDuplicate) {
      final shouldAdd = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'พบเมนูซ้ำในตะกร้า',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'คุณมี "${foodDetail!.foodName}" ที่มีตัวเลือกและหมายเหตุเหมือนกันในตะกร้าอยู่แล้ว\n\nต้องการเพิ่ม $quantity ชิ้นเป็นรายการใหม่หรือไม่?',
                style: TextStyle(color: Colors.grey[700], height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'ตัวเลือก: ${selectedOptionsText}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    if (noteController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.note, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'หมายเหตุ: ${noteController.text}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                backgroundColor: Colors.green[50],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'เพิ่มเป็นรายการใหม่',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (shouldAdd != true) return; // ถ้ายกเลิก ไม่ต้องเพิ่ม
    }

    final success = await CartAPI.addToCart(
      foodId: widget.foodId,
      quantity: quantity,
      selectedOptions: selectedOpts,
      note: noteController.text,
    );

    if (success) {
      // ✅ โหลดข้อมูลตะกร้าใหม่ทันทีหลังเพิ่มสำเร็จ
      if (mounted) {
        await basket.loadCartFromAPI();

        print('🛒 Cart updated! Total items: ${basket.cartCount}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เพิ่ม ${foodDetail!.foodName} x$quantity ลงตะกร้าแล้ว',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // ✅ รีเซ็ตจำนวนและตัวเลือกหลังเพิ่มสำเร็จ
        setState(() {
          quantity = 1;
          selectedOptions = List.generate(
            foodDetail!.options.length,
            (index) => false,
          );
          noteController.clear();
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เพิ่มตะกร้าไม่สำเร็จ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFF34C759),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: foodDetail != null
            ? Text(
                foodDetail!.foodName,
                style: const TextStyle(color: Colors.black),
              )
            : const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/basket');
              },
              child: Consumer<BasketProvider>(
                builder: (context, basket, _) {
                  int count = basket.items.fold(
                    0,
                    (sum, e) => sum + e.quantity,
                  );
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.shopping_cart, color: Colors.black),
                      ),
                      if (count > 0)
                        Positioned(
                          right: -7,
                          top: -10,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            child: Center(
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : foodDetail == null
          ? const Center(child: Text('ไม่พบข้อมูลอาหาร'))
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 48 : 24,
                    vertical: isTablet ? 32 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food Image - สามารถกดดูได้
                      GestureDetector(
                        onTap: () =>
                            _showFullImage(context, foodDetail!.imageUrl),
                        child: Hero(
                          tag: 'food_${widget.foodId}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                Image.network(
                                  foodDetail!.imageUrl,
                                  width: double.infinity,
                                  height: isTablet ? 320 : size.width * 0.5,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.zoom_in,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'แตะเพื่อดูภาพ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quantity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              foodDetail!.foodName,
                              style: TextStyle(
                                fontSize: isTablet ? 24 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.green,
                                ),
                                onPressed: quantity > 1
                                    ? () => setState(() => quantity--)
                                    : null,
                              ),
                              Text(
                                '$quantity',
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.green,
                                ),
                                onPressed: () => setState(() => quantity++),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(thickness: 1, color: Colors.grey),

                      // ส่วนตัวเลือกเพิ่มเติม
                      if (foodDetail!.options.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.restaurant_menu,
                                    color: Colors.green[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ตัวเลือกเพิ่มเติม',
                                    style: TextStyle(
                                      fontSize: isTablet ? 18 : 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'เลือกได้หลายรายการ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...List.generate(foodDetail!.options.length, (i) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedOptions[i] = !selectedOptions[i];
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selectedOptions[i]
                                          ? Colors.green[50]
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: selectedOptions[i]
                                            ? Colors.green
                                            : Colors.grey[200]!,
                                        width: selectedOptions[i] ? 2 : 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: selectedOptions[i]
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.grey.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: selectedOptions[i]
                                                ? Colors.green
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: selectedOptions[i]
                                                  ? Colors.green
                                                  : Colors.grey[400]!,
                                              width: 2,
                                            ),
                                          ),
                                          child: selectedOptions[i]
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 14,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            foodDetail!.options[i].label,
                                            style: TextStyle(
                                              fontWeight: selectedOptions[i]
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              fontSize: 15,
                                              color: selectedOptions[i]
                                                  ? Colors.green[700]
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: selectedOptions[i]
                                                ? Colors.green
                                                : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          child: Text(
                                            '+${foodDetail!.options[i].extraPrice.toStringAsFixed(0)} ฿',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: selectedOptions[i]
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(thickness: 1, color: Colors.grey),
                      ],

                      // Total Price
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ราคารวมทั้งหมด',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            Text(
                              '${totalPrice.toStringAsFixed(0)} ฿',
                              style: TextStyle(
                                fontSize: isTablet ? 22 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Note
                      Text(
                        'รายละเอียดเพิ่มเติม',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'เช่น ไม่เอาผัก, เอาน้ำแข็งเยอะๆ',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.green,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 34),

                      Text('รีวิวทั้งหมด'),
                      // ส่วนรีวิว - แสดง 5 รีวิวแรก (ลบเงื่อนไข ok)
                      if (!isLoadingReviews && reviewData != null) ...[
                        if (reviewData!['items'] != null &&
                            (reviewData!['items'] as List).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      reviewData!['food_summary']['rating_avg'] ??
                                          '0.0',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${reviewData!['food_summary']['reviews_count']} รีวิว)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                const Text(
                                  'รีวิวล่าสุด',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...List.generate(
                                  (reviewData!['items'] as List).length > 5
                                      ? 5
                                      : (reviewData!['items'] as List).length,
                                  (index) => _buildReviewItem(
                                    reviewData!['items'][index],
                                  ),
                                ),
                                if ((reviewData!['items'] as List).length >
                                    5) ...[
                                  Center(
                                    child: TextButton.icon(
                                      onPressed: () => _showAllReviews(context),
                                      icon: const Icon(Icons.comment, size: 20),
                                      label: Text(
                                        'ดูรีวิวทั้งหมด (${reviewData!['food_summary']['reviews_count']})',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(thickness: 1, color: Colors.grey),
                        ] else ...[
                          // แสดงเมื่อไม่มีรีวิว
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.rate_review_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'ยังไม่มีรีวิว',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'เป็นคนแรกที่รีวิวเมนูนี้',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(thickness: 1, color: Colors.grey),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: (!isLoading && foodDetail != null)
                ? () => _addToBasket(context)
                : null,
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            label: Text(
              'ใส่ตะกร้า • ${totalPrice.toStringAsFixed(0)} ฿',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: (!isLoading && foodDetail != null)
                  ? Colors.green
                  : Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4, // ✅ เพิ่มเงาให้ปุ่ม
            ),
          ),
        ),
      ),
    );
  }
}
