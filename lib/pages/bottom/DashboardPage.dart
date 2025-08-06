import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery/middleware/authService.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

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
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final fixed = dateStr.replaceFirst(' ', 'T');
      final date = DateTime.parse(fixed);
      final formatter = DateFormat('d MMMM y', 'th');
      return formatter.format(date);
    } catch (e) {
      debugPrint('Date parse error: $e | input: $dateStr');
      return '-';
    }
  }

  Widget _buildProfileHeader() {
    if (user == null) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          backgroundImage: _isNetworkUrl(user!['photo_url'])
              ? NetworkImage(user!['photo_url'])
              : const AssetImage('assets/default_profile.png') as ImageProvider,
        ),
        const SizedBox(height: 16),
        Text(
          user!['display_name'] ?? 'ผู้ใช้งาน',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user!['email'] ?? '',
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
        ),
        const SizedBox(height: 8),
        _buildVerificationStatus(),
      ],
    );
  }

  Widget _buildVerificationStatus() {
    final isVerified =
        user!['is_verified'] == true || user!['is_verified'] == 'true';
    final verificationText = isVerified
        ? 'ยืนยันตัวตนแล้ว'
        : 'ยังไม่ยืนยันตัวตน';
    final verificationColor = isVerified
        ? const Color(0xFF34C759)
        : Colors.redAccent;

    if (isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: verificationColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, color: verificationColor, size: 18),
            const SizedBox(width: 6),
            Text(
              verificationText,
              style: TextStyle(
                fontSize: 14,
                color: verificationColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return TextButton.icon(
        icon: const Icon(
          Icons.error_outline,
          color: Colors.redAccent,
          size: 18,
        ),
        label: Text(
          verificationText,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () => Navigator.pushNamed(
          context,
          '/verify',
        ).then((_) => _refreshAndLoadUser()),
      );
    }
  }

  Widget _buildUserInfoCard() {
    if (user == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.calendar_today_rounded,
              color: Color(0xFF34C759),
            ),
            title: const Text(
              "ลงทะเบียนเมื่อ",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              _formatDate(user!['created_at']),
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.store_rounded, color: Color(0xFF34C759)),
            title: const Text(
              "สถานะร้านค้า",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              (user!['is_seller'] == true || user!['is_seller'] == 'true')
                  ? 'เป็นเจ้าของร้าน'
                  : 'ยังไม่ได้สมัคร',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isSeller = user!['is_seller'] == true || user!['is_seller'] == 'true';
    final isVerified =
        user!['is_verified'] == true || user!['is_verified'] == 'true';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          if (isSeller)
            _buildMenuTile(
              text: 'ร้านค้าของฉัน',
              icon: Icons.storefront_rounded,
              onPressed: () => Navigator.pushNamed(context, '/myMarket'),
            )
          else
            _buildMenuTile(
              text: 'สมัครร้านค้า',
              icon: Icons.add_business_rounded,
              onPressed: () {
                if (!isVerified) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กรุณายืนยันตัวตนก่อนสมัครร้านค้า'),
                    ),
                  );
                  Navigator.pushNamed(
                    context,
                    '/verify',
                  ).then((_) => _refreshAndLoadUser());
                } else {
                  Navigator.pushNamed(
                    context,
                    '/add/market',
                  ).then((_) => _refreshAndLoadUser());
                }
              },
            ),
          const Divider(height: 1, thickness: 0.5),
          _buildMenuTile(
            text: 'แก้ไขข้อมูลส่วนตัว',
            icon: Icons.edit_rounded,
            onPressed: () => Navigator.pushNamed(context, '/editprofile'),
          ),
          const Divider(height: 1, thickness: 0.5),
          _buildMenuTile(
            text: 'ออกจากระบบ',
            icon: Icons.logout_rounded,
            color: Colors.redAccent,
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.black87,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 18,
        color: Colors.grey.shade400,
      ),
      onTap: onPressed,
      dense: false,
      minVerticalPadding: 12,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
    );
  }

  void _showLogoutDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.rightSlide,
      headerAnimationLoop: false,
      title: 'ต้องการออกจากระบบใช่หรือไม่?',
      desc: 'คุณจะต้องเข้าสู่ระบบใหม่อีกครั้งเพื่อใช้งาน',
      btnCancelOnPress: () {},
      btnCancelText: 'ยกเลิก',
      // แก้ไขตรงนี้: เรียกใช้ AuthService().logout() พร้อมส่ง context
      btnOkOnPress: () => AuthService().logout(),
      btnOkText: 'ออกจากระบบ',
      btnOkColor: Colors.red,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: const Color(0xFF34C759),
                  pinned: true,
                ),
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF34C759), Color(0xFF5AC8FA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(child: _buildProfileHeader()),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    _buildUserInfoCard(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                  ]),
                ),
              ],
            ),
    );
  }
}
