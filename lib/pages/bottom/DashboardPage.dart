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
    await _loadUser();
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
    return uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: _isNetworkUrl(user!['photo_url'])
              ? NetworkImage(user!['photo_url'])
              : AssetImage('${user!['photo_url']}') as ImageProvider,
        ),
        const SizedBox(height: 12),
        Text(
          user!['display_name'] ?? '',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          user!['email'] ?? '',
          style: TextStyle(color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        _buildVerificationStatus(),
      ],
    );
  }

  Widget _buildVerificationStatus() {
    final isVerified = user!['is_verified'] == true || user!['is_verified'] == 'true';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isVerified ? Icons.verified : Icons.error_outline,
          color: isVerified ? Color(0xFF34C759) : Colors.redAccent,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          isVerified ? 'ยืนยันตัวตนแล้ว' : 'ยังไม่ยืนยันตัวตน',
          style: TextStyle(
            fontSize: 14,
            color: isVerified ? Color(0xFF34C759) : Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("ลงทะเบียนเมื่อ"),
              subtitle: Text(user!['created_at'] ?? '-'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text("Google ID"),
              subtitle: Text(user!['google_id'] ?? '-'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text("สถานะร้านค้า"),
              subtitle: Text(
                user!['is_seller'] == true || user!['is_seller'] == 'true'
                    ? 'เป็นเจ้าของร้าน'
                    : 'ยังไม่ได้สมัคร',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final isSeller = user!['is_seller'] == true || user!['is_seller'] == 'true';
    final isVerified = user!['is_verified'] == true || user!['is_verified'] == 'true';

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        if (isSeller)
          _buildButton(
            text: 'ร้านค้าของฉัน',
            icon: Icons.storefront_rounded,
            color: const Color(0xFF34C759),
            onPressed: () => Navigator.pushNamed(context, '/myMarket'),
          )
        else
          _buildButton(
            text: 'สมัครร้านค้า',
            icon: Icons.add_business_rounded,
            color: Colors.orange.shade600,
            onPressed: () {
              if (!isVerified) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณายืนยันตัวตนก่อนสมัครร้านค้า')),
                );
                Navigator.pushNamed(context, '/verify').then((_) => _refreshAndLoadUser());
              } else {
                Navigator.pushNamed(context, '/add/market').then((_) => _refreshAndLoadUser());
              }
            },
          ),
        _buildButton(
          text: 'แก้ไขข้อมูลส่วนตัว',
          icon: Icons.edit,
          color: Colors.blue,
          onPressed: () => Navigator.pushNamed(context, '/editprofile'),
        ),
        _buildButton(
          text: 'ออกจากระบบ',
          icon: Icons.logout_rounded,
          color: Colors.redAccent,
          onPressed: () => AuthService().confirmLogout(context),
        ),
      ],
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
        icon: Icon(icon, size: 20),
        label: Text(text, style: const TextStyle(fontSize: 14)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 2,
        ),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfileSection(),
                  const SizedBox(height: 24),
                  _buildUserInfoCard(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }
}
