// APIs/Analytics_Dashboard/Market/Dashboard_salesAPIs.dart
import 'dart:convert';
import 'package:delivery/APIs/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../../pages/myMarket/Model/Dashboard_sales_models.dart';

class DashboardSalesController extends ChangeNotifier {
  DailySummary? daily;
  MonthlySummary? monthly;
  YearlySummary? yearly;
  
  bool loading = false;
  String? error;

  Future<void> fetchDaily({required DateTime date, int? marketId}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final d = "${date.toIso8601String().substring(0, 10)}";
      final uri =
          Uri.parse(
            "${ApiConfig.AnalyticsDashboardSalesUrl}/daily-summary",
          ).replace(
            queryParameters: {
              'date': d,
              if (marketId != null) 'market_id': '$marketId',
            },
          );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        daily = DailySummary.fromJson(json.decode(res.body));
      } else {
        error = res.body;
      }
    } catch (e) {
      error = "$e";
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMonthly({
    required int month,
    required int year,
    int? marketId,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final uri =
          Uri.parse(
            "${ApiConfig.AnalyticsDashboardSalesUrl}/monthly-summary",
          ).replace(
            queryParameters: {
              'month': '$month',
              'year': '$year',
              if (marketId != null) 'market_id': '$marketId',
            },
          );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        monthly = MonthlySummary.fromJson(json.decode(res.body));
      } else {
        error = res.body;
      }
    } catch (e) {
      error = "$e";
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchYearly({required int year, int? marketId}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final uri =
          Uri.parse(
            "${ApiConfig.AnalyticsDashboardSalesUrl}/yearly-summary",
          ).replace(
            queryParameters: {
              'year': '$year',
              if (marketId != null) 'market_id': '$marketId',
            },
          );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        yearly = YearlySummary.fromJson(json.decode(res.body));
      } else {
        error = res.body;
      }
    } catch (e) {
      error = "$e";
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
