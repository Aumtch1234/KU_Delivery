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
    _loadUser();
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
      appBar: AppBar(title: Text("Dashboard")),
      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(), // ✅ ใส่ loading ระหว่างโหลด user
                  SizedBox(height: 16),
                  Text("กำลังโหลดข้อมูลผู้ใช้..."),
                ],
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _isNetworkUrl(user!['photo_url'])
                          ? NetworkImage(user!['photo_url'])
                          : AssetImage('assets/avatars/${user!['photo_url']}')
                                as ImageProvider,
                    ),
                    SizedBox(height: 16),
                    Text(
                      user!['display_name'] ?? '',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      user!['email'] ?? '',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(height: 24),
                    Text(
                      user!['created_at'] ?? '',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(height: 24),
                     Text(
                      user!['google_id'] ?? '',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // ยังคงใช้ AuthService ในส่วน logout ได้
                        AuthService().confirmLogout(context);
                      },
                      child: Text("Logout"),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/myMarket');
                      },
                      child: Text("ร้านค้าของฉัน"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
