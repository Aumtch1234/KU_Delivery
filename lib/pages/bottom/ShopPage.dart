// lib/screens/home_page.dart
import 'package:delivery/pages/store/StoreMenuPage.dart';
import 'package:flutter/material.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: Colors.green.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CSC HD Food',
                  style: TextStyle(
                    fontSize: isTablet ? 28 : size.width * 0.06,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isTablet ? 20 : size.height * 0.015),
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, size: isTablet ? 26 : 20),
                    suffixIcon: Icon(Icons.tune, size: isTablet ? 26 : 20),
                    hintText: 'Search',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: isTablet ? 18 : size.width * 0.045,
                  ),
                ),
                SizedBox(height: isTablet ? 24 : size.height * 0.02),
                Text(
                  "Food That's\nGood For You",
                  style: TextStyle(
                    fontSize: isTablet ? 24 : size.width * 0.05,
                    fontWeight: FontWeight.w600,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                SizedBox(height: isTablet ? 24 : size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'หมวดหมู่อาหาร',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : size.width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'เพิ่มเติม',
                        style: TextStyle(
                          color: Color(0xFF34C759),
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 18 : size.width * 0.04,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 12 : size.height * 0.01),
                // Responsive หมวดหมู่
                SizedBox(
                  height: isTablet ? 120 : size.width * 0.22,
                  child: Center(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(),
                      children: [
                        _buildCategory(
                          size,
                          isTablet,
                          'assets/menus/main.png',
                          'มื้อหลัก',
                        ),
                        _buildCategory(
                          size,
                          isTablet,
                          'assets/menus/main.png',
                          'ก๋วยเตี๋ยว',
                        ),
                        _buildCategory(
                          size,
                          isTablet,
                          'assets/menus/main.png',
                          'เครื่องดื่ม',
                        ),
                        _buildCategory(
                          size,
                          isTablet,
                          'assets/menus/main.png',
                          'ของหวาน',
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 24 : size.height * 0.02),
                Divider(color: Colors.grey),
                SizedBox(height: isTablet ? 24 : size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ร้านค้าที่เข้าร่วม',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : size.width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'เพิ่มเติม',
                        style: TextStyle(
                          color: Color(0xFF34C759),
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 18 : size.width * 0.04,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 12 : size.height * 0.01),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStoreItem(context, size, isTablet, 'ร้านข้าวมันไก่'),
                    _buildStoreItem(context, size, isTablet, 'ร้านก๋วยเตี๋ยว'),
                    _buildStoreItem(
                      context,
                      size,
                      isTablet,
                      'ร้านอาหารตามสั่ง',
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 24 : size.height * 0.02),
                Divider(color: Colors.grey),
                SizedBox(height: isTablet ? 24 : size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'เมนูแนะนำ',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : size.width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'เพิ่มเติม',
                        style: TextStyle(
                          color: Color(0xFF34C759),
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 18 : size.width * 0.04,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 12 : size.height * 0.01),
                // Responsive GridView สำหรับเมนูแนะนำ
                GridView.count(
                  crossAxisCount: isTablet ? 3 : 2,
                  crossAxisSpacing: isTablet ? 24 : 16,
                  mainAxisSpacing: isTablet ? 24 : 16,
                  childAspectRatio: isTablet ? 0.9 : 0.75,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _buildRecommendedMenu(
                      size,
                      isTablet,
                      "ข้าวกระเพรา หมูสับ ผัดพริกแกง ต้มเป็ด",
                      "ร้านอร่อย",
                      "15 นาที",
                      45,
                      'assets/menus/kai.png',
                      5.0,
                    ),
                    _buildRecommendedMenu(
                      size,
                      isTablet,
                      "ข้าวผัด",
                      "ร้านเจ๊หมี",
                      "20 นาที",
                      50,
                      'assets/menus/yam.png',
                      4.0,
                    ),
                    _buildRecommendedMenu(
                      size,
                      isTablet,
                      "ก๋วยเตี๋ยว",
                      "ร้านเตี๋ยวเด็ด",
                      "12 นาที",
                      40,
                      'assets/menus/yam.png',
                      4.0,
                    ),
                    _buildRecommendedMenu(
                      size,
                      isTablet,
                      "ข้าวหมูแดง",
                      "ร้านหมูแดง",
                      "10 นาที",
                      55,
                      'assets/menus/kai.png',
                      4.3,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategory(Size size, bool isTablet, String icon, String label) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : size.width * 0.015,
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: isTablet ? 44 : size.width * 0.08,
            child: Image.asset(icon, height: isTablet ? 32 : size.width * 0.06),
          ),
          SizedBox(height: isTablet ? 8 : size.height * 0.005),
          Text(
            label,
            style: TextStyle(fontSize: isTablet ? 16 : size.width * 0.03),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreItem(
    BuildContext context,
    Size size,
    bool isTablet,
    String name,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreMenuPage(storeName: name),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: isTablet ? 120 : size.width * 0.22,
            height: isTablet ? 120 : size.width * 0.22,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(
                isTablet ? 20 : size.width * 0.04,
              ),
              image: const DecorationImage(
                image: AssetImage('assets/menus/kai.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 8 : size.height * 0.01),
          Text(
            name,
            style: TextStyle(
              fontSize: isTablet ? 16 : size.width * 0.035,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedMenu(
    Size size,
    bool isTablet,
    String title,
    String shop,
    String time,
    double price,
    String imagePath,
    double rating,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 18 : size.width * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 18 : size.width * 0.03),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(
              isTablet ? 12 : size.width * 0.02,
            ),
            child: Stack(
              children: [
                Image.asset(
                  imagePath,
                  height: isTablet ? 120 : size.width * 0.25,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: isTablet ? 12 : size.width * 0.02,
                  right: isTablet ? 12 : size.width * 0.02,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 10 : size.width * 0.015,
                      vertical: isTablet ? 4 : size.width * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF34C759).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(
                        isTablet ? 8 : size.width * 0.015,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.yellow,
                          size: isTablet ? 20 : size.width * 0.035,
                        ),
                        SizedBox(width: isTablet ? 6 : size.width * 0.01),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: isTablet ? 14 : size.width * 0.03,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 12 : size.height * 0.01),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 18 : size.width * 0.04,
            ),
          ),
          SizedBox(height: isTablet ? 6 : size.height * 0.005),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              shop,
              style: TextStyle(
                fontSize: isTablet ? 14 : size.width * 0.03,
                color: Colors.grey,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.timer, size: isTablet ? 18 : size.width * 0.035),
              SizedBox(width: isTablet ? 6 : size.width * 0.01),
              Text(
                time,
                style: TextStyle(fontSize: isTablet ? 14 : size.width * 0.03),
              ),
              const Spacer(),
              Text(
                '\$ $price.-',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: isTablet ? 16 : size.width * 0.035,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
