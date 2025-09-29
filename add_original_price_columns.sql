-- SQL สำหรับเพิ่มคอลัมน์ราคาต้นทุน (ยังไม่บวก%เพิ่ม)
-- ใช้คำสั่งนี้เพื่ออัปเดตโครงสร้างฐานข้อมูล

-- เพิ่มคอลัมน์ในตาราง order_items
ALTER TABLE public.order_items 
ADD COLUMN original_price numeric(10,2) DEFAULT 0.00,
ADD COLUMN original_subtotal numeric(10,2) DEFAULT 0.00,
ADD COLUMN original_options jsonb DEFAULT '[]'::jsonb;

-- เพิ่มคำอธิบายคอลัมน์
COMMENT ON COLUMN public.order_items.original_price IS 'ราคาต้นทุนก่อนบวก%เพิ่ม';
COMMENT ON COLUMN public.order_items.original_subtotal IS 'ราคารวมต้นทุนก่อนบวก%เพิ่ม (original_price * quantity)';
COMMENT ON COLUMN public.order_items.original_options IS 'ตัวเลือกอาหารราคาต้นทุนก่อนบวก%เพิ่ม';

-- เพิ่มคอลัมน์ในตาราง orders
ALTER TABLE public.orders 
ADD COLUMN original_total_price numeric(10,2) DEFAULT 0.00;

-- เพิ่มคำอธิบายคอลัมน์
COMMENT ON COLUMN public.orders.original_total_price IS 'ราคารวมต้นทุนก่อนบวก%เพิ่ม (ไม่รวมค่าส่ง)';

-- อัปเดตข้อมูลเดิม (ถ้ามี) โดยใช้สัดส่วนจากราคาปัจจุบัน
-- สมมติว่า GP 15% = ราคาต้นทุน 85% ของราคาขาย
-- คุณสามารถปรับสูตรนี้ตามความเหมาะสม

UPDATE public.order_items 
SET 
    original_price = sell_price * 0.85,
    original_subtotal = subtotal * 0.85
WHERE original_price = 0.00;

UPDATE public.orders 
SET original_total_price = (total_price - delivery_fee) * 0.85
WHERE original_total_price = 0.00;

-- สร้าง Index เพื่อประสิทธิภาพ
CREATE INDEX idx_order_items_original_price ON public.order_items(original_price);
CREATE INDEX idx_orders_original_total_price ON public.orders(original_total_price);