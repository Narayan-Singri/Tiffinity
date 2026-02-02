import 'package:flutter/material.dart';
import 'package:Tiffinity/services/subscription_service.dart';
import 'package:Tiffinity/services/api_service.dart';
import 'subscription_detail_page.dart';

class MySubscriptionsPage extends StatefulWidget {
  const MySubscriptionsPage({super.key});

  @override
  State<MySubscriptionsPage> createState() => _MySubscriptionsPageState();
}

class _MySubscriptionsPageState extends State<MySubscriptionsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndOrders();
  }

  /// Loads User ID first, then fetches orders
  Future<void> _loadUserIdAndOrders() async {
    setState(() => _isLoading = true);
    try {
      final userData = await ApiService.getUserData();
      print('🔑 User Data: $userData');

      // robustly find the ID whether it's stored as 'uid', 'id', or 'user_id'
      final userIdValue =
          userData?['uid'] ?? userData?['id'] ?? userData?['user_id'];
      _userId = userIdValue?.toString();

      if (_userId != null) {
        await _loadOrders();
      } else {
        print('❌ No user ID found');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading user: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load user data: $e')));
      }
    }
  }

  /// Fetches the list of subscriptions from the server
  Future<void> _loadOrders() async {
    if (_userId == null) return;

    try {
      final orders = await SubscriptionService.getUserSubscriptionOrders(
        _userId!,
      );
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading orders: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subscriptions: $e')),
        );
      }
    }
  }

  /// Shows confirmation dialog before deleting
  void _confirmRemove(int orderId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Subscription'),
          content: const Text(
            'Are you sure you want to remove this subscription from your list?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeOrder(orderId);
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// The actual delete logic
  Future<void> _removeOrder(int orderId) async {
    if (_userId == null) return;

    // 1. Keep a copy of the list in case we need to undo
    final previous = List<Map<String, dynamic>>.from(_orders);

    // 2. Remove it from the screen immediately (Optimistic UI)
    setState(() {
      _orders.removeWhere((o) => o['id'].toString() == orderId.toString());
    });

    try {
      // 3. Send the command to the server
      final response = await SubscriptionService.deleteSubscriptionOrder(
        orderId: orderId.toString(),
        userId: _userId!,
      );

      // 4. CHECK THE SERVER ANSWER [Critical Fix]
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription removed successfully.')),
          );
        }
      } else {
        // The server said "No": Undo the change
        throw Exception(response['message'] ?? 'Server could not delete item');
      }
    } catch (e) {
      // 5. If anything failed, put the item back on the screen
      setState(() {
        _orders = previous;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadOrders,
                child:
                    _orders.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildSubscriptionItem(_orders[index]);
                          },
                        ),
              ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.calendar_month_outlined, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'No subscriptions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Subscribe to a meal plan to see it here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionItem(Map<String, dynamic> order) {
    // Safely parse ID
    final orderIdRaw = order['id'];
    final orderId =
        orderIdRaw is int
            ? orderIdRaw
            : int.tryParse(orderIdRaw?.toString() ?? '');

    // Safely parse other fields
    final messName = order['mess_name']?.toString() ?? 'Mess';
    final planName = order['plan_name']?.toString() ?? 'Plan';
    final status = order['status']?.toString() ?? 'pending';
    final startDate = order['start_date']?.toString() ?? '';
    final endDate = order['end_date']?.toString() ?? '';
    final totalAmount = order['total_amount']?.toString() ?? '0';

    final items =
        (order['selected_items'] as List?)
            ?.map((item) => item['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList() ??
        [];

    return _SubscriptionCard(
      title: messName,
      planName: planName,
      period: '$startDate to $endDate',
      nextRenewal: endDate,
      status: status,
      items: items,
      totalAmount: totalAmount,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubscriptionDetailPage(order: order),
          ),
        );
      },
      // Only show remove button if we successfully parsed the ID
      onRemove: orderId == null ? null : () => _confirmRemove(orderId),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final String title;
  final String planName;
  final String period;
  final String nextRenewal;
  final String status;
  final List<String> items;
  final String totalAmount;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _SubscriptionCard({
    required this.title,
    required this.planName,
    required this.period,
    required this.nextRenewal,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.onTap,
    this.onRemove,
  });

  Color _statusColor() {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      27,
                      84,
                      78,
                    ).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Color.fromARGB(255, 27, 84, 78),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        planName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    period,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                Text(
                  '₹$totalAmount',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    items.take(3).map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                        ),
                      );
                    }).toList(),
              ),
              if (items.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '+${items.length - 3} more items',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
            if (onRemove != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Remove',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
