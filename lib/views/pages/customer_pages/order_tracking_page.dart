import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Tiffinity/services/order_service.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/services/rating_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Tiffinity/views/widgets/order_status_timeline.dart';
import 'package:Tiffinity/views/widgets/order_live_map.dart';
import 'package:Tiffinity/views/widgets/delivery_rating_dialog.dart';
import 'package:Tiffinity/views/widgets/mess_rating_dialog.dart';

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
  bool _ratingDialogShownForSession = false;
  bool _hasRatedMess = false;
  bool _hasRatedDriver = false;

  // Track if the OTP dialog has been shown
  bool _otpDialogShown = false;

  static const Color _primaryColor = Color.fromARGB(255, 27, 84, 78);
  static const Color _bgLight = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadRatingState();
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

        final status = data?['status']?.toString().toLowerCase();

        // --- NEW OTP LOGIC ---
        // Check for 'delivery_otp' (matches your PHP script) or fallback to 'otp'
        final otp =
            data?['delivery_otp']?.toString() ?? data?['otp']?.toString();

        // If order isn't delivered yet, and we have a valid OTP that hasn't been shown
        if (status != 'delivered' &&
            otp != null &&
            otp.trim().isNotEmpty &&
            otp != 'null' &&
            !_otpDialogShown) {
          _otpDialogShown = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showOtpDialog(otp);
          });
        }
        // ----------------------

        if (!silent) {
          _fadeController.forward();
          // Show rating dialog if order is delivered
          debugPrint("📊 Order status: $status");
          debugPrint("🎯 Checking if delivered: ${status == 'delivered'}");

          if (status == 'delivered' &&
              !_ratingDialogShownForSession &&
              (!_hasRatedMess || !_hasRatedDriver)) {
            debugPrint("✅ Status is delivered - showing rating dialog");
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _showPendingRatingDialogs(),
            );
          } else {
            debugPrint("⏭️ Status is not delivered - skipping rating dialog");
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching order: $e");
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  String _ratingStateKey(String type) => 'rating_${type}_${widget.orderId}';

  Future<void> _loadRatingState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hasRatedMess = prefs.getBool(_ratingStateKey('mess')) ?? false;
      _hasRatedDriver = prefs.getBool(_ratingStateKey('driver')) ?? false;
    });
  }

  Future<void> _markRatingSubmitted({
    required bool messRated,
    required bool driverRated,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (messRated) {
      await prefs.setBool(_ratingStateKey('mess'), true);
    }
    if (driverRated) {
      await prefs.setBool(_ratingStateKey('driver'), true);
    }

    if (!mounted) return;
    setState(() {
      _hasRatedMess = _hasRatedMess || messRated;
      _hasRatedDriver = _hasRatedDriver || driverRated;
    });
  }

  Future<void> _showPendingRatingDialogs() async {
    if (_ratingDialogShownForSession) return;

    final user = await AuthService.currentUser;
    final customerId = user?['uid']?.toString();
    if (customerId == null || customerId.isEmpty) return;

    final data = await RatingService.getLatestUnratedOrder(
      customerId: customerId,
    );

    if (!mounted || data == null) return;

    final orderRaw = data['order'];
    if (orderRaw is! Map) return;

    final order = Map<String, dynamic>.from(orderRaw);
    final orderId =
        order['id']?.toString() ?? order['order_id']?.toString() ?? '';

    if (orderId != widget.orderId) return;

    final needsMess =
        data['needs_mess_rating'] == true && !_hasRatedMess;
    final needsDelivery =
        data['needs_delivery_rating'] == true && !_hasRatedDriver;

    if (!needsMess && !needsDelivery) return;

    _ratingDialogShownForSession = true;

    if (needsMess) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => MessRatingDialog(order: order),
      );

      await _markRatingSubmitted(messRated: true, driverRated: false);
    }

    if (!mounted) return;

    if (needsDelivery) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => DeliveryRatingDialog(order: order),
      );

      await _markRatingSubmitted(messRated: false, driverRated: true);
    }
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  // NEW METHOD: Show OTP Dialog
  void _showOtpDialog(String otp) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.security, color: _primaryColor),
                SizedBox(width: 8),
                Text('Delivery OTP'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please share this OTP with your delivery partner to receive your order.',
                  style: TextStyle(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    otp,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
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
                      status: _orderData?['status'] ?? 'pending',
                      deliveryPartner: _orderData?['delivery_partner_details'],
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
                                  currentStatus:
                                      _orderData?['status'] ?? 'pending',
                                ),
                                const SizedBox(height: 24),

                                // Delivery Partner Card
                                if (_orderData!['delivery_partner_details'] !=
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
                              "Order #${_orderData?['id'] ?? ''}",
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
    final status =
        (_orderData?['status'] ?? 'pending').toString().toLowerCase();
    String title = "Order Placed";
    String subtitle = "Waiting for confirmation";
    IconData icon = Icons.receipt_long;
    Color color = Colors.orange;

    // Define status display based on your actual workflow
    switch (status) {
      case 'pending':
        title = "Order Placed";
        subtitle = "Waiting for mess to accept your order";
        icon = Icons.receipt_long;
        color = Colors.orange;
        break;

      case 'accepted':
        title = "Order Accepted";
        subtitle = "Mess accepted your order";
        icon = Icons.check_circle_outline;
        color = Colors.blue;
        break;

      case 'confirmed':
        title = "Order Confirmed";
        subtitle = "Delivery partner confirmed. Mess is preparing your order";
        icon = Icons.verified;
        color = Colors.teal;
        break;

      case 'ready':
        title = "Order Ready";
        subtitle = "Waiting for delivery partner to pick up";
        icon = Icons.shopping_bag;
        color = Colors.purple;
        break;

      case 'out_for_delivery':
        title = "On the Way";
        subtitle = "Your order is out for delivery";
        icon = Icons.delivery_dining;
        color = _primaryColor;
        break;

      case 'delivered':
        title = "Delivered";
        subtitle = "Enjoy your meal!";
        icon = Icons.check_circle;
        color = Colors.green;
        break;

      case 'cancelled':
        title = "Order Cancelled";
        subtitle = "Your order has been cancelled";
        icon = Icons.cancel;
        color = Colors.red;
        break;

      case 'rejected':
        title = "Order Rejected";
        subtitle = "Mess rejected your order";
        icon = Icons.cancel;
        color = Colors.red;
        break;

      default:
        title = "Order Status";
        subtitle = "Processing your order";
        icon = Icons.info_outline;
        color = Colors.grey;
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
                const SizedBox(height: 4),
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
    final partner = _orderData?['delivery_partner_details'];
    if (partner == null) return const SizedBox.shrink();

    // Safely extract OTP
    final otp =
        _orderData?['delivery_otp']?.toString() ??
        _orderData?['otp']?.toString();
    final hasOtp = otp != null && otp.trim().isNotEmpty && otp != 'null';

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
                    ? NetworkImage(partner['photo'].toString())
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
                  partner['name']?.toString() ?? 'Delivery Partner',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                // Show actual OTP if it exists, otherwise show a waiting message
                if (hasOtp)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "OTP: $otp",
                      style: const TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  )
                else
                  Text(
                    "OTP will generate upon arrival",
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _makePhoneCall(partner['phone']?.toString()),
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
    // Calculate item total from actual items
    final items = _orderData!['items'] as List? ?? [];
    double itemTotal = 0.0;
    for (var item in items) {
      if (item != null && item is Map) {
        final quantity = int.tryParse(item['quantity'].toString()) ?? 0;
        final price = double.tryParse(item['price_at_time'].toString()) ?? 0.0;
        itemTotal += quantity * price;
      }
    }

    final foodSubtotal =
        double.tryParse(_orderData!['food_subtotal']?.toString() ?? '0') ?? 0;

    final deliveryFee =
        double.tryParse(_orderData!['delivery_fee']?.toString() ?? '0') ?? 0;

    final platformFee =
        double.tryParse(_orderData!['platform_fee']?.toString() ?? '0') ?? 0;

    final taxAmount =
        double.tryParse(_orderData!['tax_amount']?.toString() ?? '0') ?? 0;

    final totalAmount =
        double.tryParse(_orderData!['total_amount']?.toString() ?? '0') ?? 0;

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
            "₹${foodSubtotal.toStringAsFixed(2)}",
            isDark,
          ),

          _buildBillRow(
            "Delivery Fee",
            "₹${deliveryFee.toStringAsFixed(2)}",
            isDark,
          ),

          _buildBillRow(
            "Platform Fee",
            "₹${platformFee.toStringAsFixed(2)}",
            isDark,
          ),

          _buildBillRow("Taxes", "₹${taxAmount.toStringAsFixed(2)}", isDark),

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
                "₹${totalAmount.toStringAsFixed(2)}",
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
    final status =
        (_orderData?['status'] ?? 'pending').toString().toLowerCase();

    // Customer cancellation is allowed only while order is pending.
    final bool canCancel = status == 'pending';

    return Column(
      children: [
        if (canCancel)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Cancel Order?'),
                        content: const Text(
                          'Are you sure you want to cancel this order?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              // TODO: Implement cancel order API call
                              // await OrderService.cancelOrder(widget.orderId);
                            },
                            child: const Text(
                              'Yes, Cancel',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
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
              // TODO: Open Support/Help
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
