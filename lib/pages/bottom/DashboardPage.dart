import 'dart:convert';
import 'package:delivery/middleware/authService.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    _refreshAndLoadUser();
  }

  Future<void> _refreshAndLoadUser() async {
    await AuthService().refreshUserToken();
    print('เรียก refresh token สำเร็จ');
    await _loadUser();
    print('โหลด user ใหม่: $user');
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      setState(() {
        user = jsonDecode(userStr);
      });
    }
  }

  bool _isNetworkUrl(String? url) {
    if (url == null) return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Widget _buildUserInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow("ลงทะเบียนเมื่อ", user!['created_at'] ?? '-'),
          _infoRow("Google ID", user!['google_id'] ?? '-'),
          _infoRow(
            "สถานะร้านค้า",
            user!['is_seller'] == true ? 'เป็นเจ้าของร้าน' : 'ยังไม่ได้สมัคร',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text("แดชบอร์ด"),
        backgroundColor: const Color(0xFF34C759),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("กำลังโหลดข้อมูลผู้ใช้..."),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _isNetworkUrl(user!['photo_url'])
                        ? NetworkImage(user!['photo_url'])
                        : AssetImage('assets/avatars/${user!['photo_url']}')
                              as ImageProvider,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user!['display_name'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user!['email'] ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  _buildUserInfoCard(),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      if (user!['is_seller'] == true)
                        _buildButton(
                          text: 'ร้านค้าของฉัน',
                          icon: Icons.storefront_rounded,
                          color: const Color(0xFF34C759),
                          onPressed: () {
                            Navigator.pushNamed(context, '/myMarket');
                          },
                        ),
                      if (user!['is_seller'] == false ||
                          user!['is_seller'] == null)
                        _buildButton(
                          text: 'สมัครร้านค้า',
                          icon: Icons.add_business_rounded,
                          color: Colors.orange.shade600,
                          onPressed: () async {
                            Navigator.pushNamed(context, '/add/market').then((
                              _,
                            ) async {
                              await AuthService().refreshUserToken();
                              await _loadUser();
                            });
                          },
                        ),
                      _buildButton(
                        text: 'ออกจากระบบ',
                        icon: Icons.logout_rounded,
                        color: Colors.redAccent,
                        onPressed: () {
                          AuthService().confirmLogout(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 160,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(text, style: const TextStyle(fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
