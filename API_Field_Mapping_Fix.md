# Dashboard API Field Mapping Fix Summary

## 🔍 **ปัญหาที่พบ (Problem Found)**

จาก API Response: `original_total_revenue: 180.00`  
แต่ใน UI แสดง: `฿178.5`

**สาเหตุ**: Dashboard models ใช้ field name ไม่ตรงกับ API response

---

## 🛠️ **การแก้ไขที่ทำไป (Fixes Applied)**

### 1. **DailySummary Model**
**Before:**
```dart
totalCostRevenue: _toDouble(j['total_cost_revenue'])
avgCostOrderValue: _toDouble(j['avg_cost_order_value'])
```

**After:**
```dart
totalCostRevenue: _toDouble(j['original_total_revenue'])  // ✅ ตรงกับ API
avgCostOrderValue: _toDouble(j['original_avg_order_value'])  // ✅ ตรงกับ API
```

### 2. **MonthlySummary Model**
**Before:**
```dart
totalRevenue: _toDouble(j['total_monthly_revenue'])
totalCostRevenue: _toDouble(j['total_monthly_cost_revenue'])
totalOrders: _toInt(j['total_monthly_orders'])
```

**After:**
```dart
totalRevenue: _toDouble(j['total_revenue'])  // ✅ ตรงกับ API
totalCostRevenue: _toDouble(j['original_total_revenue'])  // ✅ ตรงกับ API
totalOrders: _toInt(j['total_orders'])  // ✅ ตรงกับ API
```

### 3. **YearlySummary Model**
**Before:**
```dart
totalRevenue: _toDouble(j['total_yearly_revenue'])
totalCostRevenue: _toDouble(j['total_yearly_cost_revenue'])
totalOrders: _toInt(j['total_yearly_orders'])
avgCostOrderValue: _toDouble(j['avg_cost_order_value'])
```

**After:**
```dart
totalRevenue: _toDouble(j['total_revenue'])  // ✅ ตรงกับ API
totalCostRevenue: _toDouble(j['original_total_revenue'])  // ✅ ตรงกับ API
totalOrders: _toInt(j['total_orders'])  // ✅ ตรงกับ API
avgCostOrderValue: _toDouble(j['original_avg_order_value'])  // ✅ ตรงกับ API
```

### 4. **HourlySale Model Enhancement**
**Added:**
```dart
class HourlySale {
  final int hour;
  final int orders;
  final double revenue;
  final double originalRevenue;  // ✅ เพิ่ม field ใหม่
  
  factory HourlySale.fromJson(Map<String, dynamic> j) => HourlySale(
    hour: _toInt(j['hour']),
    orders: _toInt(j['orders']),
    revenue: _toDouble(j['revenue']),
    originalRevenue: _toDouble(j['original_revenue']),  // ✅ ดึงจาก API
  );
}
```

### 5. **Dashboard UI Update**
**Before:**
```dart
final estimatedCost = h.revenue * 0.85; // ประมาณการ
Text('กำไร: ฿${nf.format(h.revenue - estimatedCost)}')
Text('ต้นทุน: ฿${nf.format(estimatedCost)}')
```

**After:**
```dart
Text('กำไร: ฿${nf.format(h.revenue - h.originalRevenue)}')  // ✅ ใช้ข้อมูลจริง
Text('ต้นทุน: ฿${nf.format(h.originalRevenue)}')  // ✅ ใช้ข้อมูลจริง
```

---

## 📊 **API Field Mapping ที่ถูกต้อง**

### API Response Fields:
```json
{
  "total_revenue": 210.00,           // ยอดขายรวม (ราคาขาย)
  "original_total_revenue": 180.00,  // ยอดขายรวม (ต้นทุน)
  "total_orders": 1,                 // จำนวนออเดอร์
  "avg_order_value": 210,            // ค่าเฉลี่ย (ขาย)  
  "original_avg_order_value": 180,   // ค่าเฉลี่ย (ต้นทุน)
  "hourly_sales": [
    {
      "hour": 18,
      "orders": 1,
      "revenue": 210.00,             // ยอดขาย (ราคาขาย)
      "original_revenue": 180.00     // ยอดขาย (ต้นทุน)
    }
  ]
}
```

### Model Field Mapping:
```dart
// DailySummary
totalRevenue -> j['total_revenue']                    // ✅
totalCostRevenue -> j['original_total_revenue']       // ✅
avgOrderValue -> j['avg_order_value']                 // ✅
avgCostOrderValue -> j['original_avg_order_value']    // ✅

// HourlySale  
revenue -> j['revenue']                               // ✅
originalRevenue -> j['original_revenue']              // ✅
```

---

## ✅ **ผลลัพธ์**

1. **ข้อมูลต้นทุนถูกต้อง**: UI จะแสดง `฿180.00` แทน `฿178.5`
2. **ข้อมูลกำไรถูกต้อง**: การคำนวณกำไร = ราคาขาย - ต้นทุนจริง
3. **ข้อมูล Hourly Sales ถูกต้อง**: ใช้ original_revenue จาก API แทนการประมาณการ
4. **ความสอดคล้อง**: Field mapping ตรงกับ API structure 100%

---

## 📁 **ไฟล์ที่แก้ไข**

1. `lib/pages/myMarket/Model/Dashboard_sales_models.dart`
   - DailySummary.fromJson()
   - MonthlySummary.fromJson() 
   - YearlySummary.fromJson()
   - HourlySale class

2. `lib/pages/myMarket/Dashboard_salesPage.dart`
   - Hourly sales display logic

---

**สถานะ**: ✅ แก้ไขเสร็จสมบูรณ์  
**ทดสอบ**: ตรวจสอบแล้วไม่มี compilation errors  
**ผลลัพธ์**: UI จะแสดงข้อมูลต้นทุนตรงกับ API response (`฿180.00`)