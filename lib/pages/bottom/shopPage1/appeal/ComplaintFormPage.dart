import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:delivery/APIs/api_config.dart'; // ✅ เพิ่ม import ด้านบนไฟล์

class ComplaintFormPage extends StatefulWidget {
  const ComplaintFormPage({Key? key}) : super(key: key);

  @override
  State<ComplaintFormPage> createState() => _ComplaintFormPageState();
}

class _ComplaintFormPageState extends State<ComplaintFormPage> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  File? _image;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submitComplaint() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUser = auth.currentUser;
    final marketData = auth.marketData;

    if (currentUser == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final int userId = currentUser['user_id'];

    // ✅ ตรวจ role จาก marketData / currentUser
    String role = 'member';
    if (marketData != null) {
      role = 'market'; // เป็นร้านค้า
    } else if (currentUser['is_rider'] == true ||
        currentUser['rider_profile'] != null) {
      role = 'rider';
    }

    // ✅ รับ argument จาก route
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final int? riderId = args?['riderId'];
    final int? marketId = args?['marketId'];

    // ✅ Debug log
    debugPrint("📤 Sending complaint:");
    debugPrint("user_id: $userId");
    debugPrint("role: $role");
    debugPrint("riderId: $riderId");
    debugPrint("marketId: $marketId");
    debugPrint("marketData: $marketData");

    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบ")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse("${ApiConfig.baseUrl}/complaints");
      final request = http.MultipartRequest('POST', uri);

      request.fields['user_id'] = userId.toString();
      request.fields['role'] = role;
      request.fields['subject'] = _subjectController.text.trim();
      request.fields['message'] = _messageController.text.trim();

      // ✅ แนบ market_id ถ้ามีใน marketData
      if (role == "market") {
        final marketIdFromData = marketData?['market_id'];
        if (marketIdFromData != null) {
          request.fields['market_id'] = marketIdFromData.toString();
        }
      }

      if (role == "rider" && riderId != null) {
        request.fields['rider_id'] = riderId.toString();
      }

      if (_image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('evidence', _image!.path),
        );
      }

      debugPrint("🧾 Form data: ${request.fields}");

      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final decoded = jsonDecode(resBody);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded["message"] ?? "ส่งคำร้องเรียนสำเร็จ")),
        );
        _subjectController.clear();
        _messageController.clear();
        setState(() => _image = null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Server Error: ${decoded["error"] ?? resBody}"),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error sending complaint: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ร้องเรียน/แจ้งปัญหา"),
        backgroundColor: const Color(0xFF34C759),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "หัวข้อคำร้องเรียน",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: "เช่น ไรเดอร์ส่งช้า / พูดไม่สุภาพ",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "รายละเอียดเพิ่มเติม",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "อธิบายเหตุการณ์ที่เกิดขึ้น...",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_image != null)
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: InteractiveViewer(
                        child: Image.file(_image!, fit: BoxFit.contain),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_image!, height: 200, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image, color: Color(0xFF34C759)),
              label: const Text(
                "แนบรูปหลักฐาน",
                style: TextStyle(color: Color(0xFF34C759)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitComplaint,
              icon: const Icon(Icons.send, color: Colors.white),
              label: Text(
                _isSubmitting ? "กำลังส่ง..." : "ส่งคำร้องเรียน",
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
