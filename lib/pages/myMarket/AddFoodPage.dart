import 'dart:io';
import 'package:delivery/APIs/Foods/CategorysAPI.dart';
import 'package:delivery/pages/LoadingOverlay/LoadingOverlay.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery/APIs/Markets/UploadFood.dart';

class AddFoodPage extends StatefulWidget {
  @override
  _AddFoodPageState createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final _formKey = GlobalKey<FormState>();
  final CategoryApiService _categoryApiService = CategoryApiService();
  
  String foodName = '';
  double price = 0;
  File? image;
  int? selectedCategoryId;
  String? selectedCategoryName;
  
  List<dynamic> categories = [];
  bool _isLoading = false;
  bool _isLoadingCategories = true;
  
  final List<Map<String, dynamic>> options = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await _categoryApiService.getAllCategorys();
      setState(() {
        categories = data;
        // ✅ ไม่ set ค่าเริ่มต้น ให้ user เลือกเอง
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() => _isLoadingCategories = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดหมวดหมู่')),
      );
    }
  }

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
    if (!_formKey.currentState!.validate() || image == null || selectedCategoryId == null) {
      if (selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกหมวดหมู่เมนู')),
        );
      }
      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกรูปภาพเมนู')),
        );
      }
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      await uploadFood(
        foodName: foodName,
        price: price,
        categoryId: selectedCategoryId!, // ✅ เพิ่มบรรทัดนี้
        image: image!,
        options: options,
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
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
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _isLoadingCategories
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ ชื่อเมนู
                      _buildSectionTitle("ชื่อเมนู"),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: _inputDecoration("เช่น ข้าวกะเพราไก่ไข่ดาว"),
                        onSaved: (val) => foodName = val!,
                        validator: (val) => val == null || val.isEmpty
                            ? 'กรุณากรอกชื่อเมนู'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // ✅ หมวดหมู่เมนู (พร้อมรูปภาพ)
                      _buildSectionTitle("หมวดหมู่เมนู"),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor,
                            width: 2,
                          ),
                        ),
                        child: DropdownButton<int>(
                          isExpanded: true,
                          underline: const SizedBox(),
                          value: selectedCategoryId,
                          items: categories.map<DropdownMenuItem<int>>((category) {
                            final catId = category['id'] ?? category['category_id'];
                            final catName = category['name'] ?? category['category_name'] ?? 'ไม่ระบุ';
                            final catImage = category['cate_image_url'] ?? '';
                            
                            return DropdownMenuItem<int>(
                              value: catId,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  children: [
                                    // ✅ รูปหมวดหมู่
                                    if (catImage.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          catImage,
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                            width: 36,
                                            height: 36,
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.image,
                                                size: 18),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.category,
                                            size: 18,
                                            color: Colors.white),
                                      ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        catName,
                                        style: const TextStyle(fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedCategoryId = value;
                                final category = categories.firstWhere(
                                  (cat) => (cat['id'] ?? cat['category_id']) == value,
                                  orElse: () => {},
                                );
                                selectedCategoryName = category['name'] ?? category['category_name'];
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ✅ ราคา
                      _buildSectionTitle("ราคา (บาท)"),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: _inputDecoration("เช่น 55"),
                        keyboardType: TextInputType.number,
                        onSaved: (val) => price = double.tryParse(val!) ?? 0,
                        validator: (val) => val == null || val.isEmpty
                            ? 'กรุณากรอกราคา'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // ✅ รูปภาพเมนู
                      _buildSectionTitle("รูปภาพเมนู"),
                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: image != null ? primaryColor : Colors.grey.shade300,
                                width: 2,
                              ),
                              image: image != null
                                  ? DecorationImage(
                                      image: FileImage(image!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: image == null
                                ? Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.photo_library,
                                          size: 48,
                                          color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text(
                                        "แตะเพื่อเลือกรูปเมนู",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ✅ ตัวเลือกเพิ่มเติม
                      _buildSectionTitle("ตัวเลือกเพิ่มเติม"),
                      const SizedBox(height: 8),
                      ...options.asMap().entries.map((entry) {
                        int i = entry.key;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  initialValue: entry.value['label'],
                                  decoration:
                                      _inputDecoration("เช่น เผ็ดมาก"),
                                  onChanged: (val) =>
                                      options[i]['label'] = val,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue:
                                      entry.value['extraPrice'].toString(),
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      _inputDecoration("เพิ่ม (฿)"),
                                  onChanged: (val) => options[i]
                                      ['extraPrice'] =
                                      double.tryParse(val) ?? 0.0,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
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
                          label: const Text("เพิ่มตัวเลือก",
                              style:
                                  TextStyle(color: Colors.black)),
                          onPressed: _addOption,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // ✅ ปุ่มบันทึก
                      Center(
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            "บันทึกเมนู",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFF34C759), width: 2),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}