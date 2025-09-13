import 'package:delivery/APIs/Users/AddAddressAPI.dart';
import 'package:delivery/pages/my_Address/AddAddressPage.dart';
import 'package:delivery/pages/my_Address/models.dart';
import 'package:flutter/material.dart';

class ShippingAddressPage extends StatefulWidget {
  @override
  _ShippingAddressPageState createState() => _ShippingAddressPageState();
}

class _ShippingAddressPageState extends State<ShippingAddressPage> {
  List<ShippingAddress> addresses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    final res = await DeliveryAddressAPI.GetAddress(); // เรียก API
    if (res['success']) {
      setState(() {
        addresses = (res['addresses'] as List)
            .map((a) => ShippingAddress.fromJson(a))
            .toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print("❌ โหลดที่อยู่ล้มเหลว: ${res['message']}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'ที่อยู่การจัดส่ง',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF34C759),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: addresses.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      return _buildAddressCard(addresses[index], index);
                    },
                  ),
          ),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'ยังไม่มีที่อยู่การจัดส่ง',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'เพิ่มที่อยู่เพื่อความสะดวกในการสั่งซื้อ',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(ShippingAddress address, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: address.isDefault
            ? Border.all(color: Colors.green[400]!, width: 2)
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: const Color(0xFF34C759),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        address.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      if (address.isDefault) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ค่าเริ่มต้น',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF34C759),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DeliveryAddressForm(address: addresses[index]),
                          ),
                        );
                        _fetchAddresses(); // โหลดใหม่หลังแก้ไข
                        break;
                      case 'default':
                        _setAsDefault(index);
                        break;
                      case 'delete':
                        _deleteAddress(index);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('แก้ไข'),
                        ],
                      ),
                    ),
                    if (!addresses[index].isDefault)
                      PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(Icons.star_outline, size: 20),
                            SizedBox(width: 8),
                            Text('ตั้งเป็นค่าเริ่มต้น'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text('ลบ', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone_outlined, color: Colors.grey[600], size: 16),
                SizedBox(width: 8),
                Text(
                  address.phone,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Colors.grey[600],
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${address.address}\n${address.district} ${address.province} ${address.postalCode}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, '/add-address').then((_) {
                  _fetchAddresses(); // เรียกใหม่หลังกลับมา
                }),
            icon: Icon(Icons.add, color: Colors.white),
            label: Text(
              'เพิ่มที่อยู่ใหม่',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34C759),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  void _setAsDefault(int index) {
    setState(() {
      for (int i = 0; i < addresses.length; i++) {
        addresses[i].isDefault = i == index;
      }
    });
  }

  void _deleteAddress(int addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("ยืนยันการลบ"),
        content: Text("คุณต้องการลบที่อยู่นี้ใช่หรือไม่?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("ลบ"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await DeliveryAddressAPI.deleteAddress(addressId);

    if (result["success"] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("ลบที่อยู่เรียบร้อย")));
      // รีเฟรช list
      setState(() {
        addresses.removeWhere((a) => a.id == addressId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ลบไม่สำเร็จ: ${result['message']}")),
      );
    }
  }
}
