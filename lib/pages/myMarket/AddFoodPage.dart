import 'dart:io';
import 'package:delivery/LoadingOverlay/LoadingOverlay.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery/APIs/UploadFood.dart';

class AddFoodPage extends StatefulWidget {
  @override
  _AddFoodPageState createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final _formKey = GlobalKey<FormState>();
  String foodName = '';
  double price = 0;
  File? image;
  final List<Map<String, dynamic>> options = [];
  bool _isLoading = false;  // ตัวแปรสถานะโหลด

  void _addOption() {
    options.add({'label': '', 'extraPrice': 0.0});
    setState(() {});
  }

  void _removeOption(int index) {
    options.removeAt(index);
    setState(() {});
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        image = File(picked.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || image == null) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true; // เริ่มแสดงโหลด
    });

    try {
      await uploadFood(
        foodName: foodName,
        price: price,
        image: image!,
        options: options,
      );

      Navigator.pop(context, true); // แจ้งว่าบันทึกสำเร็จ
    } catch (e) {
      // แจ้ง error แบบง่าย ๆ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกเมนู')),
      );
    } finally {
      setState(() {
        _isLoading = false; // ปิดโหลด
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF34C759);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("เพิ่มเมนู"),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("ชื่อเมนู"),
                SizedBox(height: 8,),
                TextFormField(
                  decoration: _inputDecoration("เช่น ข้าวกะเพราไก่ไข่ดาว"),
                  onSaved: (val) => foodName = val!,
                  validator: (val) => val == null || val.isEmpty ? 'กรุณากรอกชื่อเมนู' : null,
                ),
                const SizedBox(height: 16),
                _buildSectionTitle("ราคา (บาท)"),
                SizedBox(height: 8,),
                TextFormField(
                  decoration: _inputDecoration("เช่น 55"),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => price = double.tryParse(val!) ?? 0,
                  validator: (val) => val == null || val.isEmpty ? 'กรุณากรอกราคา' : null,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle("รูปภาพเมนู"),
                const SizedBox(height: 8),
                Center(
                  child: image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(image!, height: 180),
                        )
                      : const Text("ยังไม่ได้เลือกรูปภาพ"),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("เลือกรูปเมนู"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildSectionTitle("ตัวเลือกเพิ่มเติม"),
                SizedBox(height: 8,),
                ...options.asMap().entries.map((entry) {
                  int i = entry.key;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: entry.value['label'],
                            decoration: _inputDecoration("เช่น เผ็ดมาก, ไม่เผ็ด"),
                            onChanged: (val) => options[i]['label'] = val,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: entry.value['extraPrice'].toString(),
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration("เพิ่ม (฿)"),
                            onChanged: (val) =>
                                options[i]['extraPrice'] = double.tryParse(val) ?? 0.0,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeOption(i),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, color: Colors.black),
                    label: const Text("เพิ่มตัวเลือก", style: TextStyle(color: Colors.black)),
                    onPressed: _addOption,
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "บันทึกเมนู",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
