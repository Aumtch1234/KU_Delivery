import 'package:delivery/SplashScreens/SplashScreen.dart';
import 'package:delivery/middleware/AuthGuard.dart';
import 'package:delivery/middleware/authService.dart';
import 'package:delivery/pages/bottom/DashboardPage.dart';
import 'package:delivery/pages/bottom/MainNavigation.dart';
import 'package:delivery/pages/bottom/ShopPage.dart';
import 'package:delivery/pages/WellcomePage.dart';
import 'package:delivery/pages/myMarket/RegisterShopPage.dart';
import 'package:delivery/pages/myMarket/myMarketPage.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthService();
  await auth.loadUser();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  Future<bool> isLoggedIn() async {
    final token = await AuthService().getToken();


    return token != null;
  }

  @override
 Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',                    // ✅ ใช้แค่นี้ก็พอ
      routes: {
        '/': (_) => SplashScreen(),         // ตรวจสอบ token ที่นี่
        '/login': (_) => wellcomePage(),
        '/dashboard': (_) => AuthGuard(child: DashboardPage()),
        '/shop': (_) => AuthGuard(child: ShopPage()),
        '/main': (_) => AuthGuard(child: MainNavigation()), // ✅ ตรงนี้
        '/myMarket': (_) => AuthGuard(child: Mymarketpage()), // ร้านค้าของฉัน
        '/add/market': (_) => AuthGuard(child: RegisterShopPage()), // ร้านค้าของฉัน


      },
      debugShowCheckedModeBanner: false,   // optional: ซ่อน debug banner
    );
  }
}
