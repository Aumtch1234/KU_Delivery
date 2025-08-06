import 'package:delivery/pages/bottom/DashboardPage.dart';
import 'package:delivery/pages/bottom/ShopPage.dart';
import 'package:delivery/pages/chat/ChatPage.dart';
import 'package:flutter/material.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    ShopPage(), 
    ChatPage(),
    DashboardPage(),
    // เพิ่มหน้าอื่นๆ ที่ต้องการใน navigation bar
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
    BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'แชท'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        print('Back button pressed. Current tab: $_selectedIndex');
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          print('Switched to Shop tab, consume back event');
          return false; // กิน event back
        }
        print('On Shop tab, allow back event (exit app)');
        return true; // ออกแอป
      },
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: _navItems,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
