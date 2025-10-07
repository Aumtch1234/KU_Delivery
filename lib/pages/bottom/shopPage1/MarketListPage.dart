import 'package:flutter/material.dart';
import 'package:delivery/APIs/Foods/MaketsAllAPI.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:delivery/pages/store/StoreMenuPage.dart';

class MarketListPage extends StatefulWidget {
  const MarketListPage({Key? key}) : super(key: key);

  @override
  State<MarketListPage> createState() => _MarketListPageState();
}

class _MarketListPageState extends State<MarketListPage> {
  final MarketsApiService _marketApiService = MarketsApiService();
  bool isLoading = true;
  List<dynamic> markets = [];

  @override
  void initState() {
    super.initState();
    fetchMarkets();
  }

  Future<void> fetchMarkets() async {
    try {
      final auth = AuthService();
      await auth.refreshUserToken();
      final token = await auth.getToken();
      if (token == null) return;

      final data = await _marketApiService.getAllMarkets();
      setState(() {
        markets = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching markets: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ร้านค้าที่เข้าร่วม'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : markets.isEmpty
              ? const Center(child: Text('ไม่พบข้อมูลร้านค้า'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: markets.length,
                  itemBuilder: (context, index) {
                    final market = markets[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoreMenuPage(
                              marketID: market['market_id'],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                market['shop_logo_url'] ??
                                    'https://via.placeholder.com/150',
                                height: isTablet ? 140 : 120,
                                width: isTablet ? 140 : 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.store, size: 80),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                market['shop_name'] ?? 'ชื่อร้านไม่ระบุ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
