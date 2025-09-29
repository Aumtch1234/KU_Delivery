# แก้ไขปัญหาการดึงราคาต้นทุนจริงจากฐานข้อมูล

## ปัญหาที่พบ:
1. **original_price และ original_subtotal** ในตาราง order_items ไม่ได้ดึงราคาต้นทุนจริงจากตาราง foods คอลัมน์ price
2. **original_options** ไม่ได้ดึงจากคอลัมน์ options ในตาราง foods (ที่ยังไม่บวก%เพิ่ม)
3. **original_total_price** ในตาราง orders ไม่ได้คำนวณจากสูตร `price + options` จริง

## การแก้ไข:

### 1. อัปเดต Backend (ordersController.js)
```javascript
// เพิ่มการดึงข้อมูลจริงจากตาราง foods
const foodRes = await client.query(
  'SELECT price, options FROM foods WHERE food_id = $1',
  [item.food_id]
);

const originalPrice = parseFloat(foodData.price) || 0;
const originalOptions = foodData.options || [];

// คำนวณราคา options ต้นทุนจริง
let originalOptionsTotal = 0;
if (item.selected_options && item.selected_options.length > 0) {
  for (const selectedOption of item.selected_options) {
    const matchingOption = originalOptions.find(opt => 
      opt.label === selectedOption.label || opt.name === selectedOption.name
    );
    if (matchingOption && matchingOption.extraPrice) {
      originalOptionsTotal += parseFloat(matchingOption.extraPrice) || 0;
    }
  }
}

// คำนวณราคาต้นทุนรวม
const originalSubtotal = (originalPrice + originalOptionsTotal) * item.quantity;
calculatedOriginalTotal += originalSubtotal;
```

### 2. อัปเดต Models (order_model.dart)
- เพิ่มฟิลด์ `originalTotalPrice` ใน Order class
- เพิ่มฟิลด์ `originalPrice`, `originalSubtotal`, `originalOptions` ใน OrderItem class
- อัปเดต fromJson, toJson, และ copyWith methods

### 3. อัปเดต UI (OrdersListPage.dart)
- แสดงราคาต้นทุนจริงจากฐานข้อมูลแทนการคำนวณ 85%
- เพิ่มการตรวจสอบ null เพื่อ fallback ไปใช้การคำนวณเดิมถ้าไม่มีข้อมูล

## วิธีการทำงาน:

### การสร้างออเดอร์:
1. **ดึงข้อมูลต้นทุน**: ระบบจะ query ไปที่ตาราง `foods` เพื่อดึง `price` และ `options` จริง
2. **คำนวณ options**: จับคู่ options ที่ลูกค้าเลือกกับ options ต้นทุนในฐานข้อมูล
3. **คำนวณราคารวม**: `original_price = price + options_total`, `original_subtotal = original_price * quantity`
4. **อัปเดต orders**: อัปเดต `original_total_price` ด้วยผลรวมของ `original_subtotal` ทุกรายการ

### การแสดงผล:
1. **ราคาต้นทุนต่อรายการ**: แสดง `original_price` และ `original_subtotal` จากฐานข้อมูล
2. **ราคาต้นทุนรวม**: แสดง `original_total_price` จากฐานข้อมูล
3. **Fallback**: ถ้าไม่มีข้อมูลใหม่ จะใช้การคำนวณ 85% เดิม

## สูตรคำนวณ:
```
original_price = foods.price + sum(selected_options.extraPrice)
original_subtotal = original_price * quantity
original_total_price = sum(all_original_subtotal) // ไม่รวมค่าส่ง
```

## การทดสอบ:
1. รัน SQL script `add_original_price_columns.sql` ก่อน
2. สร้างออเดอร์ใหม่ผ่านแอพ
3. ตรวจสอบว่าในฐานข้อมูล:
   - `order_items.original_price` = ราคาจริงจาก `foods.price` + options
   - `order_items.original_subtotal` = original_price * quantity
   - `order_items.original_options` = ข้อมูลจาก `foods.options`
   - `orders.original_total_price` = ผลรวม original_subtotal ทุกรายการ

## ข้อดี:
- ✅ ดึงราคาต้นทุนจริงจากฐานข้อมูล
- ✅ คำนวณ options ต้นทุนจริง
- ✅ แสดงกำไรแท้จริง (ไม่ใช่การประมาณ)
- ✅ รองรับออเดอร์เก่าด้วย fallback mechanism