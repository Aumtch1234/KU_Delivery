import 'package:delivery/pages/my_Address/models.dart';
import 'package:flutter/material.dart';

class ShippingAddressPage extends StatefulWidget {
  @override
  _ShippingAddressPageState createState() => _ShippingAddressPageState();
}

class _ShippingAddressPageState extends State<ShippingAddressPage> {
  List<ShippingAddress> addresses = [
    ShippingAddress(
      id: '1',
      name: 'สมชาย ใจดี',
      phone: '081-234-5678',
      address: '123/45 ซอยรามคำแหง 24',
      district: 'หัวหมาก',
      province: 'กรุงเทพมหานคร',
      postalCode: '10240',
      isDefault: true,
    ),
    ShippingAddress(
      id: '2',
      name: 'สมหญิง รักเรียน',
      phone: '089-876-5432',
      address: '789 ถนนสุขุมวิท',
      district: 'วัฒนา',
      province: 'กรุงเทพมหานคร',
      postalCode: '10110',
      isDefault: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'ที่อยู่การจัดส่ง',
          style: TextStyle(
            fontWeight: FontWeight.w600,fontSize: 16,
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
          Icon(
            Icons.location_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
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
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showAddEditDialog(address: address, index: index);
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
                    if (!address.isDefault)
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
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
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
                Icon(
                  Icons.phone_outlined,
                  color: Colors.grey[600],
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  address.phone,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
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
            onPressed: () => Navigator.pushNamed(context, '/add-address').then((_) {
              setState(() {});
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

  void _showAddEditDialog({ShippingAddress? address, int? index}) {
    final nameController = TextEditingController(text: address?.name ?? '');
    final phoneController = TextEditingController(text: address?.phone ?? '');
    final addressController = TextEditingController(text: address?.address ?? '');
    final districtController = TextEditingController(text: address?.district ?? '');
    final provinceController = TextEditingController(text: address?.province ?? '');
    final postalCodeController = TextEditingController(text: address?.postalCode ?? '');
    bool isDefault = address?.isDefault ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  address == null ? 'เพิ่มที่อยู่ใหม่' : 'แก้ไขที่อยู่',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildTextField('ชื่อ-สกุล', nameController, Icons.person_outline),
                        SizedBox(height: 16),
                        _buildTextField('หมายเลขโทรศัพท์', phoneController, Icons.phone_outlined),
                        SizedBox(height: 16),
                        _buildTextField('ที่อยู่', addressController, Icons.home_outlined, maxLines: 2),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField('เขต/อำเภอ', districtController, Icons.location_city_outlined),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField('จังหวัด', provinceController, Icons.map_outlined),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildTextField('รหัสไปรษณีย์', postalCodeController, Icons.local_post_office_outlined),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Checkbox(
                              value: isDefault,
                              onChanged: (value) {
                                setDialogState(() {
                                  isDefault = value ?? false;
                                });
                              },
                            ),
                            Text('ตั้งเป็นที่อยู่เริ่มต้น'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('ยกเลิก'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_validateForm([
                            nameController,
                            phoneController,
                            addressController,
                            districtController,
                            provinceController,
                            postalCodeController,
                          ])) {
                            final newAddress = ShippingAddress(
                              id: address?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              name: nameController.text,
                              phone: phoneController.text,
                              address: addressController.text,
                              district: districtController.text,
                              province: provinceController.text,
                              postalCode: postalCodeController.text,
                              isDefault: isDefault,
                            );

                            setState(() {
                              if (isDefault) {
                                for (var addr in addresses) {
                                  addr.isDefault = false;
                                }
                              }

                              if (index != null) {
                                addresses[index] = newAddress;
                              } else {
                                addresses.add(newAddress);
                              }
                            });

                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          address == null ? 'เพิ่ม' : 'บันทึก',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34C759),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF34C759)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF34C759)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  bool _validateForm(List<TextEditingController> controllers) {
    for (var controller in controllers) {
      if (controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return true;
  }

  void _setAsDefault(int index) {
    setState(() {
      for (int i = 0; i < addresses.length; i++) {
        addresses[i].isDefault = i == index;
      }
    });
  }

  void _deleteAddress(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบที่อยู่นี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                addresses.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
