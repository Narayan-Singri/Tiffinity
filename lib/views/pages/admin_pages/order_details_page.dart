import 'package:flutter/material.dart';
import 'package:Tiffinity/services/order_service.dart';

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

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Map<String, dynamic>? _orderDetails;
  bool _isLoading = true;
  String _currentStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.orderData['status'] ?? 'pending';
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => _isLoading = true);
    try {
      final order = await OrderService.getOrderById(widget.orderId);
      setState(() {
        _orderDetails = order;
        _currentStatus = order?['status'] ?? 'pending';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading order details: $e');
      setState(() => _isLoading = false);
    }
  }

  // ✅ FIX: Changed to use named parameters
  Future<void> _updateOrderStatus(String newStatus) async {
    final success = await OrderService.updateOrderStatus(
      orderId: widget.orderId, // ✅ Named parameter
      status: newStatus, // ✅ Named parameter
    );

    if (success && mounted) {
      setState(() => _currentStatus = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
      _loadOrderDetails();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update order status')),
      );
    }
  }

  void _showStatusUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Order Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusOption('pending', 'Pending'),
              _buildStatusOption('accepted', 'Accepted'),
              _buildStatusOption('preparing', 'Preparing'),
              _buildStatusOption('out_for_delivery', 'Out for Delivery'),
              _buildStatusOption('delivered', 'Delivered'),
              _buildStatusOption('cancelled', 'Cancelled'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(String status, String label) {
    return ListTile(
      title: Text(label),
      leading: Radio<String>(
        value: status,
        groupValue: _currentStatus,
        onChanged: (value) {
          Navigator.pop(context);
          if (value != null) {
            _updateOrderStatus(value);
          }
        },
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'out_for_delivery':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper function to safely convert to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper function to safely convert to int
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_orderDetails == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        ),
        body: const Center(child: Text('Order not found')),
      );
    }

    final statusColor = _getStatusColor(_currentStatus);
    final items = _orderDetails!['items'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${widget.orderId}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            _currentStatus.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Placed on:',
                      _formatDate(_orderDetails!['created_at']?.toString()),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Total Amount:',
                      '₹${_orderDetails!['total_amount']?.toString() ?? '0'}',
                      valueStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 27, 84, 78),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Update Status Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showStatusUpdateDialog,
                icon: const Icon(Icons.edit),
                label: const Text('Update Order Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 27, 84, 78),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Order Items
            const Text(
              'Order Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child:
                    items.isEmpty
                        ? const Text('No items found')
                        : Column(
                          children:
                              items.map((item) {
                                // ✅ FIX: Safely convert quantity and price to numbers
                                final quantity = _toInt(item['quantity']);
                                final priceAtTime = _toDouble(
                                  item['price_at_time'],
                                );
                                final totalPrice = quantity * priceAtTime;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name'] ?? 'Unknown Item',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              'Qty: $quantity × ₹${priceAtTime.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₹${totalPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
