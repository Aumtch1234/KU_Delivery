import 'dart:io';
import 'dart:convert';
import 'package:delivery/APIs/Markets/DeleteFoodAPI.dart';
import 'package:delivery/APIs/Foods/CategorysAPI.dart';
import 'package:delivery/pages/LoadingOverlay/LoadingOverlay.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery/APIs/Markets/UpdateFood.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class EditFoodPage extends StatefulWidget {
  const EditFoodPage({Key? key}) : super(key: key);

  @override
  _EditFoodPageState createState() => _EditFoodPageState();
}

class _EditFoodPageState extends State<EditFoodPage> {
  final _formKey = GlobalKey<FormState>();
  final CategoryApiService _categoryApiService = CategoryApiService();

  late TextEditingController _foodNameController;
  late TextEditingController _priceController;
  File? newImage;
  String? currentImageUrl;
  bool _isLoading = false;

  int? selectedCategoryId;
  String? selectedCategoryName;
  List<dynamic> categories = [];
  bool _isLoadingCategories = true;

  List<Map<String, dynamic>> optionsList = [];

  bool _isInit = false;

  final Color primaryColor = const Color(0xFF34C759);

  @override
  void initState() {
    super.initState();
    _foodNameController = TextEditingController();
    _priceController = TextEditingController();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await _categoryApiService.getAllCategorys();
      setState(() {
        categories = data;
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _foodNameController.text = args['food_name'] ?? '';
        _priceController.text = args['price'] != null
            ? double.tryParse(args['price'].toString())?.toString() ?? '0'
            : '0';
        currentImageUrl = args['image_url'];

        // ✅ ดึงหมวดหมู่ (Backend ต้องส่ง category_name มา)
        selectedCategoryId = args['category_id'];
        selectedCategoryName = args['category_name'] ?? 'ไม่ระบุหมวดหมู่';

        print('✅ category_id: $selectedCategoryId');
        print('✅ category_name: $selectedCategoryName');

        final rawOptions = args['options'];

        try {
          List<dynamic> decoded;

          if (rawOptions == null) {
            decoded = [];
          } else if (rawOptions is String) {
            decoded = jsonDecode(rawOptions);
          } else if (rawOptions is List) {
            decoded = rawOptions;
          } else {
            decoded = [];
          }

          optionsList = List<Map<String, dynamic>>.from(
            decoded.map(
              (opt) => {
                'name': opt['label'] ?? '',
                'price': (opt['extraPrice'] is String)
                    ? double.tryParse(opt['extraPrice']) ?? 0
                    : (opt['extraPrice'] ?? 0),
              },
            ),
          );
        } catch (e) {
          print('❌ Error decoding options: $e');
          optionsList = [];
        }
      }
      _isInit = true;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        newImage = File(picked.path);
      });
    }
  }

  void _addOption() {
    setState(() {
      optionsList.add({'name': '', 'price': 0.0});
    });
  }

  void _removeOption(int index) {
    setState(() {
      optionsList.removeAt(index);
    });
  }

  Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final foodName = _foodNameController.text;
      final price = double.tryParse(_priceController.text) ?? 0;

      final optionsForApi = optionsList.map((opt) {
        double optPrice = 0;
        if (opt['price'] != null) {
          if (opt['price'] is double) {
            optPrice = opt['price'];
          } else if (opt['price'] is int) {
            optPrice = (opt['price'] as int).toDouble();
          } else if (opt['price'] is String) {
            optPrice = double.tryParse(opt['price']) ?? 0;
          }
        }
        return {'label': opt['name'] ?? '', 'extraPrice': optPrice};
      }).toList();

      final optionsJson = jsonEncode(optionsForApi);

      await updateFood(
        foodId: (ModalRoute.of(context)?.settings.arguments as Map)['food_id'],
        foodName: foodName,
        price: price,
        imageFile: newImage,
        options: optionsJson,
        categoryId: selectedCategoryId ?? 0, // ✅ ส่งหมวดหมู่ที่เลือกไปด้วย
      );

      setState(() {
        _isLoading = false;
      });

      Navigator.pop(context, true);
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF34C759), width: 2),
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

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('แก้ไขเมนู'),
          backgroundColor: primaryColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'ลบตัวเมนูนี้',
              onPressed: () {
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.warning,
                  animType: AnimType.scale,
                  title: 'ยืนยันการลบ',
                  desc: 'คุณต้องการลบเมนูนี้จริงหรือไม่?',
                  btnCancelOnPress: () {},
                  btnOkOnPress: () async {
                    final foodId =
                        (ModalRoute.of(context)?.settings.arguments
                            as Map)['food_id'];
                    final success = await deleteFood(foodId);
                    if (success) {
                      Navigator.pop(context, true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ลบเมนูไม่สำเร็จ')),
                      );
                    }
                  },
                ).show();
              },
            ),
          ],
        ),
        body: _isLoadingCategories
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ ชื่อเมนู
                      _buildSectionTitle('ชื่อเมนู'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _foodNameController,
                        decoration: _inputDecoration('เช่น ข้าวกะเพราไก่ไข่ดาว'),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'กรอกชื่อเมนู' : null,
                      ),
                      const SizedBox(height: 16),

                      // ✅ หมวดหมู่เมนู (เปลี่ยนเป็น Dropdown แบบเดียวกับ AddFoodPage)
                      _buildSectionTitle('หมวดหมู่เมนู'),
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
                      const SizedBox(height: 16),

                      // ✅ ราคา
                      _buildSectionTitle('ราคา (บาท)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('เช่น 55'),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'กรอกราคา' : null,
                      ),
                      const SizedBox(height: 24),

                      // ✅ รูปภาพเมนู
                      _buildSectionTitle('รูปภาพเมนู'),
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
                                color: newImage != null
                                    ? primaryColor
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              image: newImage != null
                                  ? DecorationImage(
                                      image: FileImage(newImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : currentImageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(currentImageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                            ),
                            child: (newImage == null && currentImageUrl == null)
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

                      // ✅ ตัวเลือกเมนู
                      _buildSectionTitle('ตัวเลือกเมนู (Options)'),
                      const SizedBox(height: 8),
                      ...optionsList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  initialValue: option['name'],
                                  decoration: _inputDecoration(
                                    'เช่น เผ็ดมาก',
                                  ),
                                  onChanged: (val) =>
                                      optionsList[index]['name'] = val,
                                  validator: (val) =>
                                      val == null || val.isEmpty
                                          ? 'กรอกชื่อ'
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: option['price'].toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('เพิ่ม (฿)'),
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val);
                                    optionsList[index]['price'] =
                                        parsed ?? 0.0;
                                  },
                                  validator: (val) =>
                                      val == null || val.isEmpty
                                          ? 'กรอกราคา'
                                          : null,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => _removeOption(index),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addOption,
                          icon: const Icon(Icons.add, color: Colors.black),
                          label: const Text(
                            'เพิ่มตัวเลือก',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // ✅ ปุ่มบันทึก
                      Center(
                        child: ElevatedButton(
                          onPressed: _submitUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'บันทึกการเปลี่ยนแปลง',
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
}