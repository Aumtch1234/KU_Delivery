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
      return Center(child: Text('Error: ${controller.error}'));
    }
    if (d == null) return const Center(child: Text('ไม่มีข้อมูล'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'ยอดขายรวม',
                  value: '฿${nf.format(d.totalRevenue)}',
                  icon: Icons.attach_money,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  title: 'จำนวนออเดอร์',
                  value: '${d.totalOrders}',
                  icon: Icons.shopping_cart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'ค่าเฉลี่ยต่อออเดอร์',
                  value: '฿${nf.format(d.avgOrderValue)}',
                  icon: Icons.analytics,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  title: 'ชั่วโมงพีค',
                  value: d.peakHour != null ? '${d.peakHour}:00' : 'ไม่มี',
                  icon: Icons.access_time,
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
                          child: Text('${h.hour}'),
                        ),
                        title: Text('${h.orders} ออเดอร์'),
                        trailing: Text('฿${nf.format(h.revenue)}'),
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
                      return ListTile(
                        leading: Icon(
                          entry.key.contains('cash')
                              ? Icons.money
                              : Icons.credit_card,
                          color: Colors.green,
                        ),
                        title: Text(entry.key),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('฿${nf.format(entry.value)}'),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
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
                    children: d.menuItemsSold.entries.map((entry) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Text('${entry.value}'),
                        ),
                        title: Text(entry.key),
                        trailing: Text('${entry.value} ชิ้น'),
                      );
                    }).toList(),
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
      return Center(child: Text('Error: ${controller.error}'));
    }
    if (m == null) return const Center(child: Text('ไม่มีข้อมูล'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'ยอดขายรวม (เดือน)',
                  value: '฿${nf.format(m.totalRevenue)}',
                  icon: Icons.attach_money,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  title: 'จำนวนออเดอร์',
                  value: '${m.totalOrders}',
                  icon: Icons.shopping_cart,
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
                          child: Text('${d.date.day}'),
                        ),
                        title: Text(DateFormat('dd/MM/yyyy').format(d.date)),
                        subtitle: Text('${d.orders} ออเดอร์'),
                        trailing: Text('฿${nf.format(d.revenue)}'),
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
      return Center(child: Text('Error: ${controller.error}'));
    }
    if (y == null) return const Center(child: Text('ไม่มีข้อมูล'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'ยอดขายรวม (ปี)',
                  value: '฿${nf.format(y.totalRevenue)}',
                  icon: Icons.attach_money,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  title: 'จำนวนออเดอร์',
                  value: '${y.totalOrders}',
                  icon: Icons.shopping_cart,
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
                          child: Text('${m.month}'),
                        ),
                        title: Text('เดือน ${m.month}/${y.year}'),
                        subtitle: Text('${m.orders} ออเดอร์'),
                        trailing: Text('฿${nf.format(m.revenue)}'),
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

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
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
