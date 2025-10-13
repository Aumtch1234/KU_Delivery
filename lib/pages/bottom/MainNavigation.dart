import 'dart:convert';

import 'package:delivery/pages/bottom/CustomerOrderPage.dart';
import 'package:delivery/pages/bottom/DashboardPage.dart';
import 'package:delivery/pages/bottom/ShopPage.dart';
import 'package:delivery/pages/chat/ChatListPage.dart';
import 'package:delivery/pages/historys/HistorysPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  int? userId;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      final userData = jsonDecode(userStr);
      setState(() {
        userId = userData['user_id'];
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _animationController.reset();
    _animationController.forward();
  }

  // Modern navigation items with better icons and colors
  List<BottomNavigationItem> get _navItems => [
    BottomNavigationItem(
      icon: Icons.store_outlined,
      activeIcon: Icons.store,
      label: 'ร้านค้า',
      color: Colors.blue,
    ),
    BottomNavigationItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'คำสั่งซื้อ',
      color: Colors.orange,
    ),
    BottomNavigationItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'แชท',
      color: Colors.green,
    ),
    BottomNavigationItem(
      icon: Icons.history_edu_outlined,
      activeIcon: Icons.chat_bubble,
      label: 'ประวัติ',
      color: Colors.green,
    ),
    BottomNavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'โปรไฟล์',
      color: Colors.purple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      ShopPage(),
      CustomerOrderPage(userId: userId),
      CustomerChatListScreen(),
      OrderHistoryPage(),
      DashboardPage(),
    ];

    return WillPopScope(
      onWillPop: () async {
        print('Back button pressed. Current tab: $_selectedIndex');
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          print('Switched to Shop tab, consume back event');
          return false;
        }
        print('On Shop tab, allow back event (exit app)');
        return true;
      },
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 65,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _navItems.asMap().entries.map((entry) {
                  int index = entry.key;
                  BottomNavigationItem item = entry.value;
                  bool isSelected = _selectedIndex == index;

                  return GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 16 : 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? item.color.withOpacity(0.1) 
                          : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: _animation,
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected 
                                ? item.color 
                                : Colors.grey.shade600,
                              size: isSelected ? 26 : 24,
                            ),
                          ),
                          if (isSelected) ...[
                            SizedBox(width: 8),
                            AnimatedOpacity(
                              opacity: isSelected ? 1.0 : 0.0,
                              duration: Duration(milliseconds: 300),
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: item.color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper class for navigation items
class BottomNavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  BottomNavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}