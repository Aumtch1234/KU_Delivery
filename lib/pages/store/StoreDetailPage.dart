import 'package:delivery/APIs/Reviews/ReviewAPI.dart';
import 'package:flutter/material.dart';
import 'package:delivery/pages/store/models/StoreDetailModels.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreDetailPage extends StatefulWidget {
  final int marketID;

  const StoreDetailPage({Key? key, required this.marketID}) : super(key: key);

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  final GlobalKey _reviewKey = GlobalKey();
  final GlobalKey _infoKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  late Future<StoreDetailResponse> _futureStoreDetail;
  int _tabIndex = 0;
  bool _isScrollListenerAttached = false;

  @override
  void initState() {
    super.initState();
    _futureStoreDetail = _fetchStoreDetail();
  }

  Future<StoreDetailResponse> _fetchStoreDetail() async {
    try {
      final Map<String, dynamic> data = await ReviewApi.getAllReviewMaket(
        widget.marketID,
      );
      return StoreDetailResponse.fromJson(data);
    } catch (e) {
      throw Exception('Error loading store details: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isScrollListenerAttached) {
      _scrollController.addListener(_onScroll);
      _isScrollListenerAttached = true;
    }
  }

  void _onScroll() {
    final reviewBox =
        _reviewKey.currentContext?.findRenderObject() as RenderBox?;
    if (reviewBox == null) return;

    final scrollBox = context.findRenderObject() as RenderBox?;
    if (scrollBox == null) return;

    try {
      final reviewOffset = reviewBox
          .localToGlobal(Offset.zero, ancestor: scrollBox)
          .dy;

      if (_scrollController.offset >= reviewOffset - 60) {
        if (_tabIndex != 1) {
          setState(() {
            _tabIndex = 1;
          });
        }
      } else {
        if (_tabIndex != 0) {
          setState(() {
            _tabIndex = 0;
          });
        }
      }
    } catch (e) {
      // Handle silently
    }
  }


Future<void> _makePhoneCall(String phoneNumber) async {
  final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(phoneUri)) {
    await launchUrl(phoneUri);
  } else {
    throw 'ไม่สามารถโทรออกได้: $phoneNumber';
  }
}


  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'รายละเอียดร้านอาหาร',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<StoreDetailResponse>(
        future: _futureStoreDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'เกิดข้อผิดพลาด: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _futureStoreDetail = _fetchStoreDetail();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final market = data.market;
          final reviews = data.reviews;

          return Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoTab(market),
                      const Divider(height: 32, thickness: 1),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'รีวิว',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      _buildReviewTab(market, reviews),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _tabIndex = 0;
                });
                if (_infoKey.currentContext != null) {
                  final box =
                      _infoKey.currentContext!.findRenderObject() as RenderBox;
                  final scrollBox = context.findRenderObject() as RenderBox?;
                  if (scrollBox != null) {
                    final offset =
                        box.localToGlobal(Offset.zero, ancestor: scrollBox).dy +
                        _scrollController.offset;
                    _scrollController.animateTo(
                      offset,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                } else {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'ข้อมูลร้าน',
                    style: TextStyle(
                      color: _tabIndex == 0 ? Colors.green : Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    color: _tabIndex == 0 ? Colors.green : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _tabIndex = 1;
                });
                if (_reviewKey.currentContext != null) {
                  final box =
                      _reviewKey.currentContext!.findRenderObject()
                          as RenderBox;
                  final scrollBox = context.findRenderObject() as RenderBox?;
                  if (scrollBox != null) {
                    final offset =
                        box.localToGlobal(Offset.zero, ancestor: scrollBox).dy +
                        _scrollController.offset;
                    _scrollController.animateTo(
                      offset,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              },
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'รีวิว',
                    style: TextStyle(
                      color: _tabIndex == 1 ? Colors.green : Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    color: _tabIndex == 1 ? Colors.green : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(Market market) {
    return Padding(
      key: _infoKey,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ แสดงรูปร้านจาก API
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              market.shopLogoUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 180,
                color: Colors.grey[300],
                child: const Icon(Icons.store, size: 64, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ✅ ชื่อร้านจาก API
          Text(
            market.shopName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          // ✅ คำอธิบายร้าน
          if (market.shopDescription.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                market.shopDescription,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 8),
              // ปุ่ม Facebook (ปิดไว้ก่อนถ้าไม่มีข้อมูล)
              // ElevatedButton.icon(
              //   onPressed: () {},
              //   icon: const Icon(Icons.facebook, color: Colors.white, size: 18),
              //   label: const Text('Facebook', style: TextStyle(fontSize: 14)),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.blue,
              //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(20),
              //     ),
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 16),
          // ✅ ที่อยู่จาก API
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  market.address,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ✅ เวลาทำการจาก API
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'เปิดทุกวัน ${market.formattedTime}',
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ✅ เบอร์โทรจาก API
          if (market.phone.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.phone_android, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(market.phone, style: const TextStyle(fontSize: 15)),
              ],
            ),
          const SizedBox(height: 12),

          // ✅ ปุ่มโทรจริง
          ElevatedButton.icon(
            onPressed: market.phone.isNotEmpty
                ? () => _makePhoneCall(market.phone)
                : null,
            icon: const Icon(Icons.phone, color: Colors.white, size: 18),
            label: const Text('ติดต่อร้าน', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTab(Market market, List<Review> reviews) {
    return Padding(
      key: _reviewKey,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              Text(
                market.ratingAvgDouble.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${market.reviewsCount} เรตติ้ง',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRatingBar(market),
          const SizedBox(height: 16),
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'ยังไม่มีรีวิว',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            ...reviews.map((review) => _buildReviewItem(review)).toList(),
        ],
      ),
    );
  }

  Widget _buildRatingBar(Market market) {
    final maxCount = market.totalRatings > 0 ? market.totalRatings : 1;

    return Column(
      children: [
        _buildStarRow(5, market.rating5Count, maxCount),
        _buildStarRow(4, market.rating4Count, maxCount),
        _buildStarRow(3, market.rating3Count, maxCount),
        _buildStarRow(2, market.rating2Count, maxCount),
        _buildStarRow(1, market.rating1Count, maxCount),
      ],
    );
  }

  Widget _buildStarRow(int stars, int count, int maxCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(
                  stars,
                  (index) =>
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              Text(count.toString()),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: maxCount > 0 ? count / maxCount : 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: review.reviewerPhoto.isNotEmpty
                    ? NetworkImage(review.reviewerPhoto)
                    : null,
                backgroundColor: Colors.grey[300],
                child: review.reviewerPhoto.isEmpty
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      review.formattedDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              review.rating,
              (index) => const Icon(Icons.star, color: Colors.amber, size: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(review.comment, style: const TextStyle(fontSize: 14)),
          const Divider(height: 24),
        ],
      ),
    );
  }
}
