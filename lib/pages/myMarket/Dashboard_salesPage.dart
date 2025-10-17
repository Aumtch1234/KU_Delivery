import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../APIs/Analytics_Dashboard/Market/Dashboard_salesAPIs.dart';

class DashboardSalesPage extends StatefulWidget {
  final int? marketId;
  const DashboardSalesPage({Key? key, this.marketId}) : super(key: key);

  @override
  State<DashboardSalesPage> createState() => _DashboardSalesPageState();
}

class _DashboardSalesPageState extends State<DashboardSalesPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<DashboardSalesController>();
      controller.fetchDaily(date: _selectedDate, marketId: widget.marketId);
      controller.fetchMonthly(
        month: _selectedMonth,
        year: _selectedYear,
        marketId: widget.marketId,
      );
      controller.fetchYearly(year: _selectedYear, marketId: widget.marketId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardSalesController>();
    final nf = NumberFormat.decimalPattern();

    return Scaffold(
      appBar: AppBar(
        title: const Text('สรุปการขาย'),
        backgroundColor: const Color(0xFF34C759),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'วันนี้'),
            Tab(text: 'เดือนนี้'),
            Tab(text: 'ปีนี้'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
                controller.fetchDaily(date: date, marketId: widget.marketId);
              }
            },
          ),
        ],
      ),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDailyTab(controller, nf),
                _buildMonthlyTab(controller, nf),
                _buildYearlyTab(controller, nf),
              ],
            ),
    );
  }

  Widget _buildDailyTab(DashboardSalesController controller, NumberFormat nf) {
    final d = controller.daily;
    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: ${controller.error}', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.fetchDaily(
                date: _selectedDate,
                marketId: widget.marketId,
              ),
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      );
    }
    if (d == null) return const Center(child: Text('ไม่มีข้อมูล'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary Cards - ราคาต้นทุน
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'ยอดขาย (ต้นทุน)',
                  value: '฿${nf.format(d.totalCostRevenue)}',
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: _SummaryCard(
                  title: 'จำนวนออเดอร์',
                  value: '${d.totalOrders}',
                  icon: Icons.shopping_cart,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'ค่าเฉลี่ย (ต้นทุน)',
                  value: '฿${nf.format(d.avgCostOrderValue)}',
                  icon: Icons.analytics_outlined,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hourly Sales
          _SectionTitle('ยอดขายต่อชั่วโมง'),
          Card(
            child: d.hourlySales.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('ไม่มีข้อมูลยอดขาย')),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: d.hourlySales.length,
                    itemBuilder: (context, index) {
                      final h = d.hourlySales[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            '${h.hour}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          '${h.orders} ออเดอร์',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: Text(
                          '฿${nf.format(h.originalRevenue)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),

          // Payment Methods
          _SectionTitle('วิธีการชำระเงิน'),
          Card(
            child: d.paymentMethods.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('ไม่มีข้อมูลการชำระเงิน')),
                  )
                : Column(
                    children: d.paymentMethods.entries.map((entry) {
                      final total = d.paymentMethods.values.fold(
                        0.0,
                        (a, b) => a + b,
                      );
                      final percentage = total > 0
                          ? (entry.value / total * 100)
                          : 0;
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              entry.key.contains('cash')
                                  ? Icons.money
                                  : Icons.credit_card,
                              color: Colors.green,
                            ),
                          ),
                          title: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '฿${nf.format(entry.value)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // Top Menu Items
          _SectionTitle('เมนูขายดี'),
          Card(
            child: d.menuItemsSold.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('ไม่มีข้อมูลเมนู')),
                  )
                : Column(
                    children: d.menuItemsSold.entries
                        .toList()
                        .asMap()
                        .entries
                        .map((indexedEntry) {
                          final index = indexedEntry.key;
                          final entry = indexedEntry.value;
                          final rankColors = [
                            Colors.amber,
                            Colors.grey,
                            Colors.orange,
                            Colors.blue,
                            Colors.green,
                          ];
                          final rankColor = index < rankColors.length
                              ? rankColors[index]
                              : Colors.grey;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      rankColor.withOpacity(0.8),
                                      rankColor.withOpacity(0.4),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '#${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: rankColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${entry.value} ชิ้น',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: rankColor[900],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTab(
    DashboardSalesController controller,
    NumberFormat nf,
  ) {
    final m = controller.monthly;
    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: ${controller.error}', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.fetchMonthly(
                month: _selectedMonth,
                year: _selectedYear,
                marketId: widget.marketId,
              ),
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      );
    }
    if (m == null) return const Center(child: Text('ไม่มีข้อมูล'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Debug info
          if (m.totalRevenue == 0 && m.totalOrders == 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ไม่มีข้อมูลสำหรับเดือน ${m.month}/${m.year}',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'ยอดขาย (ต้นทุน)',
                  value: '฿${nf.format(m.totalCostRevenue)}',
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'จำนวนออเดอร์',
                  value: '${m.totalOrders}',
                  icon: Icons.shopping_cart,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _SectionTitle('ยอดขายรายวัน'),
          Card(
            child: m.daily.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('ไม่มีข้อมูลยอดขายรายวัน')),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: m.daily.length,
                    itemBuilder: (context, index) {
                      final d = m.daily[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            '${d.date.day}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          DateFormat('dd/MM/yyyy').format(d.date),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text('${d.orders} ออเดอร์'),
                        trailing: Text(
                          '฿${nf.format(d.original_revenue)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyTab(DashboardSalesController controller, NumberFormat nf) {
    final y = controller.yearly;
    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: ${controller.error}', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.fetchYearly(
                year: _selectedYear,
                marketId: widget.marketId,
              ),
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      );
    }
    if (y == null) return const Center(child: Text('ไม่มีข้อมูล'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Debug info
          if (y.totalRevenue == 0 && y.totalOrders == 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ไม่มีข้อมูลสำหรับปี ${y.year}',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'ยอดขาย (ต้นทุน)',
                  value: '฿${nf.format(y.totalCostRevenue)}',
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'จำนวนออเดอร์',
                  value: '${y.totalOrders}',
                  icon: Icons.shopping_cart,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _SectionTitle('ยอดขายรายเดือน'),
          Card(
            child: y.monthlyData.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('ไม่มีข้อมูลยอดขายรายเดือน')),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: y.monthlyData.length,
                    itemBuilder: (context, index) {
                      final m = y.monthlyData[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          child: Text(
                            '${m.month}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          'เดือน ${m.month}/${y.year}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text('${m.orders} ออเดอร์'),
                        trailing: Text(
                          '฿${nf.format(m.original_revenue)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Colors.green;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cardColor.withOpacity(0.1), cardColor.withOpacity(0.05)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: cardColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
