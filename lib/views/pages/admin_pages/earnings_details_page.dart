import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Tiffinity/services/order_service.dart';

class EarningsDetailsPage extends StatefulWidget {
  final String messId;

  const EarningsDetailsPage({super.key, required this.messId});

  @override
  State<EarningsDetailsPage> createState() => _EarningsDetailsPageState();
}

class _EarningsDetailsPageState extends State<EarningsDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _dateRange;
  bool _isLoading = false;

  List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> _filteredOrders = []; // ✅ Added to strictly hold filtered orders
  double _totalCompletedAmount = 0;

  final _dateFormat = DateFormat('dd MMM yyyy');

  Color get primaryColor => const Color(0xFF1B5450);
  Color get accentColor => const Color(0xFF00C04B);
  Color get bgColor => const Color(0xFFF3F6FA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final now = DateTime.now();
    // Default to Today
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day),
    );

    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await OrderService.getMessOrders(int.parse(widget.messId));
      if (mounted) {
        setState(() {
          _allOrders = List<Map<String, dynamic>>.from(orders);
          _isLoading = false;
        });
        _applyFilters(); // ✅ Call our new strict filter logic
      }
    } catch (e) {
      debugPrint("Error loading earnings: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ New method that strictly filters list AND total by the Date Range
  void _applyFilters() {
    if (_dateRange == null) return;

    // Start of the day (00:00:00)
    DateTime start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
    // End of the day (23:59:59)
    DateTime end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day, 23, 59, 59);

    double total = 0;
    List<Map<String, dynamic>> filtered = [];

    for (var order in _allOrders) {
      if (order['status']?.toString().toLowerCase() == 'delivered') {

        // Grab updated_at, fallback to created_at
        String dateString = order['updated_at']?.toString() ?? order['created_at']?.toString() ?? '';

        if (dateString.isNotEmpty) {
          try {
            DateTime orderDate = DateTime.parse(dateString);

            // Strictly check if the delivery happened inside the selected date boundary
            if (orderDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
                orderDate.isBefore(end.add(const Duration(seconds: 1)))) {
              filtered.add(order);
              total += double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
            }
          } catch (e) {
            debugPrint("Date parse error: $e");
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _filteredOrders = filtered;
        _totalCompletedAmount = total;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
      _applyFilters(); // ✅ Re-apply filters when the date changes!
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Earnings & Settlements'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Top Summary Card
          Container(
            color: primaryColor,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Completed Value',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rs ${_totalCompletedAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _dateRange == null
                              ? 'Select Date Range'
                              : '${_dateFormat.format(_dateRange!.start)} - ${_dateFormat.format(_dateRange!.end)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Completed Orders'),
                Tab(text: 'Settlements'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child:
            _isLoading
                ? Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
                : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(),
                _buildSettlementsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_filteredOrders.isEmpty) { // ✅ Use strictly filtered orders here
      return _buildEmptyState(
        icon: Icons.receipt_long,
        title: 'No Completed Orders',
        subtitle: 'You have no delivered orders for the selected date range.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredOrders.length, // ✅ Use strictly filtered orders
        itemBuilder: (context, index) {
          final order = _filteredOrders[index]; // ✅ Use strictly filtered orders
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildSettlementsList() {
    return _buildEmptyState(
      icon: Icons.account_balance_wallet,
      title: 'No Settlements Found',
      subtitle:
      'Your payouts will appear here once transferred to your bank account.',
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    // Parse order date safely
    final rawDate = order['updated_at']?.toString() ?? order['created_at']?.toString() ?? '';
    String displayDate = 'N/A';
    String displayTime = '';

    if (rawDate.isNotEmpty) {
      try {
        final dt = DateTime.parse(rawDate);
        displayDate = _dateFormat.format(dt);
        displayTime = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Rs ${order['total_amount']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                _buildStatusChip(
                  label: order['status'] ?? 'Completed',
                  color: primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({required String label, required Color color}) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}