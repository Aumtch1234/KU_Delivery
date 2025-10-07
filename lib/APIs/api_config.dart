class ApiConfig {
  static const String baseUrl = "http://192.168.1.113:4000/client";
  static const String SocketUrl = "http://192.168.1.113:4000/socket";
  static const String SocketChatUrl = "http://192.168.1.113:4000";
  static const String HosttUrl = "http://192.168.1.113:4000";
  static const String AnalyticsDashboardSalesUrl =
      "http://192.168.1.113:4000/dashboard/sales";
  // ✅ Function สำหรับดึงเฉพาะ base ที่ไม่ผูก /client เผื่อใช้ใน route อื่น ๆ
  static const String baseHost = "http://192.168.1.113:4000";
}
