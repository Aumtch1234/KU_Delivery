import 'dart:io';
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

  void _submitForm() async {
    if (!_formKey.currentState!.validate() || image == null) return;

    _formKey.currentState!.save();
    await uploadFood(
      foodName: foodName,
      price: price,
      image: image!,
      options: options,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("เพิ่มเมนู")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'ชื่อเมนู'),
                onSaved: (val) => foodName = val!,
                validator: (val) => val == null || val.isEmpty ? 'กรอกชื่อเมนู' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'ราคา (บาท)'),
                keyboardType: TextInputType.number,
                onSaved: (val) => price = double.tryParse(val!) ?? 0,
                validator: (val) => val == null || val.isEmpty ? 'กรอกราคา' : null,
              ),
              const SizedBox(height: 10),
              image != null
                  ? Image.file(image!, height: 150)
                  : Text("ยังไม่ได้เลือกรูปภาพ"),
              ElevatedButton(onPressed: _pickImage, child: Text("เลือกรูปเมนู")),
              const SizedBox(height: 20),
              Text("ตัวเลือกเพิ่มเติม", style: TextStyle(fontWeight: FontWeight.bold)),
              ...options.asMap().entries.map((entry) {
                int i = entry.key;
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: entry.value['label'],
                        decoration: InputDecoration(labelText: 'ตัวเลือก เช่น เผ็ดน้อย'),
                        onChanged: (val) => options[i]['label'] = val,
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: entry.value['extraPrice'].toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'เพิ่ม (฿)'),
                        onChanged: (val) =>
                            options[i]['extraPrice'] = double.tryParse(val) ?? 0.0,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeOption(i),
                      icon: Icon(Icons.delete, color: Colors.red),
                    )
                  ],
                );
              }).toList(),
              TextButton.icon(
                icon: Icon(Icons.add),
                label: Text("เพิ่มตัวเลือก"),
                onPressed: _addOption,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text("บันทึกเมนู"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
