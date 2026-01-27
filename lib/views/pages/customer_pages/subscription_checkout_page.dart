import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Tiffinity/services/api_service.dart';
import 'package:Tiffinity/services/subscription_service.dart';

class SubscriptionCheckoutPage extends StatefulWidget {
  final int messId;
  final String messName;
  final int planId;
  final DateTime startDate;
  final DateTime endDate;
  final int selectedDays;
  final double totalAmount;
  final List<Map<String, dynamic>> selectedItems;

  const SubscriptionCheckoutPage({
    super.key,
    required this.messId,
    required this.messName,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.selectedDays,
    required this.totalAmount,
    required this.selectedItems,
  });

  @override
  State<SubscriptionCheckoutPage> createState() =>
      _SubscriptionCheckoutPageState();
}

class _SubscriptionCheckoutPageState extends State<SubscriptionCheckoutPage> {
  Map<String, dynamic>? _userData;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await ApiService.getUserData();
    setState(() => _userData = data);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _placeOrder() async {
    if (_isPlacingOrder) return;
    if (widget.selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item.')),
      );
      return;
    }

    final userIdValue =
        _userData?['uid'] ?? _userData?['id'] ?? _userData?['user_id'];
    final userId = userIdValue?.toString();

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to find user information.')),
      );
      return;
    }

    final payloadItems =
        widget.selectedItems.map((item) {
          return {
            'id': item['id'],
            'name': item['name'] ?? 'Item',
            'price': item['price'] ?? 0,
            'type': item['type'] ?? 'veg',
            'date': item['menu_date'] ?? '',
            'meal_time': item['meal_time'] ?? 'lunch',
          };
        }).toList();

    setState(() => _isPlacingOrder = true);

    try {
      final response = await SubscriptionService.createSubscriptionOrder(
        userId: userId,
        planId: widget.planId,
        messId: widget.messId,
        startDate: _formatDate(widget.startDate),
        endDate: _formatDate(widget.endDate),
        totalAmount: widget.totalAmount,
        selectedItems: payloadItems,
        customerName: _userData?['name'] ?? _userData?['full_name'],
        customerEmail: _userData?['email'],
        customerPhone: _userData?['phone'],
      );

      final success = response['success'] == true;
      final message =
          response['message']?.toString() ?? 'Order placed successfully';

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        if (success) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateRange =
        '${DateFormat('dd MMM yyyy').format(widget.startDate)} - ${DateFormat('dd MMM yyyy').format(widget.endDate)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.green[400],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(dateRange),
                const SizedBox(height: 12),
                _buildCustomerCard(),
                const SizedBox(height: 12),
                _buildItemsList(),
              ],
            ),
          ),
          _buildFooterButton(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String dateRange) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.store, color: Colors.green[600]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.messName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plan ID: ${widget.planId}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.selectedDays} days',
                  style: TextStyle(color: Colors.green[800]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(dateRange, style: TextStyle(color: Colors.grey[800])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.currency_rupee, size: 20, color: Colors.green[700]),
              const SizedBox(width: 6),
              Text(
                widget.totalAmount.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    final name = _userData?['name'] ?? _userData?['full_name'] ?? 'Customer';
    final email = _userData?['email'] ?? 'No email available';
    final phone = _userData?['phone'] ?? 'No phone available';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green[100],
            child: Text(
              name.toString().isNotEmpty
                  ? name.toString()[0].toUpperCase()
                  : '?',
              style: TextStyle(color: Colors.green[800]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toString(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(email, style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 2),
                Text(phone, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (widget.selectedItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: const [
            Icon(Icons.restaurant_menu, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('No items selected'),
          ],
        ),
      );
    }

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in widget.selectedItems) {
      final dateKey = item['menu_date']?.toString() ?? 'N/A';
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(item);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'Selected Items (${widget.selectedItems.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat(
                    'dd MMM yyyy',
                  ).format(DateTime.tryParse(entry.key) ?? DateTime.now()),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 6),
                ...entry.value.map(_buildItemTile).toList(),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    final itemType = item['type']?.toString().toLowerCase() ?? 'veg';
    final isNonVeg = itemType.contains('non');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNonVeg ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name']?.toString() ?? 'Item',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['meal_time'] ?? 'lunch'} • ₹${item['price'] ?? '0'}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isPlacingOrder ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[500],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                _isPlacingOrder
                    ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                    : const Text(
                      'Place Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
