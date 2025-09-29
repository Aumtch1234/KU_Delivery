// lib/pages/myMarket/Model/Dashboard_sales_models.dart

class HourlySale {
  final int hour;
  final int orders;
  final double revenue;
  final double originalRevenue;
  HourlySale({
    required this.hour,
    required this.orders,
    required this.revenue,
    required this.originalRevenue,
  });

  factory HourlySale.fromJson(Map<String, dynamic> j) => HourlySale(
    hour: _toInt(j['hour']),
    orders: _toInt(j['orders']),
    revenue: _toDouble(j['revenue']),
    originalRevenue: _toDouble(j['original_revenue']),
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
  final double totalCostRevenue; // ราคาต้นทุนรวม
  final int totalOrders;
  final Map<String, int> menuItemsSold;
  final Map<String, double> paymentMethods;
  final double avgOrderValue;
  final double avgCostOrderValue; // ค่าเฉลี่ยต้นทุนต่ออเดอร์
  final int? peakHour;
  final List<HourlySale> hourlySales;

  DailySummary({
    required this.date,
    this.marketId,
    required this.totalRevenue,
    required this.totalCostRevenue,
    required this.totalOrders,
    required this.menuItemsSold,
    required this.paymentMethods,
    required this.avgOrderValue,
    required this.avgCostOrderValue,
    required this.peakHour,
    required this.hourlySales,
  });

  factory DailySummary.fromJson(Map<String, dynamic> j) {
    final revenue = _toDouble(j['total_revenue']);
    final costRevenue = _toDouble(j['original_total_revenue']) != 0
        ? _toDouble(j['original_total_revenue'])
        : revenue * 0.85;
    final orders = _toInt(j['total_orders']);
    final avgValue = _toDouble(j['avg_order_value']) != 0
        ? _toDouble(j['avg_order_value'])
        : (orders > 0 ? revenue / orders : 0.0);
    final avgCostValue = _toDouble(j['original_avg_order_value']) != 0
        ? _toDouble(j['original_avg_order_value'])
        : (orders > 0 ? costRevenue / orders : 0.0);

    return DailySummary(
      date: j['date']?.toString() ?? '',
      marketId: _toInt(j['market_id']),
      totalRevenue: revenue,
      totalCostRevenue: costRevenue,
      totalOrders: orders,
      menuItemsSold: _parseMenuItems(j['menu_items_sold']),
      paymentMethods: _parsePaymentMethods(j['payment_methods']),
      avgOrderValue: avgValue,
      avgCostOrderValue: avgCostValue,
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
  final double totalCostRevenue; // ราคาต้นทุนรวม
  final int totalOrders;
  final List<MonthlyDayPoint> daily;

  MonthlySummary({
    required this.month,
    required this.year,
    this.marketId,
    required this.totalRevenue,
    required this.totalCostRevenue,
    required this.totalOrders,
    required this.daily,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> j) {
    final List days = j['daily_sales_data'] ?? j['daily'] ?? [];

    // Use correct API field names from monthly-summary response
    final revenue = _toDouble(j['total_monthly_revenue']);
    final costRevenue = _toDouble(j['original_total_monthly_revenue']) != 0
        ? _toDouble(j['original_total_monthly_revenue'])
        : revenue * 0.85;
    final orders = _toInt(j['total_monthly_orders']);

    return MonthlySummary(
      month: _toInt(j['month']),
      year: _toInt(j['year']),
      marketId: _toInt(j['market_id']),
      totalRevenue: revenue,
      totalCostRevenue: costRevenue,
      totalOrders: orders,
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
  final double totalCostRevenue; // ราคาต้นทุนรวม
  final int totalOrders;
  final double avgOrderValue;
  final double avgCostOrderValue; // ค่าเฉลี่ยต้นทุนต่ออเดอร์
  final Map<String, double> paymentMethods;
  final List<Map<String, dynamic>> topItems; // [{food_name, qty}]
  final List<YearlyMonthPoint> monthlyData;

  YearlySummary({
    required this.year,
    this.marketId,
    required this.totalRevenue,
    required this.totalCostRevenue,
    required this.totalOrders,
    required this.avgOrderValue,
    required this.avgCostOrderValue,
    required this.paymentMethods,
    required this.topItems,
    required this.monthlyData,
  });

  factory YearlySummary.fromJson(Map<String, dynamic> j) {
    final List md = j['monthly_sales_data'] ?? j['monthly_data'] ?? [];

    // Use correct API field names from yearly-summary response
    final revenue = _toDouble(j['total_yearly_revenue']);
    final costRevenue = _toDouble(j['original_total_yearly_revenue']) != 0
        ? _toDouble(j['original_total_yearly_revenue'])
        : revenue * 0.85;
    final orders = _toInt(j['total_yearly_orders']);

    final avgValue = orders > 0 ? revenue / orders : 0.0;
    final avgCostValue = orders > 0 ? costRevenue / orders : 0.0;

    return YearlySummary(
      year: _toInt(j['year']),
      marketId: _toInt(j['market_id']),
      totalRevenue: revenue,
      totalCostRevenue: costRevenue,
      totalOrders: orders,
      avgOrderValue: avgValue,
      avgCostOrderValue: avgCostValue,
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
