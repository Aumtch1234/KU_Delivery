// lib/pages/myMarket/Model/Dashboard_sales_models.dart

class HourlySale {
  final int hour;
  final int orders;
  final double revenue;
  HourlySale({required this.hour, required this.orders, required this.revenue});

  factory HourlySale.fromJson(Map<String, dynamic> j) => HourlySale(
    hour: _toInt(j['hour']),
    orders: _toInt(j['orders']),
    revenue: _toDouble(j['revenue']),
  );

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class DailySummary {
  final String date;
  final int? marketId;
  final double totalRevenue;
  final int totalOrders;
  final Map<String, int> menuItemsSold;
  final Map<String, double> paymentMethods;
  final double avgOrderValue;
  final int? peakHour;
  final List<HourlySale> hourlySales;

  DailySummary({
    required this.date,
    this.marketId,
    required this.totalRevenue,
    required this.totalOrders,
    required this.menuItemsSold,
    required this.paymentMethods,
    required this.avgOrderValue,
    required this.peakHour,
    required this.hourlySales,
  });

  factory DailySummary.fromJson(Map<String, dynamic> j) {
    return DailySummary(
      date: j['date']?.toString() ?? '',
      marketId: _toInt(j['market_id']),
      totalRevenue: _toDouble(j['total_revenue']),
      totalOrders: _toInt(j['total_orders']),
      menuItemsSold: _parseMenuItems(j['menu_items_sold']),
      paymentMethods: _parsePaymentMethods(j['payment_methods']),
      avgOrderValue: _toDouble(j['avg_order_value']),
      peakHour: j['peak_hour'] != null ? _toInt(j['peak_hour']['hour']) : null,
      hourlySales: _parseHourlySales(j['hourly_sales']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static Map<String, int> _parseMenuItems(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _toInt(v)));
    }
    return {};
  }

  static Map<String, double> _parsePaymentMethods(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _toDouble(v)));
    }
    return {};
  }

  static List<HourlySale> _parseHourlySales(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((x) => HourlySale.fromJson(Map<String, dynamic>.from(x ?? {})))
          .toList();
    }
    return [];
  }
}

class MonthlyDayPoint {
  final DateTime date;
  final int orders;
  final double revenue;
  MonthlyDayPoint({
    required this.date,
    required this.orders,
    required this.revenue,
  });
}

class MonthlySummary {
  final int month;
  final int year;
  final int? marketId;
  final double totalRevenue;
  final int totalOrders;
  final List<MonthlyDayPoint> daily;

  MonthlySummary({
    required this.month,
    required this.year,
    this.marketId,
    required this.totalRevenue,
    required this.totalOrders,
    required this.daily,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> j) {
    final List days = j['daily_sales_data'] ?? [];
    return MonthlySummary(
      month: _toInt(j['month']),
      year: _toInt(j['year']),
      marketId: _toInt(j['market_id']),
      totalRevenue: _toDouble(j['total_monthly_revenue']),
      totalOrders: _toInt(j['total_monthly_orders']),
      daily: days.map((x) {
        final m = Map<String, dynamic>.from(x);
        return MonthlyDayPoint(
          date:
              DateTime.tryParse(m['date']?.toString() ?? '') ?? DateTime.now(),
          orders: _toInt(m['orders']),
          revenue: _toDouble(m['revenue']),
        );
      }).toList(),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class YearlyMonthPoint {
  final int month; // 1..12
  final int orders;
  final double revenue;
  YearlyMonthPoint({
    required this.month,
    required this.orders,
    required this.revenue,
  });
}

class YearlySummary {
  final int year;
  final int? marketId;
  final double totalRevenue;
  final int totalOrders;
  final double avgOrderValue;
  final Map<String, double> paymentMethods;
  final List<Map<String, dynamic>> topItems; // [{food_name, qty}]
  final List<YearlyMonthPoint> monthlyData;

  YearlySummary({
    required this.year,
    this.marketId,
    required this.totalRevenue,
    required this.totalOrders,
    required this.avgOrderValue,
    required this.paymentMethods,
    required this.topItems,
    required this.monthlyData,
  });

  factory YearlySummary.fromJson(Map<String, dynamic> j) {
    final List md = j['monthly_sales_data'] ?? [];
    return YearlySummary(
      year: _toInt(j['year']),
      marketId: _toInt(j['market_id']),
      totalRevenue: _toDouble(j['total_yearly_revenue']),
      totalOrders: _toInt(j['total_yearly_orders']),
      avgOrderValue: _toDouble(j['avg_order_value']),
      paymentMethods: _parsePaymentMethods(j['payment_methods']),
      topItems: _parseTopItems(j['top_items']),
      monthlyData: md.map((x) {
        final m = Map<String, dynamic>.from(x);
        return YearlyMonthPoint(
          month: _toInt(m['month']),
          orders: _toInt(m['orders']),
          revenue: _toDouble(m['revenue']),
        );
      }).toList(),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static Map<String, double> _parsePaymentMethods(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _toDouble(v)));
    }
    return {};
  }

  static List<Map<String, dynamic>> _parseTopItems(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((x) => Map<String, dynamic>.from(x ?? {})).toList();
    }
    return [];
  }
}
