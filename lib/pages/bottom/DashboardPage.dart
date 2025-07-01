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
              padding: const EdgeInsets.all(20),
              child: Center(
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
                    const SizedBox(height: 8),
                    Text(
                      user!['email'] ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ลงทะเบียนเมื่อ: ${user!['created_at'] ?? '-'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Google ID: ${user!['google_id'] ?? '-'}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    Text(
                      'Is_Seller: ${user!['is_seller'] ?? '-'}',
                      style: TextStyle(fontSize: 13, color: Colors.red[500]),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (user!['is_seller'] == true)
                          _buildButton(
                            text: 'ร้านค้าของฉัน',
                            icon: Icons.store,
                            color: Colors.green.shade600,
                            onPressed: () {
                              Navigator.pushNamed(context, '/myMarket');
                            },
                          ),
                        if (user!['is_seller'] == false ||
                            user!['is_seller'] == null)
                          _buildButton(
                            text: 'สมัครร้านค้า',
                            icon: Icons.add_business,
                            color: Colors.orange.shade600,
                            onPressed: () {
                              Navigator.pushNamed(context, '/add/market').then((
                                _,
                              ) async {
                                await AuthService()
                                    .refreshUserToken(); // รีเฟรช token ใหม่
                                await _loadUser(); // โหลด user ใหม่เข้า state
                              });
                            },
                          ),
                        _buildButton(
                          text: 'ออกจากระบบ',
                          icon: Icons.logout,
                          color: Colors.red.shade400,
                          onPressed: () {
                            AuthService().confirmLogout(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
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
