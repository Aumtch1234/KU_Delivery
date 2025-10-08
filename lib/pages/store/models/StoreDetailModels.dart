// models/StoreDetailModels.dart

class StoreDetailResponse {
  final bool ok;
  final Market market;
  final List<Review> reviews;
  final Paging paging;

  StoreDetailResponse({
    required this.ok,
    required this.market,
    required this.reviews,
    required this.paging,
  });

  factory StoreDetailResponse.fromJson(Map<String, dynamic> json) {
    return StoreDetailResponse(
      ok: json['ok'] ?? false,
      market: Market.fromJson(json['market'] ?? {}),
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((item) => Review.fromJson(item))
              .toList() ??
          [],
      paging: Paging.fromJson(json['paging'] ?? {}),
    );
  }
}

class Market {
  final int marketId;
  final int ownerId;
  final String shopName;
  final String shopDescription;
  final String shopLogoUrl;
  final String createdAt;
  final double latitude;
  final double longitude;
  final String openTime;
  final String closeTime;
  final bool isOpen;
  final bool isManualOverride;
  final String? overrideUntil;
  final String ratingAvg;
  final String address;
  final String phone;
  final bool approve;
  final int adminId;
  final bool isAdmin;
  final int reviewsCount;
  final String rating5;
  final String rating4;
  final String rating3;
  final String rating2;
  final String rating1;

  Market({
    required this.marketId,
    required this.ownerId,
    required this.shopName,
    required this.shopDescription,
    required this.shopLogoUrl,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
    required this.isManualOverride,
    this.overrideUntil,
    required this.ratingAvg,
    required this.address,
    required this.phone,
    required this.approve,
    required this.adminId,
    required this.isAdmin,
    required this.reviewsCount,
    required this.rating5,
    required this.rating4,
    required this.rating3,
    required this.rating2,
    required this.rating1,
  });

  factory Market.fromJson(Map<String, dynamic> json) {
    return Market(
      marketId: json['market_id'] ?? 0,
      ownerId: json['owner_id'] ?? 0,
      shopName: json['shop_name'] ?? '',
      shopDescription: json['shop_description'] ?? '',
      shopLogoUrl: json['shop_logo_url'] ?? '',
      createdAt: json['created_at'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      openTime: json['open_time'] ?? '',
      closeTime: json['close_time'] ?? '',
      isOpen: json['is_open'] ?? false,
      isManualOverride: json['is_manual_override'] ?? false,
      overrideUntil: json['override_until'],
      ratingAvg: json['rating_avg'] ?? '0.0',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      approve: json['approve'] ?? false,
      adminId: json['admin_id'] ?? 0,
      isAdmin: json['is_admin'] ?? false,
      reviewsCount: json['reviews_count'] ?? 0,
      rating5: json['rating_5'] ?? '0',
      rating4: json['rating_4'] ?? '0',
      rating3: json['rating_3'] ?? '0',
      rating2: json['rating_2'] ?? '0',
      rating1: json['rating_1'] ?? '0',
    );
  }

  // Helper getters
  double get ratingAvgDouble => double.tryParse(ratingAvg) ?? 0.0;
  int get rating5Count => int.tryParse(rating5) ?? 0;
  int get rating4Count => int.tryParse(rating4) ?? 0;
  int get rating3Count => int.tryParse(rating3) ?? 0;
  int get rating2Count => int.tryParse(rating2) ?? 0;
  int get rating1Count => int.tryParse(rating1) ?? 0;
  int get totalRatings => rating5Count + rating4Count + rating3Count + rating2Count + rating1Count;

  // แปลงเวลาเป็นรูปแบบไทย เช่น "09:30 - 22:00"
  String get formattedTime {
    if (openTime.isEmpty || closeTime.isEmpty) return 'ไม่ระบุเวลา';
    return '$openTime - $closeTime น.';
  }

  // สถานะเปิด-ปิด
  String get statusText => isOpen ? 'เปิดอยู่' : 'ปิดแล้ว';
}

class Review {
  final int reviewId;
  final int rating;
  final String comment;
  final String createdAt;
  final String reviewerName;
  final String reviewerPhoto;

  Review({
    required this.reviewId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.reviewerName,
    required this.reviewerPhoto,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['review_id'] ?? 0,
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] ?? '',
      reviewerName: json['reviewer_name'] ?? '',
      reviewerPhoto: json['reviewer_photo'] ?? '',
    );
  }

  // แปลงวันที่เป็นรูปแบบไทย เช่น "7 ต.ค. 68"
  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      final thaiMonths = [
        'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
        'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
      ];
      final thaiYear = (date.year + 543).toString().substring(2);
      return '${date.day} ${thaiMonths[date.month - 1]} $thaiYear';
    } catch (e) {
      return '';
    }
  }
}

class Paging {
  final int limit;
  final int offset;

  Paging({
    required this.limit,
    required this.offset,
  });

  factory Paging.fromJson(Map<String, dynamic> json) {
    return Paging(
      limit: json['limit'] ?? 20,
      offset: json['offset'] ?? 0,
    );
  }
}