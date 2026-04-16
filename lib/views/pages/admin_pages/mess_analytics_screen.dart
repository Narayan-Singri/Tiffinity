import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../../services/mess_analytics_service.dart';

class MessAnalyticsScreen extends StatefulWidget {
  final String messId;

  const MessAnalyticsScreen({super.key, required this.messId});

  @override
  State<MessAnalyticsScreen> createState() => _MessAnalyticsScreenState();
}

class _MessAnalyticsScreenState extends State<MessAnalyticsScreen> {
  bool _isLoading = true;
  int _selectedDays = 30; // Default to 30 days

  Map<String, dynamic> _summary = {};
  List<dynamic> _dailyData = [];
  List<dynamic> _statusData = [];
  List<dynamic> _topItems = [];

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _isLoading = true);

    final result = await MessAnalyticsService.getMessAnalytics(
        messId: widget.messId, days: _selectedDays);

    if (result['success'] == true && mounted) {
      setState(() {
        _summary = result['summary'];
        _dailyData = result['daily_data'] ?? [];
        _statusData = result['status_data'] ?? [];
        _topItems = result['top_items'] ?? [];
        _isLoading = false;
      });
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to load data')),
        );
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('EEE, d MMM').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Order Analytics', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          // MODERN DATE FILTER DROPDOWN
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE9FFFA),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFB5E3DB)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedDays,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF00796B), size: 20),
                  style: const TextStyle(color: Color(0xFF00796B), fontWeight: FontWeight.bold, fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('Last 7 Days')),
                    DropdownMenuItem(value: 30, child: Text('Last 30 Days')),
                    DropdownMenuItem(value: 90, child: Text('Last 90 Days')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedDays = val);
                      _fetchAnalytics();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00796B)))
          : RefreshIndicator(
        onRefresh: _fetchAnalytics,
        color: const Color(0xFF00796B),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- 1. TOP SUMMARY CARDS ---
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Total Orders',
                    value: '${_summary['total_orders_period'] ?? 0}',
                    icon: Icons.shopping_bag_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Total Revenue',
                    value: '₹${_summary['total_revenue_period'] ?? 0}',
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- 2. PIE CHART: ORDER STATUS ---
            const Text('Order Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF12403B))),
            const SizedBox(height: 12),
            _buildPieChartCard(),
            const SizedBox(height: 24),

            // --- 3. TOP SELLING DISHES ---
            const Text('Most Selling Dishes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF12403B))),
            const SizedBox(height: 12),
            _buildTopDishesCard(),
            const SizedBox(height: 24),

            // --- 4. DAY BY DAY LIST ---
            const Text('Daily Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF12403B))),
            const SizedBox(height: 12),
            if (_dailyData.isEmpty)
              _buildEmptyStateCard(
                icon: Icons.calendar_month_rounded,
                title: "No Daily Records",
                message: "When you complete orders, your day-by-day earnings will appear here.",
              )
            else
              ..._dailyData.map((day) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFFE9FFFA), borderRadius: BorderRadius.circular(12)),
                        child: Text(_formatDate(day['date']), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00796B))),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${day['orders']} Orders', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('₹${day['revenue']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }

  // =========================================
  // WIDGET BUILDERS
  // =========================================

  Widget _buildSummaryCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTopDishesCard() {
    if (_topItems.isEmpty) {
      // 🌟 PROFESSIONAL EMPTY STATE FOR DISHES
      return _buildEmptyStateCard(
        icon: Icons.restaurant_menu_rounded,
        title: "No Best Sellers Yet",
        message: "Your top 5 most popular dishes will be ranked here once orders start rolling in.",
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: _topItems.map((item) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.restaurant_menu, color: Colors.white, size: 18)),
            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text('${item['quantity']} Sold', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieChartCard() {
    if (_statusData.isEmpty) {
      // 🌟 PROFESSIONAL EMPTY STATE FOR PIE CHART
      return _buildEmptyStateCard(
        icon: Icons.pie_chart_outline_rounded,
        title: "No Chart Data",
        message: "A visual breakdown of your Delivered vs. Cancelled orders will appear here.",
      );
    }

    // Map statuses to specific colors
    List<double> values = [];
    List<Color> colors = [];
    List<Widget> legend = [];

    for (var data in _statusData) {
      values.add((data['count'] as int).toDouble());

      Color c = Colors.grey;
      String status = data['status'];
      if (status == 'delivered') c = Colors.green;
      else if (status == 'cancelled' || status == 'rejected') c = Colors.red;
      else c = Colors.orange; // Pending, accepted, out_for_delivery

      colors.add(c);
      legend.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('${status.toUpperCase()} (${data['count']})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          )
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          SizedBox(
            width: 110, height: 110,
            child: CustomPaint(painter: PieChartPainter(values, colors)),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: legend.map((w) => Padding(padding: const EdgeInsets.only(bottom: 10.0), child: w)).toList(),
            ),
          )
        ],
      ),
    );
  }

  // 🌟 THE NEW EMPTY STATE BUILDER 🌟
  Widget _buildEmptyStateCard({required IconData icon, required String title, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// =========================================
// CUSTOM PIE CHART PAINTER (Zero Dependencies!)
// =========================================
class PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  PieChartPainter(this.values, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    double total = values.fold(0, (a, b) => a + b);
    if (total == 0) return;

    double startAngle = -pi / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    for (int i = 0; i < values.length; i++) {
      double sweepAngle = (values[i] / total) * 2 * pi;
      paint.color = colors[i];
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    // Add a white circle in the middle to make it a "Donut Chart" (Looks much more modern!)
    paint.color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 3.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}