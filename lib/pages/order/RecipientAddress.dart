import 'package:flutter/material.dart';
import 'PickMapPage.dart';

class RecipientAddressPage extends StatefulWidget {
  static const routeName = '/recipient-address';
  final Map<String, dynamic>? initialAddress;
  const RecipientAddressPage({super.key, this.initialAddress});

  @override
  State<RecipientAddressPage> createState() => _RecipientAddressPageState();
}

class _RecipientAddressPageState extends State<RecipientAddressPage> {
  late TextEditingController placeController;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  String? mapLocation;

  @override
  void initState() {
    super.initState();
    placeController = TextEditingController(
      text: widget.initialAddress?['place'] ?? '',
    );
    nameController = TextEditingController(
      text: widget.initialAddress?['name'] ?? '',
    );
    phoneController = TextEditingController(
      text: widget.initialAddress?['phone'] ?? '',
    );
    addressController = TextEditingController(
      text: widget.initialAddress?['address'] ?? '',
    );
    mapLocation = widget.initialAddress?['mapLocation'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF34C759),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ที่อยู่', style: TextStyle(color: Colors.black)),
        centerTitle: false,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ชื่อของอยู่จัดส่ง*',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: placeController,
                decoration: const InputDecoration(
                  hintText: 'เช่น บ้าน,ที่ทำงาน',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ข้อมูลติดต่อ*',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'ชื่อ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'เบอร์โทรศัพท์',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ที่อยู่*',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  hintText: 'รายละเอียด เช่น บ้านเลขที่, อำเภอ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF34C759),
                    side: const BorderSide(color: Color(0xFF34C759)),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PickMapPage()),
                    );
                    if (result != null) {
                      setState(() {
                        mapLocation = '${result.latitude},${result.longitude}';
                      });
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('เลือกจากแผนที่'),
                      Icon(Icons.arrow_forward_ios, size: 18),
                    ],
                  ),
                ),
              ),
              if (mapLocation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'ตำแหน่งที่เลือก: $mapLocation',
                    style: const TextStyle(color: Colors.green, fontSize: 13),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34C759),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context, {
                      'place': placeController.text,
                      'name': nameController.text,
                      'phone': phoneController.text,
                      'address': addressController.text,
                      'mapLocation': mapLocation,
                    });
                  },
                  child: const Text('บันทึก', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
