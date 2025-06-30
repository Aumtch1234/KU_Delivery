import 'package:flutter/material.dart';

class StoreDetailPage extends StatefulWidget {
  final String storeName;

  const StoreDetailPage({Key? key, required this.storeName}) : super(key: key);

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  final GlobalKey _reviewKey = GlobalKey();
  final GlobalKey _infoKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  int _tabIndex = 0;

  // For scroll detection
  bool _isScrollListenerAttached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isScrollListenerAttached) {
      _scrollController.addListener(_onScroll);
      _isScrollListenerAttached = true;
    }
  }

  void _onScroll() {
    // Get positions of info and review
    final infoBox = _infoKey.currentContext?.findRenderObject() as RenderBox?;
    final reviewBox =
        _reviewKey.currentContext?.findRenderObject() as RenderBox?;
    if (infoBox == null || reviewBox == null) return;

    // Get the offset of each section relative to the scrollable
    final scrollBox = context.findRenderObject() as RenderBox?;
    if (scrollBox == null) return;

    final infoOffset = infoBox
        .localToGlobal(Offset.zero, ancestor: scrollBox)
        .dy;
    final reviewOffset = reviewBox
        .localToGlobal(Offset.zero, ancestor: scrollBox)
        .dy;

    // The threshold is when the review section is at or above the top bar
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
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
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
        title: Text(
          'รายละเอียดร้านอาหาร',
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
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
                            _infoKey.currentContext!.findRenderObject()
                                as RenderBox;
                        final scrollBox =
                            context.findRenderObject() as RenderBox?;
                        if (scrollBox != null) {
                          final offset =
                              box
                                  .localToGlobal(
                                    Offset.zero,
                                    ancestor: scrollBox,
                                  )
                                  .dy +
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
                            color: _tabIndex == 0
                                ? Colors.green
                                : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 2,
                          color: _tabIndex == 0
                              ? Colors.green
                              : Colors.transparent,
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
                        final scrollBox =
                            context.findRenderObject() as RenderBox?;
                        if (scrollBox != null) {
                          final offset =
                              box
                                  .localToGlobal(
                                    Offset.zero,
                                    ancestor: scrollBox,
                                  )
                                  .dy +
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
                            color: _tabIndex == 1
                                ? Colors.green
                                : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 2,
                          color: _tabIndex == 1
                              ? Colors.green
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoTab(),
                  const Divider(height: 32, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'รีวิว',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  _buildReviewTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return Padding(
      key: _infoKey,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/menus/kai.png',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.storeName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.phone, color: Colors.white),
                label: const Text('ติดต่อร้าน'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.facebook, color: Colors.white),
                label: const Text('facebook'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(Icons.location_on, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'เชียงเครือ เมืองสกลนคร สกลนคร',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.access_time, color: Colors.green),
              SizedBox(width: 8),
              Text('ทุกวัน เวลา 9:30 - 22:00', style: TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTab() {
    return Padding(
      key: _reviewKey,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.star, color: Colors.amber, size: 32),
              SizedBox(width: 8),
              Text(
                '4.5',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Text('613 เรตติ้ง', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          _buildRatingBar(),
          const SizedBox(height: 16),
          _buildReviewItem(
            'สมรักษ์',
            'ข้าวนุ่มเหมือนกำลังเคี้ยวน้ำ HD',
            5,
            '20 ก.พ 68',
          ),
          _buildReviewItem(
            'ธนกวย คงควรทอง',
            'โปรดสั่งเสีย ก่อนสั่งซื้อ 👋',
            5,
            '13 ก.พ 68',
          ),
          _buildReviewItem('ฮองเฮา', 'คำแนะนำดีใจ คำต่อไปติดคอ', 4, '9 ก.พ 68'),
          _buildReviewItem(
            'มาสไรเดอร์ที่ผ่านทางมา',
            'ซื้อเป็นร้อย ก็ยังน้อยอยู่ดี 😂',
            4,
            '19 ม.ค 68',
          ),
          _buildReviewItem(
            'เทพลิ้นพัฒนาอาหารผู้มีสไตล์',
            'อาหารจานด่วน มาแค่จาน อาหารรอค่อน',
            3,
            '1 ม.ค 68',
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar() {
    return Column(
      children: [
        _buildStarRow(5, 500),
        _buildStarRow(4, 50),
        _buildStarRow(3, 26),
        _buildStarRow(2, 32),
        _buildStarRow(1, 5),
      ],
    );
  }

  Widget _buildStarRow(int stars, int count) {
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
              widthFactor: count / 500,
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

  Widget _buildReviewItem(String name, String comment, int stars, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(date, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          Row(
            children: List.generate(
              stars,
              (index) => const Icon(Icons.star, color: Colors.amber, size: 16),
            ),
          ),
          Text(comment),
        ],
      ),
    );
  }
}
