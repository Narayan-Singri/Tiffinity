import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Tiffinity/services/order_service.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/services/rating_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  int _messRating = 0;
  int _driverRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _ratingDialogShownForSession = false;
  bool _hasRatedMess = false;
  bool _hasRatedDriver = false;
  bool _isSubmittingRatings = false;

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
    _feedbackController.dispose();
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
        if (!silent) {
          _fadeController.forward();
          // Show rating dialog if order is delivered
          final status = data?['status']?.toString().toLowerCase();
          debugPrint("📊 Order status: $status");
          debugPrint("🎯 Checking if delivered: ${status == 'delivered'}");
          
          if (status == 'delivered' &&
              !_ratingDialogShownForSession &&
              !(_hasRatedMess && _hasRatedDriver)) {
            debugPrint("✅ Status is delivered - showing rating dialog");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showDriverRatingDialog();
            });
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

  String? _extractId(Map<String, dynamic>? map, List<String> candidates) {
    if (map == null) return null;
    for (final key in candidates) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  bool _isRatingSuccess(Map<String, dynamic> response) {
    final isSuccess = response['success'] == true ||
        response['status']?.toString().toLowerCase() == 'success';
    if (isSuccess) return true;

    final message = response['message']?.toString().toLowerCase() ?? '';
    return message.contains('already rated');
  }

  Future<void> _submitRatings({
    required Map<String, dynamic>? partner,
    required Map<String, dynamic>? messDetails,
  }) async {
    if (_isSubmittingRatings) return;

    if (_messRating <= 0 && _driverRating <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one rating')),
      );
      return;
    }

    final user = await AuthService.currentUser;
    final customerId = user?['uid']?.toString();
    if (customerId == null || customerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again to submit rating')),
      );
      return;
    }

    final review = _feedbackController.text.trim();
    final messOwnerId =
        _extractId(messDetails, [
          'owner_id',
          'mess_owner_id',
          'owner_uid',
          'uid',
          'user_id',
        ]) ??
        _orderData?['mess_owner_id']?.toString();
    final deliveryPartnerId =
        _extractId(partner, [
          'delivery_partner_id',
          'uid',
          'partner_id',
          'id',
        ]) ??
        _orderData?['delivery_partner_id']?.toString();

    bool messRatedNow = false;
    bool driverRatedNow = false;
    final errors = <String>[];

    if (mounted) {
      setState(() => _isSubmittingRatings = true);
    }

    try {
      if (_messRating > 0 && !_hasRatedMess) {
        if (messOwnerId == null || messOwnerId.isEmpty) {
          errors.add('Mess ID missing');
        } else {
          final response = await RatingService.submitMessRating(
            orderId: widget.orderId,
            messOwnerId: messOwnerId,
            customerId: customerId,
            rating: _messRating,
            review: review,
          );
          if (_isRatingSuccess(response)) {
            messRatedNow = true;
          } else {
            errors.add(response['message']?.toString() ?? 'Mess rating failed');
          }
        }
      }

      if (_driverRating > 0 && !_hasRatedDriver) {
        if (deliveryPartnerId == null || deliveryPartnerId.isEmpty) {
          errors.add('Delivery partner ID missing');
        } else {
          final response = await RatingService.submitDeliveryRating(
            orderId: widget.orderId,
            deliveryPartnerId: deliveryPartnerId,
            customerId: customerId,
            rating: _driverRating,
            review: review,
          );
          if (_isRatingSuccess(response)) {
            driverRatedNow = true;
          } else {
            errors.add(
              response['message']?.toString() ?? 'Delivery rating failed',
            );
          }
        }
      }

      await _markRatingSubmitted(
        messRated: messRatedNow,
        driverRated: driverRatedNow,
      );

      if (messRatedNow || driverRatedNow) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ),
        );
        _ratingDialogShownForSession = true;
        _messRating = 0;
        _driverRating = 0;
        _feedbackController.clear();
      }

      if (errors.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errors.join(', ')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingRatings = false);
      }
    }
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _showDriverRatingDialog() {
    final partnerRaw = _orderData?['delivery_partner_details'];
    final messRaw = _orderData?['mess_details'];
    final Map<String, dynamic>? partner =
        partnerRaw is Map ? Map<String, dynamic>.from(partnerRaw) : null;
    final Map<String, dynamic>? messDetails =
        messRaw is Map ? Map<String, dynamic>.from(messRaw) : null;
    debugPrint("🚗 Partner data: $partner");

    if (partner == null && messDetails == null) {
      debugPrint("❌ No partner/mess data found - cannot show rating dialog");
      return;
    }

    _ratingDialogShownForSession = true;
    debugPrint("✅ Rating entities found - showing dialog now");

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Driver Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: partner?['photo'] != null
                      ? NetworkImage(partner?['photo'].toString() ?? '')
                      : null,
                  child: partner?['photo'] == null
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  'Rate Your Order',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Driver Name
                Text(
                  partner?['name'] ?? messDetails?['name'] ?? 'Tiffinity',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                if (messDetails != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rate food & mess',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            _messRating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < _messRating ? Icons.star : Icons.star_border,
                            size: 32,
                            color:
                                index < _messRating ? Colors.amber : Colors.grey[400],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],

                if (partner != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rate delivery partner',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            _driverRating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < _driverRating ? Icons.star : Icons.star_border,
                            size: 32,
                            color:
                                index < _driverRating ? Colors.amber : Colors.grey[400],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 24),
                
                // Feedback TextField
                TextField(
                  controller: _feedbackController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Share your experience (optional)',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primaryColor),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _ratingDialogShownForSession = true;
                          _messRating = 0;
                          _driverRating = 0;
                          _feedbackController.clear();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: const Text('Skip'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_driverRating > 0 || _messRating > 0)
                            ? () async {
                                await _submitRatings(
                                  partner: partner,
                                  messDetails: messDetails,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: Text(
                          _isSubmittingRatings ? 'Submitting...' : 'Submit',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            );
          },
        ),
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
                      status: _orderData!['status'] ?? 'pending',
                      deliveryPartner: _orderData!['delivery_partner_details'],
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
      case 'confirmed':
        title = "Order Accepted";
        subtitle = "Delivery partner assigned. Mess is preparing your order";
        icon = Icons.check_circle_outline;
        color = Colors.blue;
        break;

      case 'preparing':
        title = "Preparing Your Order";
        subtitle = "Your food is being prepared";
        icon = Icons.restaurant;
        color = Colors.blue;
        break;

      case 'ready':
      case 'ready_for_pickup':
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

      case 'picked_up':
        title = "Order Picked Up";
        subtitle = "Delivery partner is heading to your location";
        icon = Icons.delivery_dining;
        color = Colors.orange;
        break;

      case 'delivered':
        title = "Delivered";
        subtitle = "Enjoy your meal! 🎉";
        icon = Icons.check_circle;
        color = Colors.green;
        break;

      case 'cancelled':
      case 'rejected':
        title = "Order Cancelled";
        subtitle = "Your order has been cancelled";
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
    final partner = _orderData!['delivery_partner_details'];
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

    final totalAmount = _orderData!['total_amount'];
    final totalAmountValue =
        double.tryParse(totalAmount?.toString() ?? '0') ?? 0.0;
    final deliveryFee = totalAmountValue - itemTotal;

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
          _buildBillRow(
            "Delivery Fee",
            "₹${deliveryFee.toStringAsFixed(2)}",
            isDark,
          ),
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

    // Can only cancel before delivery boy picks up
    bool canCancel = [
      'pending',
      'confirmed',
      'accepted',
      'preparing',
      'ready',
    ].contains(status);

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
