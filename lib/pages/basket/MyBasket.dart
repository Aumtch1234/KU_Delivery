import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/basket_provider.dart';

class MyBasketPage extends StatefulWidget {
  static const routeName = '/basket';
  const MyBasketPage({super.key});

  @override
  State<MyBasketPage> createState() => _MyBasketPageState();
}

class _MyBasketPageState extends State<MyBasketPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final basket = Provider.of<BasketProvider>(context, listen: false);
      await basket.loadCartFromAPI();
      setState(() {
        _isLoading = false;
      });
    });
  }

  // Helper method สำหรับ responsive breakpoints
  double _getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  bool _isSmallScreen(BuildContext context) {
    return _getScreenWidth(context) < 600;
  }

  // ฟังก์ชันสำหรับ responsive font size
  double _responsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = _getScreenWidth(context);
    if (screenWidth < 360) return baseSize * 0.9;
    if (screenWidth > 600) return baseSize * 1.1;
    return baseSize;
  }

  // ฟังก์ชันสำหรับ responsive padding
  EdgeInsets _responsivePadding(BuildContext context) {
    final screenWidth = _getScreenWidth(context);
    if (screenWidth < 360) return const EdgeInsets.all(12);
    if (screenWidth > 600) return const EdgeInsets.all(24);
    return const EdgeInsets.all(16);
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = _isSmallScreen(context);

    return Consumer<BasketProvider>(
      builder: (context, basket, _) {
        final items = basket.items;
        final isEdit = basket.isEditMode;

        if (_isLoading) {
          return Scaffold(
            backgroundColor: const Color(0xFF34C759),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังโหลดตะกร้า...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _responsiveFontSize(context, 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF34C759),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(isSmallScreen ? 56 : 64),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: isSmallScreen ? 20 : 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'ตะกร้าของฉัน (${items.length})',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _responsiveFontSize(context, 18),
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: isSmallScreen ? 8 : 16),
                  child: TextButton(
                    onPressed: () => basket.toggleEditMode(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 6 : 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      isEdit ? 'เสร็จสิ้น' : 'แก้ไข',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _responsiveFontSize(context, 14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: items.isEmpty
                      ? _buildEmptyState(context)
                      : _buildBasketItemsByStore(context, basket, isEdit),
                ),
              ),
              _buildBottomBar(context, basket, isEdit),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Center(
      child: Padding(
        padding: _responsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(_isSmallScreen(context) ? 20 : 32),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: _isSmallScreen(context) ? 64 : 80,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'ยังไม่มีสินค้าในตะกร้า',
              style: TextStyle(
                fontSize: _responsiveFontSize(context, 20),
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              'เริ่มเลือกซื้อสินค้าได้เลย!',
              style: TextStyle(
                fontSize: _responsiveFontSize(context, 14),
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 แสดงสินค้าโดยจำแนกตามร้าน
  Widget _buildBasketItemsByStore(BuildContext context, BasketProvider basket, bool isEdit) {
    final responsivePadding = _responsivePadding(context);
    final itemsByStore = basket.itemsByStore;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: responsivePadding,
        child: Column(
          children: [
            const SizedBox(height: 16),
            ...itemsByStore.entries.map((entry) {
              final storeName = entry.key;
              final storeItems = entry.value;
              return _buildStoreGroup(context, basket, storeName, storeItems, isEdit);
            }).toList(),
            const SizedBox(height: 100), // พื้นที่สำหรับ bottom bar
          ],
        ),
      ),
    );
  }

  // 🆕 สร้างกลุ่มสินค้าของแต่ละร้าน
  Widget _buildStoreGroup(BuildContext context, BasketProvider basket, String storeName, List storeItems, bool isEdit) {
    final isSmallScreen = _isSmallScreen(context);
    final isFullySelected = basket.isStoreFullySelected(storeName);
    final isPartiallySelected = basket.isStorePartiallySelected(storeName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 🆕 Header ร้าน
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: const BoxDecoration(
              color: Color(0xFF34C759),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Transform.scale(
                  scale: isSmallScreen ? 0.9 : 1.0,
                  child: Checkbox(
                    value: isFullySelected,
                    tristate: true,
                    activeColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (value) {
                      basket.toggleStoreSelected(storeName, value ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.store,
                  size: isSmallScreen ? 18 : 20,
                  color: const Color(0xFFF8F9FA),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    storeName,
                    style: TextStyle(
                      fontSize: _responsiveFontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (isPartiallySelected && !isFullySelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'เลือกบางส่วน',
                      style: TextStyle(
                        fontSize: _responsiveFontSize(context, 11),
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // รายการสินค้าของร้าน
          ...storeItems.asMap().entries.map((entry) {
            final itemIndex = basket.items.indexOf(entry.value);
            return _buildBasketItem(context, basket, entry.value, itemIndex, isEdit);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBasketItem(BuildContext context, BasketProvider basket, dynamic item, int index, bool isEdit) {
    final isSmallScreen = _isSmallScreen(context);
    final imageSize = isSmallScreen ? 70.0 : 90.0;

    return Container(
      decoration: BoxDecoration(
        color: item.selected ? const Color(0xFF34C759).withOpacity(0.05) : Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // สามารถเพิ่ม onTap เพื่อดูรายละเอียดสินค้า
          },
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox และรูปภาพ
                Column(
                  children: [
                    Transform.scale(
                      scale: isSmallScreen ? 0.9 : 1.0,
                      child: Checkbox(
                        value: item.selected,
                        activeColor: const Color(0xFF34C759),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (v) => basket.toggleItemSelected(index, v ?? false),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: imageSize,
                      height: imageSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.imagePath.startsWith('http')
                            ? Image.network(
                                item.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image_not_supported),
                                  );
                                },
                              )
                            : Image.asset(
                                item.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image_not_supported),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(width: isSmallScreen ? 12 : 16),
                
                // ข้อมูลสินค้า
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ชื่อสินค้า
                      Text(
                        item.foodName,
                        style: TextStyle(
                          fontSize: _responsiveFontSize(context, 16),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // ตัวเลือก
                      if (item.optionsText.isNotEmpty) ...[
                        Text(
                          item.optionsText,
                          style: TextStyle(
                            fontSize: _responsiveFontSize(context, 13),
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                      ],
                      
                      // หมายเหตุ
                      if (item.note.isNotEmpty) ...[
                        Text(
                          "หมายเหตุ: ${item.note}",
                          style: TextStyle(
                            fontSize: _responsiveFontSize(context, 12),
                            color: Colors.orange[700],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                      ],
                      
                      // ราคา
                      Text(
                        '${item.sell_price.toStringAsFixed(0)} บาท',
                        style: TextStyle(
                          fontSize: _responsiveFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF34C759),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // ปุ่มจำนวน
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildQuantityButton(
                            Icons.remove,
                            () => basket.updateQuantity(index, item.quantity - 1),
                            item.quantity > 1 && !isEdit,
                            isSmallScreen,
                          ),
                          Container(
                            width: isSmallScreen ? 32 : 40,
                            alignment: Alignment.center,
                            child: Text(
                              '${item.quantity}',
                              style: TextStyle(
                                fontSize: _responsiveFontSize(context, 16),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          _buildQuantityButton(
                            Icons.add,
                            () => basket.updateQuantity(index, item.quantity + 1),
                            !isEdit,
                            isSmallScreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback? onPressed, bool enabled, bool isSmallScreen) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onPressed : null,
        child: Container(
          width: isSmallScreen ? 28 : 32,
          height: isSmallScreen ? 28 : 32,
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFF34C759) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: isSmallScreen ? 16 : 20,
            color: enabled ? Colors.white : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, BasketProvider basket, bool isEdit) {
    final isSmallScreen = _isSmallScreen(context);
    final screenWidth = _getScreenWidth(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 24,
            vertical: isSmallScreen ? 12 : 16,
          ),
          child: Row(
            children: [
              // Checkbox ทั้งหมด
              Transform.scale(
                scale: isSmallScreen ? 0.9 : 1.0,
                child: Checkbox(
                  value: basket.allSelected,
                  activeColor: const Color(0xFF34C759),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (v) => basket.toggleSelectAll(v ?? false),
                ),
              ),
              
              Text(
                'ทั้งหมด',
                style: TextStyle(
                  fontSize: _responsiveFontSize(context, 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              SizedBox(width: isSmallScreen ? 8 : 16),
              
              // ราคารวม
              Expanded(
                flex: screenWidth < 360 ? 2 : 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'รวม',
                      style: TextStyle(
                        fontSize: _responsiveFontSize(context, 12),
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${basket.totalSelectedPrice.toStringAsFixed(0)} บาท',
                      style: TextStyle(
                        fontSize: _responsiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF34C759),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(width: isSmallScreen ? 8 : 16),
              
              // ปุ่มหลัก
              Expanded(
                flex: screenWidth < 360 ? 3 : 4,
                child: !isEdit
                    ? ElevatedButton(
                        onPressed: basket.selectedCount > 0
                            ? () => Navigator.pushNamed(context, '/order-now')
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34C759),
                          disabledBackgroundColor: Colors.grey[300],
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'ชำระเงิน (${basket.selectedCount})',
                          style: TextStyle(
                            fontSize: _responsiveFontSize(context, 14),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: basket.selectedCount > 0
                            ? () async => await basket.removeSelected()
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(
                            color: basket.selectedCount > 0 ? Colors.red : Colors.grey[300]!,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'ลบที่เลือก',
                          style: TextStyle(
                            fontSize: _responsiveFontSize(context, 14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}