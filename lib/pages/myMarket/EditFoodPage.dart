import 'dart:io';
import 'dart:convert';
import 'package:delivery/LoadingOverlay/LoadingOverlay.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery/APIs/UpdateFood.dart';

class EditFoodPage extends StatefulWidget {
  const EditFoodPage({Key? key}) : super(key: key);

  @override
  _EditFoodPageState createState() => _EditFoodPageState();
}

class _EditFoodPageState extends State<EditFoodPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _foodNameController;
  late TextEditingController _priceController;
  File? newImage;
  String? currentImageUrl;
  bool _isLoading = false; // แสดงโหลด

  List<Map<String, dynamic>> optionsList = [];

  bool _isInit = false;

  final Color primaryColor = const Color(0xFF34C759);

  @override
  void initState() {
    super.initState();
    _foodNameController = TextEditingController();
    _priceController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _foodNameController.text = args['name'] ?? '';
        _priceController.text = args['price'] != null
            ? double.tryParse(args['price'].toString())?.toString() ?? '0'
            : '0';
        currentImageUrl = args['imagePath'];

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
        _isLoading = true; // แสดงโหลด
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
        foodId: (ModalRoute.of(context)?.settings.arguments as Map)['id'],
        foodName: foodName,
        price: price,
        imageFile: newImage,
        options: optionsJson,
      );

      setState(() {
        _isLoading = false; // ซ่อนโหลด
      });

      Navigator.pop(context);
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('ชื่อเมนู'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _foodNameController,
                  decoration: _inputDecoration('เช่น ข้าวกะเพราไก่ไข่ดาว'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'กรอกชื่อเมนู' : null,
                ),
                const SizedBox(height: 16),
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
                _buildSectionTitle('รูปภาพเมนู'),
                const SizedBox(height: 8),
                Center(
                  child: newImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(newImage!, height: 180),
                        )
                      : currentImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(currentImageUrl!, height: 180),
                        )
                      : const Text('ยังไม่ได้เลือกรูปภาพ'),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('เปลี่ยนรูปภาพ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildSectionTitle('ตัวเลือกเมนู (Options)'),
                const SizedBox(height: 8),
                ...optionsList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: option['name'],
                            decoration: _inputDecoration(
                              'เช่น เผ็ดมาก, ไม่เผ็ด',
                            ),
                            onChanged: (val) =>
                                optionsList[index]['name'] = val,
                            validator: (val) =>
                                val == null || val.isEmpty ? 'กรอกชื่อ' : null,
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
                              optionsList[index]['price'] = parsed ?? 0.0;
                            },
                            validator: (val) =>
                                val == null || val.isEmpty ? 'กรอกราคา' : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeOption(index),
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text(
                    'เพิ่มตัวเลือก',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
