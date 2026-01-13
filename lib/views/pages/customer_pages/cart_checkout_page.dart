import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Tiffinity/data/notifiers.dart';
import 'package:Tiffinity/services/api_service.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/services/order_service.dart';
import 'package:Tiffinity/views/widgets/checkout_login_dialog.dart';
import 'package:Tiffinity/views/widgets/glassmorphic_cart_item.dart';
import 'package:Tiffinity/views/widgets/empty_cart_widget.dart';
import 'package:Tiffinity/views/widgets/price_breakdown_card.dart';
import 'order_tracking_page.dart';

class CartCheckoutPage extends StatefulWidget {
  final String messId;
  final String messName;

  const CartCheckoutPage({
    super.key,
    required this.messId,
    required this.messName,
  });

  @override
  State<CartCheckoutPage> createState() => _CartCheckoutPageState();
}

class _CartCheckoutPageState extends State<CartCheckoutPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();

    // Animated Background Controller
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Map<String, CartItem> _getCurrentMessCart() {
    return Map.fromEntries(
      cartNotifier.value.entries.where(
        (entry) => entry.value.messId == widget.messId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: Stack(
        children: [
          // 1. Animated Liquid Background
          _buildLiquidBackground(),

          // 2. Main Content
          SafeArea(
            child: ValueListenableBuilder<Map<String, CartItem>>(
              valueListenable: cartNotifier,
              builder: (context, cart, _) {
                final messCart = _getCurrentMessCart();

                if (messCart.isEmpty) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _buildFloatingAppBar(),
                        const Expanded(child: EmptyCartWidget()),
                      ],
                    ),
                  );
                }

                final subtotal = messCart.values.fold(
                  0.0,
                  (sum, item) => sum + item.totalPrice,
                );
                final deliveryFee = 20.0;
                final taxAmount = subtotal * 0.05;
                final totalAmount = subtotal + deliveryFee + taxAmount;

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      _buildFloatingAppBar(),
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          children: [
                            const SizedBox(height: 10),
                            _buildEnlargedMessHeader(),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Your Items'),
                            const SizedBox(height: 12),
                            ...messCart.entries.map((entry) {
                              return GlassmorphicCartItem(
                                item: entry.value,
                                itemId: entry.key,
                                onAdd: () => _addToCart(entry.key, entry.value),
                                onRemove: () => _removeFromCart(entry.key),
                              );
                            }).toList(),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Bill Details'),
                            const SizedBox(height: 12),
                            PriceBreakdownCard(
                              subtotal: subtotal,
                              deliveryFee: deliveryFee,
                              taxAmount: taxAmount,
                              totalAmount: totalAmount,
                            ),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                      _buildFloatingCheckoutButton(totalAmount),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Animated Liquid Background (from Profile Page)
  Widget _buildLiquidBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Stack(
          children: [
            // Top Right Blob
            Positioned(
              top: -120 + (40 * _backgroundController.value),
              right: -120,
              child: _blob(450, Colors.teal.withOpacity(0.12)),
            ),
            // Bottom Left Blob
            Positioned(
              bottom: 80 - (60 * _backgroundController.value),
              left: -120,
              child: _blob(400, Colors.tealAccent.withOpacity(0.08)),
            ),
            // Middle Right Accent Blob
            Positioned(
              top:
                  MediaQuery.of(context).size.height * 0.4 +
                  (30 * _backgroundController.value),
              right: -80,
              child: _blob(
                300,
                const Color.fromARGB(255, 27, 84, 78).withOpacity(0.06),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 50)],
      ),
    );
  }

  // Floating Pill-Shaped App Bar
  Widget _buildFloatingAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button - Pill Shaped
          _pillButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          // Title
          Text(
            'Your Cart',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2D3142),
              letterSpacing: 0.5,
            ),
          ),
          // Placeholder for symmetry
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _pillButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor ?? const Color.fromARGB(255, 27, 84, 78),
          size: 20,
        ),
      ),
    );
  }

  // Enlarged Mess Header with Glassmorphism
  Widget _buildEnlargedMessHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Restaurant Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 27, 84, 78),
                          const Color.fromARGB(
                            255,
                            27,
                            84,
                            78,
                          ).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(
                            255,
                            27,
                            84,
                            78,
                          ).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.messName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D3142),
                            letterSpacing: 0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '4.2',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '• 1.2 km',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Delivery Info Cards
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      icon: Icons.access_time_rounded,
                      label: 'Delivery',
                      value: '25-30 min',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoCard(
                      icon: Icons.delivery_dining_rounded,
                      label: 'Fee',
                      value: '₹20',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color.fromARGB(255, 27, 84, 78), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Floating Pill-Shaped Checkout Button (UPDATED)
  Widget _buildFloatingCheckoutButton(double totalAmount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF5F7F8).withOpacity(0),
            const Color(0xFFF5F7F8),
            const Color(0xFFF5F7F8),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 27, 84, 78),
              const Color.fromARGB(255, 27, 84, 78).withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(50), // Full pill shape
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isProcessing ? null : () => _proceedToCheckout(totalAmount),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              child:
                  _isProcessing
                      ? const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${totalAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'Proceed to Checkout',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }

  void _addToCart(String itemId, CartItem item) async {
    HapticFeedback.lightImpact();
    final cart = Map<String, CartItem>.from(cartNotifier.value);
    if (cart.containsKey(itemId)) {
      cart[itemId]!.quantity++;
    }
    cartNotifier.value = cart;
    await CartHelper.saveCart(cart);
  }

  void _removeFromCart(String itemId) async {
    HapticFeedback.lightImpact();
    final cart = Map<String, CartItem>.from(cartNotifier.value);
    if (cart.containsKey(itemId)) {
      if (cart[itemId]!.quantity > 1) {
        cart[itemId]!.quantity--;
      } else {
        cart.remove(itemId);
      }
    }
    cartNotifier.value = cart;
    await CartHelper.saveCart(cart);
  }

  void _proceedToCheckout(double totalAmount) async {
    final currentCart = _getCurrentMessCart();
    if (currentCart.isEmpty) return;

    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder:
            (context) => CheckoutLoginDialog(
              messId: widget.messId,
              messName: widget.messName,
            ),
      );
      return;
    }

    await _placeOrder(totalAmount);
  }

  Future<void> _placeOrder(double totalAmount) async {
    final currentCart = _getCurrentMessCart();
    if (currentCart.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final currentUser = await AuthService.currentUser;
      if (currentUser == null) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      String deliveryAddress = 'Not provided';
      try {
        final addressResponse =
            await ApiService.getRequest(
                  'users/get_default_address.php?user_id=${currentUser['uid']}',
                )
                as Map<String, dynamic>;

        if (addressResponse['success'] == true &&
            addressResponse['address'] != null) {
          final addr = addressResponse['address'];
          deliveryAddress =
              '${addr['room_no']}, ${addr['building']}, ${addr['area']}';
        } else {
          if (mounted) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a delivery address first'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a delivery address'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final orderItems =
          currentCart.entries.map((entry) {
            return {
              'menu_item_id': int.parse(entry.key),
              'quantity': entry.value.quantity,
              'price': entry.value.price,
            };
          }).toList();

      final result = await OrderService.createOrder(
        customerId: currentUser['uid'],
        messId: int.parse(widget.messId),
        totalAmount: totalAmount,
        items: orderItems,
        deliveryAddress: deliveryAddress,
      );

      if (mounted) setState(() => _isProcessing = false);

      if (result['message'] == 'Order created') {
        final orderId = result['order_id'];

        final updatedCart = Map<String, CartItem>.from(cartNotifier.value);
        currentCart.keys.forEach((key) => updatedCart.remove(key));
        cartNotifier.value = updatedCart;
        await CartHelper.saveCart(updatedCart);
        await CartHelper.clearPendingMess();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderTrackingPage(orderId: orderId),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order placed successfully! #$orderId'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Order failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
