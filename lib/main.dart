import 'package:delivery/APIs/Chat/ChatControllerSKAPI.dart';
import 'package:delivery/APIs/Orders/OrdersSocket.dart';
import 'package:delivery/SplashScreens/SplashScreen.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:delivery/pages/EditProfilePage.dart';
import 'package:delivery/pages/LoginPage.dart';
import 'package:delivery/pages/RegisterPage.dart';
import 'package:delivery/pages/Verify-OTP-Page.dart';
import 'package:delivery/pages/VerifyPage.dart';
import 'package:delivery/pages/basket/MyBasket.dart';
import 'package:delivery/pages/bottom/DashboardPage.dart';
import 'package:delivery/pages/bottom/MainNavigation.dart';
import 'package:delivery/pages/bottom/ShopPage.dart';
import 'package:delivery/pages/WellcomePage.dart';
import 'package:delivery/pages/myMarket/AddFoodPage.dart';
import 'package:delivery/pages/myMarket/Dashboard_salesPage.dart';
import 'package:delivery/pages/myMarket/EditFoodPage.dart';
import 'package:delivery/pages/myMarket/EditMarket.dart';
import 'package:delivery/pages/myMarket/RegisterShopPage.dart';
import 'package:delivery/pages/myMarket/myMarketPage.dart';
import 'package:delivery/pages/my_Address/AddAddressPage.dart';
import 'package:delivery/pages/my_Address/MyAddressPage.dart';
import 'package:delivery/pages/order/OrderNowPage.dart';
import 'package:delivery/pages/order/RecipientAddress.dart';
import 'package:delivery/pages/status/TakingStatusPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/basket/providers/basket_provider.dart';
import 'APIs/Analytics_Dashboard/Market/Dashboard_salesAPIs.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'AssistiveButton.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthService();
  await auth.loadUser();
  await initializeDateFormatting('th', null); // โหลด locale "th"

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BasketProvider()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => DashboardSalesController()),
        ChangeNotifierProvider(create: (_) => CustomerChatController()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  Future<bool> isLoggedIn() async {
    final token = await AuthService().getToken();

    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/', // ✅ ใช้แค่นี้ก็พอ
      routes: {
        '/': (_) => const RouteWrapper(
          child: SplashScreen(),
          routeName: '/',
        ), // ตรวจสอบ token ที่นี่
        '/wellcome': (_) =>
            RouteWrapper(child: wellcomePage(), routeName: '/wellcome'),
        '/login': (_) =>
            const RouteWrapper(child: LoginPage(), routeName: '/login'),
        '/register': (_) =>
            const RouteWrapper(child: RegisterPage(), routeName: '/register'),

        '/verify': (_) =>
            const RouteWrapper(child: VerifyPage(), routeName: '/verify'),
        '/verify-otp': (_) =>
            RouteWrapper(child: OtpVerifyPage(), routeName: '/verify-otp'),

        '/dashboard': (_) =>
            RouteWrapper(child: DashboardPage(), routeName: '/dashboard'),
        '/shop': (_) => RouteWrapper(child: ShopPage(), routeName: '/shop'),
        '/main': (_) =>
            RouteWrapper(child: MainNavigation(), routeName: '/main'),
        '/add/market': (_) =>
            RouteWrapper(child: RegisterShopPage(), routeName: '/add/market'),
        '/myMarket': (_) =>
            RouteWrapper(child: Mymarketpage(), routeName: '/myMarket'),
        '/editprofile': (_) =>
            RouteWrapper(child: EditProfilePage(), routeName: '/editprofile'),
        '/myMarket/edit': (_) =>
            RouteWrapper(child: EditShopPage(), routeName: '/myMarket/edit'),
        '/addFood': (_) =>
            RouteWrapper(child: AddFoodPage(), routeName: '/addFood'),
        '/editFood': (_) =>
            RouteWrapper(child: EditFoodPage(), routeName: '/editFood'),
        '/basket': (context) =>
            RouteWrapper(child: MyBasketPage(), routeName: '/basket'),
        '/order-now': (context) =>
            RouteWrapper(child: OrderNowPage(), routeName: '/order-now'),
        '/recipient-address': (context) => RouteWrapper(
          child: RecipientAddressPage(),
          routeName: '/recipient-address',
        ),
        '/status': (_) =>
            RouteWrapper(child: TakingStatusPage(), routeName: '/status'),

        '/myaddress': (_) =>
            RouteWrapper(child: ShippingAddressPage(), routeName: '/myaddress'),
        '/add-address': (_) => RouteWrapper(
          child: DeliveryAddressForm(),
          routeName: '/add-address',
        ),
        '/dashboard-sales': (context) {
          // รับ marketId จาก arguments
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final marketId = args?['marketId'] as int?;
          return RouteWrapper(
            child: DashboardSalesPage(marketId: marketId),
            routeName: '/dashboard-sales',
          );
        },
      },
      debugShowCheckedModeBanner: false,
      // builder: (context, child) {
      //   return Stack(
      //     children: [
      //       // แอพปกติเป็นชั้นล่างสุด พร้อมกับการจับการแตะ
      //       GestureDetector(
      //         onTap: () {
      //           // แสดงปุ่มช่วยเหลือกลับมาเมื่อแตะที่หน้าจอ
      //           AssistiveButton.showButton(context);
      //         },
      //         child: child,
      //       ),
      //       // ปุ่มช่วยเหลือลอยอยู่ด้านบน
      //       const AssistiveButton(),
      //     ],
      //   );
      // },
    );
  }
}

class RouteWrapper extends StatelessWidget {
  final Widget child;
  final String routeName;

  const RouteWrapper({Key? key, required this.child, required this.routeName})
    : super(key: key);

  bool _shouldShowAssistiveButton(String routeName) {
    // ซ่อนปุ่มในบาง route เช่น login, register
    final hiddenRoutes = ['/', '/wellcome', '/login', '/register'];
    return !hiddenRoutes.contains(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final shouldShow =
            _shouldShowAssistiveButton(routeName) && auth.isSellerApproved;

        print(
          'Route: $routeName, Show Button: $shouldShow, isSellerApproved: ${auth.isSellerApproved}, isPending: ${auth.isPendingSeller}',
        );

        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (shouldShow) {
                  AssistiveButton.showButton(context);
                }
              },
              child: child,
            ),
            if (shouldShow) const AssistiveButton(),
          ],
        );
      },
    );
  }
}
