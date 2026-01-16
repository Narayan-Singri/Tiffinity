import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Tiffinity/services/order_service.dart';
import 'package:Tiffinity/views/widgets/order_status_timeline.dart';
import 'package:Tiffinity/views/widgets/order_live_map.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;

  const OrderTrackingPage({super.key, required this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _refreshTimer;
  late AnimationController _fadeController;

  static const Color _primaryColor = Color.fromARGB(255, 27, 84, 78);
  static const Color _bgLight = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadOrderDetails();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadOrderDetails(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetails({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final data = await OrderService.getOrderById(widget.orderId);

      // DEBUG: Print the entire response
      debugPrint("===== ORDER DATA =====");
      debugPrint("Full response: ${data.toString()}");
      debugPrint("Keys: ${data?.keys.toList()}");
      debugPrint("Mess data: ${data?['mess']}");
      debugPrint("Items data: ${data?['items']}");
      debugPrint("=====================");

      if (mounted) {
        setState(() {
          _orderData = data;
          _isLoading = false;
          _hasError = false;
        });
        if (!silent) _fadeController.forward();
      }
    } catch (e) {
      debugPrint("Error fetching order: $e");
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : _bgLight,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: _primaryColor),
              )
              : _hasError
              ? _buildErrorView()
              : Stack(
                children: [
                  // 1. BACKGROUND MAP LAYER
                  Positioned.fill(
                    child: OrderLiveMap(
                      status: _orderData!['status'] ?? 'pending',
                      deliveryPartner: _orderData!['delivery']?['partner'],
                    ),
                  ),

                  // 2. DRAGGABLE BOTTOM SHEET (FOREGROUND)
                  DraggableScrollableSheet(
                    initialChildSize: 0.6,
                    minChildSize: 0.5,
                    maxChildSize: 1.0, // ⬅️ Allow full screen coverage
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : _bgLight,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // DRAG HANDLE
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),

                                // Order Status Card
                                _buildStatusCard(isDark),
                                const SizedBox(height: 24),

                                // Track Order Section
                                Text(
                                  "Track Order",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Timeline
                                OrderStatusTimeline(
                                  currentStatus: _orderData!['status'],
                                ),
                                const SizedBox(height: 24),

                                // Delivery Partner Card
                                if (_orderData!['delivery']?['partner'] !=
                                    null) ...[
                                  _buildDeliveryPartnerCard(isDark),
                                  const SizedBox(height: 24),
                                ],

                                // Order Details Section
                                Text(
                                  "Order Details",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                _buildOrderItemsList(isDark),
                                const SizedBox(height: 16),
                                _buildBillDetails(isDark),
                                const SizedBox(height: 30),
                                _buildActionButtons(isDark),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 3. FLOATING ORDER ID PILL (TOP CENTER)
                  Positioned(
                    top:
                        MediaQuery.of(context).padding.top +
                        10, // Below status bar
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black87 : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 18,
                              color: _primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Order #${_orderData!['id']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 4. BACK BUTTON (TOP LEFT)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 16,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    final status = _orderData!['status'].toString().toLowerCase();
    String title = "Order Placed";
    String subtitle = "Waiting for confirmation";
    IconData icon = Icons.receipt_long; // ✅ Add this line
    Color color = Colors.orange; // ✅ Add this line

    if (status == 'confirmed') {
      title = "Order Confirmed";
      subtitle = "Restaurant is preparing your order";
      icon = Icons.check_circle_outline;
      color = Colors.blue;
    } else if (status == 'ready') {
      title = "Order Ready";
      subtitle = "Waiting for delivery partner to pick up";
      icon = Icons.shopping_bag;
      color = Colors.purple;
    } else if (status == 'at_pickup_location') {
      title = "Driver Arrived at Restaurant";
      subtitle = "Waiting for order to be ready";
      icon = Icons.local_shipping;
      color = Colors.amber;
    } else if (status == 'out_for_delivery') {
      title = "On the Way";
      subtitle = "Your order is out for delivery";
      icon = Icons.delivery_dining;
      color = _primaryColor;
    } else if (status == 'delivered') {
      title = "Delivered";
      subtitle = "Enjoy your meal!";
      icon = Icons.check_circle;
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPartnerCard(bool isDark) {
    final partner = _orderData!['delivery']['partner'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            backgroundImage:
                partner['photo'] != null
                    ? NetworkImage(partner['photo'])
                    : null,
            child:
                partner['photo'] == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner['name'] ?? 'Delivery Partner',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  "${_orderData!['otp']} is your OTP",
                  style: const TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _makePhoneCall(partner['phone']),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call, color: Colors.green, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsList(bool isDark) {
    final items = _orderData!['items'] as List? ?? [];
    final messDetails =
        _orderData!['mess_details']; // Changed from 'mess' to 'mess_details'

    // Add null check for mess details
    if (messDetails == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Mess information not available',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              color: Colors.grey[200],
              child: const Icon(Icons.store, size: 20),
            ),
          ),
          title: Text(
            messDetails['name']?.toString() ?? 'Mess',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            _orderData!['delivery_address']?.toString() ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          children:
              items.where((item) => item != null && item is Map).map((item) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color:
                            (item['type']?.toString().toLowerCase() ?? 'veg') ==
                                    'veg'
                                ? Colors.green
                                : Colors.red,
                        size: 12,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${item['quantity'] ?? 1}x",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['name']?.toString() ?? 'Item',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        "₹${item['price_at_time'] ?? item['price'] ?? 0}", // Use price_at_time
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildBillDetails(bool isDark) {
    // Get values from root level, not from 'bill' object
    final totalAmount = _orderData!['total_amount'];
    final deliveryFee = _orderData!['delivery_fee'];

    // Calculate item total and taxes
    final itemTotal =
        totalAmount != null && deliveryFee != null
            ? (double.tryParse(totalAmount.toString()) ?? 0) -
                (double.tryParse(deliveryFee.toString()) ?? 0)
            : 0;
    final taxes = itemTotal * 0.05; // 5% tax

    if (totalAmount == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bill Summary",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildBillRow(
            "Item Total",
            "₹${itemTotal.toStringAsFixed(2)}",
            isDark,
          ),
          _buildBillRow("Delivery Fee", "₹${deliveryFee ?? 0}", isDark),
          _buildBillRow("Taxes (5%)", "₹${taxes.toStringAsFixed(2)}", isDark),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Amount",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                "₹$totalAmount",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    final status = _orderData!['status'].toString().toLowerCase();
    bool canCancel = ['pending', 'confirmed', 'accepted'].contains(status);

    return Column(
      children: [
        if (canCancel)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // TODO: Implement Cancel Order
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Cancel Order"),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              // TODO: Open Support
            },
            icon: const Icon(Icons.headset_mic, size: 18),
            label: Text(
              "Need Help?",
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text("Something went wrong"),
          TextButton(
            onPressed: () => _loadOrderDetails(),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
