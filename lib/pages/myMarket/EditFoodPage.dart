import 'dart:io';
import 'dart:convert';
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

  List<Map<String, dynamic>> optionsList = [];

  bool _isInit = false;

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
            decoded.map((opt) => {
              'name': opt['label'] ?? '',
              'price': (opt['extraPrice'] is String)
                  ? double.tryParse(opt['extraPrice']) ?? 0
                  : (opt['extraPrice'] ?? 0),
            }),
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
      // ใช้ค่าจาก controller แทน
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

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขเมนู')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _foodNameController,
                decoration: const InputDecoration(labelText: 'ชื่อเมนู'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรอกชื่อเมนู' : null,
              ),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ราคา'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรอกราคา' : null,
              ),
              const SizedBox(height: 10),
              if (newImage != null)
                Image.file(newImage!, height: 150)
              else if (currentImageUrl != null)
                Image.network(currentImageUrl!, height: 150),
              TextButton(
                onPressed: _pickImage,
                child: const Text('เปลี่ยนรูปภาพ'),
              ),
              const SizedBox(height: 20),
              const Text(
                'ตัวเลือกเมนู (Options)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...optionsList.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: option['name'],
                        decoration: InputDecoration(
                          labelText: 'ชื่อ ตัวเลือก #${index + 1}',
                        ),
                        onChanged: (val) => optionsList[index]['name'] = val,
                        validator: (val) =>
                            val == null || val.isEmpty ? 'กรอกชื่อ' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: option['price'].toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ราคา'),
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
                );
              }),
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('เพิ่มตัวเลือก'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitUpdate,
                child: const Text('บันทึกการเปลี่ยนแปลง'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
