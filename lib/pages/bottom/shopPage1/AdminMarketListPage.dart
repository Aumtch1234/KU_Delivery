import 'package:flutter/material.dart';
import 'package:delivery/APIs/Foods/MaketsAllAPI.dart';
import 'package:delivery/APIs/middleware/authService.dart';
import 'package:delivery/pages/store/StoreMenuPage.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminMarketListPage extends StatefulWidget {
  const AdminMarketListPage({Key? key}) : super(key: key);

  @override
  State<AdminMarketListPage> createState() => _AdminMarketListPageState();
}

class _AdminMarketListPageState extends State<AdminMarketListPage> {
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

      final data = await _marketApiService.getAllADMINMarkets();
      setState(() {
        markets = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching markets: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

  try {
    // ใช้ mode external เพื่อเปิดแอปโทรศัพท์โดยตรง
    if (!await launchUrl(launchUri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch dialer');
    }
  } catch (e) {
    print('❌ Error launching phone call: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ไม่สามารถเปิดแอปโทรศัพท์ได้')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ร้านค้าแอดมิน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : markets.isEmpty
          ? const Center(child: Text('ไม่พบข้อมูลร้านค้า'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: markets.length,
              itemBuilder: (context, index) {
                final market = markets[index];
                final isOpen = market['is_open'] ?? false;
                final rating = market['rating'];
                final phone = market['phone'] ?? '-';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StoreMenuPage(marketID: market['market_id']),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // รูปร้าน
                            Stack(
                              children: [
                                Hero(
                                  tag: 'shop_${market['market_id']}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      market['shop_logo_url'] ??
                                          'https://via.placeholder.com/150',
                                      width: 120,
                                      height: 140,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: 120,
                                                height: 140,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Icon(
                                                  Icons.store_rounded,
                                                  size: 50,
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                                // Status badge
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOpen
                                          ? Colors.green
                                          : Colors.red.shade400,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (isOpen
                                                      ? Colors.green
                                                      : Colors.red)
                                                  .withOpacity(0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      isOpen ? 'เปิด' : 'ปิด',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),

                            // ข้อมูลร้าน
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ชื่อร้านและดาว
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          market['shop_name'] ??
                                              'ชื่อร้านไม่ระบุ',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // เวลาเปิด-ปิด
                                  if (market['open_time'] != null &&
                                      market['close_time'] != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: isOpen
                                              ? Colors.green.shade700
                                              : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${market['open_time']} - ${market['close_time']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isOpen
                                                ? Colors.green.shade700
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 6),

                                  // Rating
                                  if (rating != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          size: 16,
                                          color: Colors.amber.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          double.tryParse(
                                                rating.toString(),
                                              )?.toStringAsFixed(1) ??
                                              '0.0',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (rating != null) const SizedBox(height: 6),

                                  // คำอธิบายร้าน
                                  if (market['shop_description'] != null &&
                                      market['shop_description']
                                          .toString()
                                          .isNotEmpty)
                                    Text(
                                      market['shop_description'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 10),

                                  // เบอร์โทร
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone_rounded,
                                        size: 16,
                                        color: Colors.blue.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          phone,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade900,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (phone != '-')
                                        const SizedBox(width: 8),
                                      if (phone != '-')
                                        Material(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: InkWell(
                                            onTap: () => _makePhoneCall(phone),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              child: const Icon(
                                                Icons.call_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
