import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:confetti/confetti.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:Tiffinity/services/order_service.dart';
import 'package:Tiffinity/views/widgets/rejection_reason_bottom_sheet.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _orderDetails;
  bool _isLoading = true;
  String _currentStatus = 'pending';
  late ConfettiController _confettiController;
  late AnimationController _pulseController;

  // Auto-refresh timer
  bool _autoRefreshEnabled = true;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.orderData['status'] ?? 'pending';
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _loadOrderDetails();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    _autoRefreshEnabled = false;
    super.dispose();
  }

  // Auto-refresh every 15 seconds
  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 15), () {
      if (_autoRefreshEnabled && mounted) {
        _loadOrderDetails(silent: true);
        _startAutoRefresh();
      }
    });
  }

  Future<void> _loadOrderDetails({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    try {
      final order = await OrderService.getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _orderDetails = order;
          _currentStatus = order?['status'] ?? 'pending';
          _isLoading = false;
        });

        // Show confetti if delivered
        if (_currentStatus == 'delivered') {
          _confettiController.play();
        }
      }
    } catch (e) {
      debugPrint('Error loading order details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load order: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    HapticFeedback.mediumImpact();

    final success = await OrderService.updateOrderStatus(
      orderId: widget.orderId,
      status: newStatus,
    );

    if (success && mounted) {
      setState(() => _currentStatus = newStatus);

      // Show appropriate snackbar
      final snackbarConfig = _getSnackbarConfig(newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(snackbarConfig['icon'], color: Colors.white),
              const SizedBox(width: 12),
              Text(snackbarConfig['message']),
            ],
          ),
          backgroundColor: snackbarConfig['color'],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      _loadOrderDetails(silent: true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update order status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic> _getSnackbarConfig(String status) {
    switch (status) {
      case 'confirmed':
        return {
          'message': 'Order Accepted Successfully',
          'color': Colors.green,
          'icon': Icons.check_circle,
        };
      case 'ready':
        return {
          'message': 'Order Ready for Pickup',
          'color': Colors.blue,
          'icon': Icons.restaurant_menu,
        };
      case 'out_for_delivery':
        return {
          'message': 'Order Out for Delivery',
          'color': Colors.orange,
          'icon': Icons.delivery_dining,
        };
      case 'delivered':
        return {
          'message': 'Order Delivered Successfully',
          'color': Colors.green,
          'icon': Icons.celebration,
        };
      default:
        return {
          'message': 'Status Updated',
          'color': Colors.blue,
          'icon': Icons.info,
        };
    }
  }

  Future<void> _showRejectionDialog() async {
    HapticFeedback.lightImpact();

    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RejectionReasonBottomSheet(),
    );

    if (reason != null && reason.isNotEmpty) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Rejecting order...'),
                    ],
                  ),
                ),
              ),
            ),
      );

      final success = await OrderService.rejectOrder(
        orderId: widget.orderId,
        reason: reason,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.cancel, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Order Rejected'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          setState(() => _currentStatus = 'rejected');
          _loadOrderDetails(silent: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reject order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'accepted':
        return const Color(0xFF2196F3);
      case 'confirmed': // ✅ Delivery boy confirmed
        return const Color(0xFF4CAF50);
      case 'preparing':
        return const Color(0xFF2196F3);
      case 'waiting_for_order': // ✅ Delivery boy waiting
        return const Color(0xFFFFC107);
      case 'waiting_for_pickup': // ✅ Order ready, boy not there
        return const Color(0xFF673AB7);
      case 'ready':
      case 'ready_for_pickup':
        return const Color(0xFF9C27B0);
      case 'out_for_delivery':
      case 'picked_up':
      case 'assigned_to_delivery':
        return const Color(0xFFFF5722);
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
      case 'accepted':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
      case 'ready_for_pickup':
        return Icons.shopping_bag;
      case 'out_for_delivery':
      case 'picked_up':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0';
    final value = double.tryParse(amount.toString()) ?? 0.0;
    return '₹${value.toStringAsFixed(0)}';
  }

  String _getRelativeTime(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return timeago.format(date, locale: 'en_short');
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        ),
        body: _buildShimmerLoading(),
      );
    }

    if (_orderDetails == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Order not found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 27, 84, 78),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final statusColor = _getStatusColor(_currentStatus);
    final items = _orderDetails!['items'] as List? ?? [];
    final customerDetails =
        _orderDetails!['customer_details'] != null
            ? Map<String, dynamic>.from(
              _orderDetails!['customer_details'] as Map,
            )
            : <String, dynamic>{};
    final deliveryPartnerDetails =
        _orderDetails!['delivery_partner_details'] != null
            ? Map<String, dynamic>.from(
              _orderDetails!['delivery_partner_details'] as Map,
            )
            : <String, dynamic>{};
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadOrderDetails(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _loadOrderDetails(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HEADER CARD
                  _buildHeaderCard(statusColor),
                  const SizedBox(height: 16),

                  // 2. CUSTOMER DETAILS CARD
                  _buildCustomerCard(customerDetails),
                  const SizedBox(height: 16),

                  // 3. ORDER ITEMS CARD
                  _buildOrderItemsCard(items),
                  const SizedBox(height: 16),

                  // 4. BILL BREAKDOWN CARD
                  _buildBillBreakdownCard(),
                  const SizedBox(height: 16),

                  // 5. DELIVERY PARTNER CARD (if assigned)
                  if (deliveryPartnerDetails.isNotEmpty) ...[
                    _buildDeliveryPartnerCard(deliveryPartnerDetails),
                    const SizedBox(height: 16),
                  ],

                  // 6. REJECTION DETAILS (if rejected)
                  if (_currentStatus == 'rejected' ||
                      _currentStatus == 'cancelled')
                    _buildRejectionCard(),

                  const SizedBox(height: 100), // Space for bottom action button
                ],
              ),
            ),
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),

          // Bottom Action Section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActionSection(statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color statusColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [statusColor.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start, // ✅ ADDED
              children: [
                Expanded(
                  // ✅ WRAP IN EXPANDED
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${widget.orderId}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 27, 84, 78),
                        ),
                        maxLines: 1, // ✅ LIMIT TO 1 LINE
                        overflow: TextOverflow.ellipsis, // ✅ TRUNCATE WITH ...
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRelativeTime(
                          _orderDetails!['created_at']?.toString(),
                        ),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8), // ✅ SMALL SPACING
                _buildPulsingStatusBadge(statusColor),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  _formatCurrency(_orderDetails!['total_amount']),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 27, 84, 78),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildPulsingStatusBadge(Color statusColor) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final isPulsing =
            _currentStatus == 'pending' ||
            _currentStatus == 'preparing' ||
            _currentStatus == 'out_for_delivery';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(
              isPulsing ? 0.2 + (_pulseController.value * 0.1) : 0.2,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor, width: 2),
            boxShadow:
                isPulsing
                    ? [
                      BoxShadow(
                        color: statusColor.withOpacity(0.4),
                        blurRadius: 8 + (_pulseController.value * 4),
                        spreadRadius: _pulseController.value * 2,
                      ),
                    ]
                    : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(_currentStatus),
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _currentStatus.toUpperCase().replaceAll('_', ' '),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customerDetails) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      27,
                      84,
                      78,
                    ).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color.fromARGB(255, 27, 84, 78),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Customer Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.person_outline,
              'Name',
              customerDetails['name'] ?? 'N/A',
            ),
            const SizedBox(height: 12),
            _buildInfoRowWithAction(
              icon: Icons.phone,
              label: 'Phone',
              value: customerDetails['phone'] ?? 'N/A',
              onTap: () => _makePhoneCall(customerDetails['phone'] ?? ''),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Delivery Address',
              _orderDetails!['delivery_address'] ?? 'N/A',
            ),
            if (_orderDetails!['special_instructions'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Special Instructions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _orderDetails!['special_instructions'],
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildOrderItemsCard(List items) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      27,
                      84,
                      78,
                    ).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Color.fromARGB(255, 27, 84, 78),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Order Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length} items',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...items.map((item) => _buildOrderItem(item)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final quantity = int.tryParse(item['quantity'].toString()) ?? 0;
    final price = double.tryParse(item['price_at_time'].toString()) ?? 0.0;
    final total = quantity * price;
    final itemType = item['type']?.toString().toLowerCase() ?? 'veg';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Veg/Non-veg indicator
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(
                color: itemType == 'non-veg' ? Colors.red : Colors.green,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: itemType == 'non-veg' ? Colors.red : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Unknown Item',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: $quantity × ${_formatCurrency(price)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(total),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 27, 84, 78),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillBreakdownCard() {
    final subtotal =
        double.tryParse(_orderDetails!['total_amount'].toString()) ?? 0.0;
    final deliveryFee =
        double.tryParse(_orderDetails!['delivery_fee']?.toString() ?? '0') ??
        0.0;
    final itemTotal = subtotal - deliveryFee;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      27,
                      84,
                      78,
                    ).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Color.fromARGB(255, 27, 84, 78),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Bill Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildBillRow('Item Total', itemTotal),
            const SizedBox(height: 8),
            _buildBillRow('Delivery Fee', deliveryFee),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatCurrency(subtotal),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 27, 84, 78),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildBillRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
        Text(
          _formatCurrency(amount),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDeliveryPartnerCard(Map<String, dynamic> partnerDetails) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Delivery Partner',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  child: Text(
                    partnerDetails['name']?.toString()[0].toUpperCase() ?? 'D',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnerDetails['name'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${partnerDetails['rating'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.directions_bike,
                            color: Colors.grey[600],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            partnerDetails['vehicle_type'] ?? 'N/A',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      if (partnerDetails['vehicle_number'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          partnerDetails['vehicle_number'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed:
                      () => _makePhoneCall(partnerDetails['phone'] ?? ''),
                  icon: const Icon(Icons.phone, color: Colors.green),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildRejectionCard() {
    final rejectionDetails =
        _orderDetails!['rejection_details'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 2,
      color: Colors.red.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cancel, color: Colors.red),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Order Rejected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Reason: ${rejectionDetails['rejection_reason'] ?? 'No reason provided'}',
              style: const TextStyle(fontSize: 15),
            ),
            if (rejectionDetails['rejected_at'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Rejected ${_getRelativeTime(rejectionDetails['rejected_at'].toString())}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).shake();
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color.fromARGB(255, 27, 84, 78)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowWithAction({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color.fromARGB(255, 27, 84, 78)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.phone, color: Colors.green),
          style: IconButton.styleFrom(
            backgroundColor: Colors.green.withOpacity(0.1),
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionSection(Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(child: _buildActionButtons()),
    );
  }

  Widget _buildActionButtons() {
    switch (_currentStatus.toLowerCase()) {
      // ======================================================================
      // PENDING: Mess can Accept or Reject
      // ======================================================================
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _showRejectionDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel_outlined),
                    SizedBox(width: 8),
                    Text('REJECT', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus('accepted'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline),
                    SizedBox(width: 8),
                    Text('ACCEPT ORDER', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        );

      // ======================================================================
      // ACCEPTED: Delivery boy auto-assigned, preparing food
      // ======================================================================
      case 'accepted':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.restaurant, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Delivery partner auto-assigned. Prepare the order.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SlideAction(
              text: 'Swipe to Mark Order Ready',
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              innerColor: Colors.white,
              outerColor: Colors.blue,
              sliderButtonIcon: const Icon(
                Icons.restaurant_menu,
                color: Colors.blue,
              ),
              onSubmit: () {
                _updateOrderStatus('ready');
                return null;
              },
            ),
          ],
        );

      // ======================================================================
      // CONFIRMED: Delivery boy accepted assignment
      // ======================================================================
      case 'confirmed':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '✅ Delivery partner confirmed. Prepare the order now.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SlideAction(
              text: 'Swipe to Mark Order Ready',
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              innerColor: Colors.white,
              outerColor: Colors.green,
              sliderButtonIcon: const Icon(
                Icons.restaurant_menu,
                color: Colors.green,
              ),
              onSubmit: () {
                _updateOrderStatus('ready');
                return null;
              },
            ),
          ],
        );

      // ======================================================================
      // PREPARING: Actively preparing
      // ======================================================================
      case 'preparing':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.restaurant, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🍳 Preparing the order...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SlideAction(
              text: 'Swipe to Mark Order Ready',
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              innerColor: Colors.white,
              outerColor: Colors.orange,
              sliderButtonIcon: const Icon(
                Icons.restaurant_menu,
                color: Colors.orange,
              ),
              onSubmit: () {
                _updateOrderStatus('ready');
                return null;
              },
            ),
          ],
        );

      // ======================================================================
      // 🚨 AT_PICKUP_LOCATION / REACHED_PICKUP: Delivery boy waiting
      // ======================================================================
      case 'at_pickup_location':
      case 'atpickuplocation':
      case 'reached_pickup':
      case 'reachedpickup':
      case 'waiting_for_order':
      case 'waitingfororder':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.amber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '⚠️ Delivery partner is WAITING at pickup location!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SlideAction(
              text: 'Swipe When Order Ready',
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              innerColor: Colors.white,
              outerColor: Colors.amber,
              sliderButtonIcon: const Icon(
                Icons.restaurant_menu,
                color: Colors.amber,
              ),
              onSubmit: () {
                _updateOrderStatus('ready');
                return null;
              },
            ),
          ],
        );

      // ======================================================================
      // READY: Order ready, waiting for delivery boy
      // ======================================================================
      case 'ready':
      case 'ready_for_pickup':
      case 'readyforpickup':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple),
          ),
          child: const Row(
            children: [
              Icon(Icons.shopping_bag, color: Colors.purple, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Order Ready for Pickup',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Waiting for delivery partner to pick up the order',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      // ======================================================================
      // WAITING_FOR_PICKUP: Order ready but delivery boy not at location
      // ======================================================================
      case 'waiting_for_pickup':
      case 'waitingforpickup':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo),
          ),
          child: const Row(
            children: [
              Icon(Icons.shopping_bag, color: Colors.indigo, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📦 Order Ready - Waiting for Pickup',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Order is ready. Waiting for delivery partner to arrive.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      // ======================================================================
      // OUT_FOR_DELIVERY: Delivery boy has the order (INFO ONLY - NO SLIDER)
      // ======================================================================
      case 'out_for_delivery':
      case 'outfordelivery':
      case 'picked_up':
      case 'pickedup':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange),
          ),
          child: const Row(
            children: [
              Icon(Icons.delivery_dining, color: Colors.orange, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚴 Order Out for Delivery',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Delivery partner is on the way to customer',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      // ======================================================================
      // DELIVERED: Order completed successfully
      // ======================================================================
      case 'delivered':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text(
                '✅ Order Delivered Successfully',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        );

      // ======================================================================
      // CANCELLED / REJECTED
      // ======================================================================
      case 'cancelled':
      case 'rejected':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Text(
                'Order Rejected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
