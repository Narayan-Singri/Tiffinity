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

  // Theme Colors
  static const Color _primaryColor = Color(0xFF00695C);
  static const Color _bgLight = Color(0xFFF4F7F8);

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

  // MODERNIZED OTP DIALOG
  void _showOtpDialog(String otp) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security_rounded, color: _primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Delivery OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please share this OTP with your delivery partner to receive your order.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primaryColor.withOpacity(0.2), width: 2),
              ),
              child: Text(
                otp,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 12,
                  color: _primaryColor,
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Got it',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
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

          // 2. MODERN DRAGGABLE BOTTOM SHEET
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.5,
            maxChildSize: 1.0,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : _bgLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // MODERN DRAG HANDLE
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        // Order Status Card
                        _buildStatusCard(isDark),
                        const SizedBox(height: 28),

                        // Track Order Section
                        Text(
                          "Track Order",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Timeline
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isDark ? [] : [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: OrderStatusTimeline(
                            currentStatus: _orderData?['status'] ?? 'pending',
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Delivery Partner Card
                        if (_orderData!['delivery_partner_details'] != null) ...[
                          _buildDeliveryPartnerCard(isDark),
                          const SizedBox(height: 28),
                        ],

                        // Order Details Section
                        Text(
                          "Order Details",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildOrderItemsList(isDark),
                        const SizedBox(height: 20),
                        _buildBillDetails(isDark),
                        const SizedBox(height: 32),
                        _buildActionButtons(isDark),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 3. FLOATING ORDER ID PILL (MODERN)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black87 : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 18, color: _primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      "Order #${_orderData?['id'] ?? ''}",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. BACK BUTTON (MODERN)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black87 : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    final status = (_orderData?['status'] ?? 'pending').toString().toLowerCase();
    String title = "Order Placed";
    String subtitle = "Waiting for confirmation";
    IconData icon = Icons.receipt_long_rounded;
    Color color = const Color(0xFFF59E0B); // Amber

    switch (status) {
      case 'pending':
        title = "Order Placed";
        subtitle = "Waiting for mess to accept your order";
        icon = Icons.schedule_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case 'accepted':
        title = "Order Accepted";
        subtitle = "Mess accepted your order";
        icon = Icons.thumb_up_outlined;
        color = const Color(0xFF3B82F6);
        break;
      case 'confirmed':
        title = "Order Confirmed";
        subtitle = "Delivery partner confirmed. Mess is preparing.";
        icon = Icons.verified_outlined;
        color = const Color(0xFF8B5CF6);
        break;
      case 'ready':
        title = "Order Ready";
        subtitle = "Waiting for delivery partner to pick up";
        icon = Icons.fastfood_outlined;
        color = const Color(0xFF6366F1);
        break;
      case 'out_for_delivery':
        title = "On the Way";
        subtitle = "Your order is out for delivery";
        icon = Icons.moped_rounded;
        color = const Color(0xFF0EA5E9);
        break;
      case 'delivered':
        title = "Delivered";
        subtitle = "Enjoy your meal!";
        icon = Icons.check_circle_outline_rounded;
        color = const Color(0xFF10B981);
        break;
      case 'cancelled':
        title = "Order Cancelled";
        subtitle = "Your order has been cancelled";
        icon = Icons.cancel_outlined;
        color = const Color(0xFFEF4444);
        break;
      case 'rejected':
        title = "Order Rejected";
        subtitle = "Mess rejected your order";
        icon = Icons.cancel_outlined;
        color = const Color(0xFFEF4444);
        break;
      default:
        title = "Order Status";
        subtitle = "Processing your order";
        icon = Icons.info_outline_rounded;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
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
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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

    final otp = _orderData?['delivery_otp']?.toString() ?? _orderData?['otp']?.toString();
    final hasOtp = otp != null && otp.trim().isNotEmpty && otp != 'null';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.grey[100],
            backgroundImage: partner['photo'] != null ? NetworkImage(partner['photo'].toString()) : null,
            child: partner['photo'] == null ? Icon(Icons.person_outline, color: Colors.grey[400], size: 28) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner['name']?.toString() ?? 'Delivery Partner',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                if (hasOtp)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "OTP: $otp",
                      style: const TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                  )
                else
                  Text(
                    "OTP will generate upon arrival",
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _makePhoneCall(partner['phone']?.toString()),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.call_rounded, color: Color(0xFF10B981), size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsList(bool isDark) {
    final items = _orderData!['items'] as List? ?? [];
    final messDetails = _orderData!['mess_details'];

    if (messDetails == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Text('Mess information not available', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront_rounded, size: 22, color: _primaryColor),
          ),
          title: Text(
            messDetails['name']?.toString() ?? 'Mess',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
          ),
          subtitle: Text(
            _orderData!['delivery_address']?.toString() ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.grey[400] : Colors.grey[500]),
          ),
          children: items.where((item) => item != null && item is Map).map((item) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: (item['type']?.toString().toLowerCase() ?? 'veg') == 'veg' ? Colors.green : Colors.red,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.circle,
                      color: (item['type']?.toString().toLowerCase() ?? 'veg') == 'veg' ? Colors.green : Colors.red,
                      size: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${item['quantity'] ?? 1}x",
                    style: const TextStyle(fontWeight: FontWeight.w800, color: _primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['name']?.toString() ?? 'Item',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey[800]),
                    ),
                  ),
                  Text(
                    "₹${item['price_at_time'] ?? item['price'] ?? 0}",
                    style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.grey[800]),
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
    final items = _orderData!['items'] as List? ?? [];
    double itemTotal = 0.0;
    for (var item in items) {
      if (item != null && item is Map) {
        final quantity = int.tryParse(item['quantity'].toString()) ?? 0;
        final price = double.tryParse(item['price_at_time'].toString()) ?? 0.0;
        itemTotal += quantity * price;
      }
    }

    final foodSubtotal = double.tryParse(_orderData!['food_subtotal']?.toString() ?? '0') ?? 0;
    final deliveryFee = double.tryParse(_orderData!['delivery_fee']?.toString() ?? '0') ?? 0;
    final platformFee = double.tryParse(_orderData!['platform_fee']?.toString() ?? '0') ?? 0;
    final taxAmount = double.tryParse(_orderData!['tax_amount']?.toString() ?? '0') ?? 0;
    final totalAmount = double.tryParse(_orderData!['total_amount']?.toString() ?? '0') ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bill Summary",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 16),
          _buildBillRow("Item Total", "₹${foodSubtotal.toStringAsFixed(2)}", isDark),
          _buildBillRow("Delivery Fee", "₹${deliveryFee.toStringAsFixed(2)}", isDark),
          _buildBillRow("Platform Fee", "₹${platformFee.toStringAsFixed(2)}", isDark),
          _buildBillRow("Taxes", "₹${taxAmount.toStringAsFixed(2)}", isDark),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            // Modern dashed-look divider substitute
            child: Container(
              height: 1,
              color: isDark ? Colors.grey[700] : const Color(0xFFE5E7EB),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Amount",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
              ),
              Text(
                "₹${totalAmount.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: _primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    final status = (_orderData?['status'] ?? 'pending').toString().toLowerCase();
    final bool canCancel = status == 'pending';

    return Column(
      children: [
        if (canCancel)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Cancel Order?', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text('Are you sure you want to cancel this order?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text('No', style: TextStyle(color: Colors.grey[700]))),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          // await OrderService.cancelOrder(widget.orderId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50], // Soft red background
                foregroundColor: Colors.red,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Cancel Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              // TODO: Open Support/Help
            },
            icon: const Icon(Icons.headset_mic_rounded, size: 20),
            label: Text(
              "Need Help with this Order?",
              style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700], fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.grey[300] : Colors.grey[700],
              padding: const EdgeInsets.symmetric(vertical: 12),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[400]),
          ),
          const SizedBox(height: 20),
          Text(
            "Something went wrong",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadOrderDetails(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Retry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}