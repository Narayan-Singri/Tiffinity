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

  // Theme Colors
  final Color _primaryColor = const Color(0xFF00695C);
  final Color _bgColor = const Color(0xFFF4F7F8);

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Remove Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Are you sure you want to remove this subscription from your list?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeOrder(orderId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'My Subscriptions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : RefreshIndicator(
        color: _primaryColor,
        onRefresh: _loadOrders,
        child: _orders.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            return _buildSubscriptionItem(_orders[index]);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ]
            ),
            child: Icon(
              Icons.event_note_rounded,
              size: 50,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Subscriptions Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Subscribe to a meal plan to see it here.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
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
        return const Color(0xFF10B981); // Emerald Green
      case 'pending':
        return const Color(0xFFF59E0B); // Amber
      case 'completed':
        return const Color(0xFF3B82F6); // Blue
      case 'cancelled':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6B7280); // Grey
    }
  }

  IconData _getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle_outline_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'completed':
        return Icons.verified_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP HEADER
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00695C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Color(0xFF00695C),
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
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            planName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getStatusIcon(), size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // PERIOD & PRICE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Text(
                          period,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    Text(
                      '₹$totalAmount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00695C),
                      ),
                    ),
                  ],
                ),

                // ITEMS CHIPS
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: items.take(3).map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (items.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
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

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                ),

                // BOTTOM ACTION BAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_view_day_rounded, size: 18, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Text(
                          'View Plan Details',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (onRemove != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: InkWell(
                              onTap: onRemove,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red[400]),
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7F8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}