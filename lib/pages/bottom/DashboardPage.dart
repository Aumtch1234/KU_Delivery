import 'dart:convert';
import 'package:delivery/APIs/Markets/FetchMarket.dart';
import 'package:delivery/pages/WellcomePage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? user;
  Map<String, dynamic>? marketData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshAndLoadUser();
  }

  Future<void> _refreshAndLoadUser() async {
    setState(() => isLoading = true);
    await AuthService().refreshUserToken();
    await _loadUser();
    setState(() => isLoading = false);
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');

    if (userStr == null) return;

    final loadedUser = jsonDecode(userStr);

    try {
      final marketDataResult = await fetchMyMarket();

      if (marketDataResult != null) {
        loadedUser['is_seller'] = marketDataResult['approve'] == true;
        marketData = marketDataResult;
      } else {
        loadedUser['is_seller'] = false;
        marketData = null;
      }
    } catch (e) {
      loadedUser['is_seller'] = false;
      marketData = null;
      debugPrint('Error fetching my-market: $e');
    }

    setState(() {
      user = loadedUser;
    });
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
      final formatter = DateFormat('d MMM y', 'th');
      return formatter.format(date);
    } catch (e) {
      debugPrint('Date parse error: $e | input: $dateStr');
      return '-';
    }
  }

  Widget _buildPendingApprovalBanner() {
    if (marketData == null || marketData!['approve'] == true) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade50, Colors.amber.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'อยู่ระหว่างการตรวจสอบ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ร้านค้าของคุณอยู่ในขั้นตอนการรออนุมัติ กรุณารอการตรวจสอบจากผู้ดูแลระบบ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (user == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  backgroundImage: _isNetworkUrl(user!['photo_url'])
                      ? NetworkImage(user!['photo_url'])
                      : const AssetImage('assets/default_profile.png')
                            as ImageProvider,
                ),
              ),
              if (user!['is_verified'] == true ||
                  user!['is_verified'] == 'true')
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF34C759),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              user!['display_name'] ?? 'ผู้ใช้งาน',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    color: Colors.black26,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: Text(
              user!['email'] ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          _buildVerificationStatus(),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus() {
    final isVerified =
        user!['is_verified'] == true || user!['is_verified'] == 'true';

    if (isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text(
              'ยืนยันตัวตนแล้ว',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: () => Navigator.pushNamed(
              context,
              '/verify',
            ).then((_) => _refreshAndLoadUser()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ยืนยันตัวตน',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildUserInfoCard() {
    if (user == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        child: Container(
          child: Column(
            children: [
              _buildInfoTile(
                icon: Icons.calendar_today_rounded,
                title: "ลงทะเบียนเมื่อ",
                value: _formatDate(user!['created_at']),
                iconColor: const Color(0xFF34C759),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              _buildInfoTile(
                icon: Icons.store_rounded,
                title: "สถานะร้านค้า",
                value: _getShopStatusText(),
                valueColor: _getShopStatusColor(),
                iconColor: const Color(0xFF34C759),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getShopStatusText() {
    if (marketData != null && marketData!['approve'] == true) {
      return 'เจ้าของร้าน ${marketData!['shop_name'] ?? ''}';
    } else if (marketData != null && marketData!['approve'] == false) {
      return 'รอการอนุมัติ';
    } else {
      return 'ไม่มีร้านค้า';
    }
  }

  Color _getShopStatusColor() {
    if (marketData != null && marketData!['approve'] == true) {
      return const Color(0xFF34C759);
    } else if (marketData != null && marketData!['approve'] == false) {
      return Colors.orange;
    } else {
      return Colors.grey.shade600;
    }
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    Color? valueColor,
  }) {
    return Container(
      width: double.infinity, // ให้เต็มบรรทัด
      padding: const EdgeInsets.symmetric(
        vertical: 18,
      ), // ปรับเหลือเฉพาะ vertical
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.grey.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
    final isPending = marketData != null && marketData!['approve'] == false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        child: Container(
          child: Column(
            children: [
              if (isSeller)
                _buildMenuTile(
                  text: 'ร้านค้าของฉัน',
                  icon: Icons.storefront_rounded,
                  iconColor: const Color(0xFF34C759),
                  onPressed: () => Navigator.pushNamed(context, '/myMarket'),
                )
              else if (isPending)
                _buildMenuTile(
                  text: 'ร้านค้าของฉัน (รออนุมัติ)',
                  icon: Icons.schedule_rounded,
                  iconColor: Colors.orange,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'ร้านค้าของคุณอยู่ระหว่างการรออนุมัติ กรุณารอการตรวจสอบ',
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                )
              else
                _buildMenuTile(
                  text: 'สมัครร้านค้า',
                  icon: Icons.add_business_rounded,
                  iconColor: const Color(0xFF007AFF),
                  onPressed: () {
                    if (!isVerified) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'กรุณายืนยันตัวตนก่อนสมัครร้านค้า',
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
              _buildDivider(),
              _buildMenuTile(
                text: 'ที่อยู่ของฉัน',
                icon: Icons.location_on_rounded,
                iconColor: const Color(0xFFFF3B30),
                onPressed: () => Navigator.pushNamed(context, '/myaddress'),
              ),
              _buildDivider(),
              _buildMenuTile(
                text: 'แก้ไขข้อมูลส่วนตัว',
                icon: Icons.edit_rounded,
                iconColor: const Color(0xFF007AFF),
                onPressed: () => Navigator.pushNamed(context, '/editprofile'),
              ),
              _buildDivider(),
              _buildMenuTile(
                text: 'ออกจากระบบ',
                icon: Icons.logout_rounded,
                iconColor: Colors.redAccent,
                textColor: Colors.redAccent,
                onPressed: () => _showLogoutDialog(),
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 20,
      endIndent: 20,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildMenuTile({
    required String text,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
    Color? textColor,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: isLast ? Radius.zero : const Radius.circular(0),
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
        onTap: onPressed,
        child: Container(
          width: double.infinity, // เพิ่มบรรทัดนี้
          padding: const EdgeInsets.symmetric(
            vertical: 18,
          ), // ปรับเหลือเฉพาะ vertical
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor ?? Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      headerAnimationLoop: false,
      title: 'ออกจากระบบ',
      desc: 'คุณต้องการออกจากระบบใช่หรือไม่?',
      btnCancelOnPress: () {},
      btnCancelText: 'ยกเลิก',
      btnOkOnPress: () async {
        await AuthService().logout();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => wellcomePage()),
          (Route<dynamic> route) => false,
        );
      },
      btnOkText: 'ออกจากระบบ',
      btnOkColor: Colors.redAccent,
      btnCancelColor: Colors.grey,
      dismissOnTouchOutside: false,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: isLoading
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF34C759), Color(0xFF5AC8FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : user == null
          ? const Center(child: Text('ไม่พบข้อมูลผู้ใช้'))
          : RefreshIndicator(
              onRefresh: _refreshAndLoadUser,
              color: const Color(0xFF34C759),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ...existing code...
                  SliverAppBar(
                    expandedHeight: 0,
                    pinned: true,
                    backgroundColor: const Color(0xFF34C759),
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    flexibleSpace: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF34C759), Color(0xFF5AC8FA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Text(
                            'โปรไฟล์ของฉัน',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ...existing code...
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF34C759), Color(0xFF5AC8FA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: _buildProfileHeader(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          _buildPendingApprovalBanner(),
                          const SizedBox(height: 8),
                          _buildUserInfoCard(),
                          const SizedBox(height: 24),
                          _buildActionButtons(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
