// TestShopPage.dart - หน้าทดสอบสำหรับร้านค้า
import 'package:delivery/APIs/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TestShopPage extends StatefulWidget {
  const TestShopPage({Key? key}) : super(key: key);

  @override
  State<TestShopPage> createState() => _TestShopPageState();
}

class _TestShopPageState extends State<TestShopPage> {
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _shopIdController = TextEditingController(text: '1');
  
  bool _isLoading = false;
  String? _statusMessage;
  Map<String, dynamic>? _orderData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('ทดสอบระบบร้านค้า'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shop ID Card
            _buildShopIdCard(),
            
            const SizedBox(height: 20),
            
            // Order ID Input
            _buildOrderIdInput(),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            _buildActionButtons(),
            
            const SizedBox(height: 20),
            
            // Status Display
            if (_statusMessage != null) _buildStatusCard(),
            
            const SizedBox(height: 20),
            
            // Order Details
            if (_orderData != null) _buildOrderDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildShopIdCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.store,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'ร้านค้า',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            child: TextField(
              controller: _shopIdController,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'Shop ID',
                hintStyle: TextStyle(color: Colors.white70),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderIdInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'หมายเลขออเดอร์',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _orderIdController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'กรุณาใส่หมายเลขออเดอร์',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
              prefixIcon: const Icon(Icons.receipt_long, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Check Status Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _checkOrderStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.search),
            label: Text(
              _isLoading ? 'กำลังตรวจสอบ...' : 'ตรวจสอบสถานะ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Accept Order Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _acceptOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.check_circle),
            label: Text(
              _isLoading ? 'กำลังรับงาน...' : 'รับออเดอร์',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final isSuccess = _statusMessage!.contains('success') || _statusMessage!.contains('สำเร็จ');
    final isError = _statusMessage!.contains('error') || _statusMessage!.contains('ผิดพลาด');
    
    Color bgColor = Colors.blue[50]!;
    Color borderColor = Colors.blue[200]!;
    Color textColor = Colors.blue[800]!;
    IconData icon = Icons.info;
    
    if (isSuccess) {
      bgColor = Colors.green[50]!;
      borderColor = Colors.green[200]!;
      textColor = Colors.green[800]!;
      icon = Icons.check_circle;
    } else if (isError) {
      bgColor = Colors.red[50]!;
      borderColor = Colors.red[200]!;
      textColor = Colors.red[800]!;
      icon = Icons.error;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายละเอียดออเดอร์',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildDetailRow('Order ID', '${_orderData!['order_id']}'),
          _buildDetailRow('Status', _orderData!['status'] ?? 'N/A'),
          _buildDetailRow('Shop Accepted', _orderData!['hasShop'] ? 'Yes' : 'No'),
          _buildDetailRow('Rider Assigned', _orderData!['hasRider'] ? 'Yes' : 'No'),
          
          if (_orderData!['rider_id'] != null)
            _buildDetailRow('Rider ID', '${_orderData!['rider_id']}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkOrderStatus() async {
    if (_orderIdController.text.isEmpty) {
      setState(() {
        _statusMessage = 'กรุณาใส่หมายเลขออเดอร์';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _orderData = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/socket/order_status/${_orderIdController.text}'),
      );

      final data = json.decode(response.body);
      
      setState(() {
        _isLoading = false;
        if (data['success']) {
          _statusMessage = 'ตรวจสอบสถานะสำเร็จ';
          _orderData = data['data'];
        } else {
          _statusMessage = 'Error: ${data['error']}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }

  Future<void> _acceptOrder() async {
    if (_orderIdController.text.isEmpty) {
      setState(() {
        _statusMessage = 'กรุณาใส่หมายเลขออเดอร์';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/socket/accept_order'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': int.parse(_orderIdController.text),
          'shop_id': int.parse(_shopIdController.text),
        }),
      );

      final data = json.decode(response.body);
      
      setState(() {
        _isLoading = false;
        if (data['success']) {
          _statusMessage = 'รับออเดอร์สำเร็จ!';
          // Refresh order status
          _checkOrderStatus();
        } else {
          _statusMessage = 'Error: ${data['error']}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _shopIdController.dispose();
    super.dispose();
  }
}