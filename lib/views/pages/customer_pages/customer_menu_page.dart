import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:Tiffinity/data/notifiers.dart';
import 'package:Tiffinity/data/constants.dart';
import 'package:Tiffinity/services/mess_service.dart';
import 'package:Tiffinity/services/menu_service.dart';
import 'cart_checkout_page.dart';
import 'subscription_duration_page.dart';

class MenuPage extends StatefulWidget {
  final String messId;
  const MenuPage({super.key, required this.messId});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String selectedCategory = 'All';
  String searchQuery = '';
  Map<String, dynamic>? _messData;
  List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final mess = await MessService.getMessById(int.parse(widget.messId));

      // ✅ FETCH TODAY'S MENU ONLY (from weekly schedule)
      final todaysItems = await MenuService.getTodaysMenu(
        int.parse(widget.messId),
      );

      // Convert TodaysMenuItem to Map format (compatible with existing UI)
      final menu =
          todaysItems.map((item) {
            return {
              'id': item.menuItemId, // ✅ Use menuItemId for cart
              'mess_id': int.parse(
                widget.messId,
              ), // ✅ Use widget.messId instead
              'name': item.itemName,
              'description': item.description ?? '',
              'price': item.price,
              'image_url': item.imageUrl ?? '',
              'type': item.itemType,
              'category': item.categoryName ?? 'Uncategorized',
              'is_available': 1,
            };
          }).toList();

      setState(() {
        _messData = mess;
        _menuItems = menu;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading today\'s menu: $e');
      setState(() => _isLoading = false);
    }
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_messData == null) {
      return const Scaffold(body: Center(child: Text("Mess not found")));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image Header with Mess Background
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color.fromARGB(255, 27, 84, 78),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              ValueListenableBuilder<Map<String, CartItem>>(
                valueListenable: cartNotifier,
                builder: (context, cart, _) {
                  final messCart = _getCurrentMessCart();
                  final itemCount = messCart.values.fold(
                    0,
                    (sum, item) => sum + item.quantity,
                  );
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.shopping_cart,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => CartCheckoutPage(
                                    messId: widget.messId,
                                    messName:
                                        _messData!['name']?.toString() ??
                                        'Unknown',
                                  ),
                            ),
                          );
                        },
                      ),
                      if (itemCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$itemCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.card_membership, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => SubscriptionDurationPage(
                            messId: widget.messId,
                            messName: _messData?['name'] ?? 'Mess',
                          ),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Mess Background Image (Fitted)
                  if (_messData!['image_url'] != null &&
                      _messData!['image_url'].toString().isNotEmpty)
                    Image.network(
                      _messData!['image_url'].toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color.fromARGB(255, 27, 84, 78),
                          child: const Center(
                            child: Icon(
                              Icons.restaurant_menu,
                              size: 80,
                              color: Colors.white54,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: const Color.fromARGB(255, 27, 84, 78),
                      child: const Center(
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 80,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // MESS INFO SECTION with Rounded Top Corners
          SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mess Name
                    Text(
                      _messData!['name']?.toString() ?? 'Restaurant Name',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ✨ TODAY'S MENU BADGE (NEW)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(
                                  255,
                                  27,
                                  84,
                                  78,
                                ).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Today's Menu • ${_getDayName(DateTime.now().weekday)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Cuisine Type
                        Expanded(
                          child: Text(
                            _messData!['mess_type']?.toString() ??
                                'Cuisine Type',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Rating and Timings Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.white, size: 14),
                              SizedBox(width: 2),
                              Text(
                                '4.2',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Open • Closes 10:30 PM',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Location and Delivery Time Row
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '1.0 km',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.delivery_dining,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '28 mins',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // SEARCH AND FILTER SECTION
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.black),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search menu items...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'Filter',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildMenuSections(),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<Map<String, CartItem>>(
        valueListenable: cartNotifier,
        builder: (context, cart, _) {
          final messCart = _getCurrentMessCart();
          if (messCart.isEmpty) return const SizedBox.shrink();

          final itemCount = messCart.values.fold(
            0,
            (sum, item) => sum + item.quantity,
          );
          final totalAmount = messCart.values.fold(
            0.0,
            (sum, item) => sum + item.totalPrice,
          );

          return _buildFloatingCartButton(itemCount, totalAmount);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Pill-Shaped Translucent Floating Cart Button
  Widget _buildFloatingCartButton(int itemCount, double totalAmount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CartCheckoutPage(
                            messId: widget.messId,
                            messName:
                                _messData!['name']?.toString() ?? 'Unknown',
                          ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(50),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(
                                255,
                                27,
                                84,
                                78,
                              ).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shopping_cart_rounded,
                              color: Color.fromARGB(255, 27, 84, 78),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$itemCount items',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 27, 84, 78),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '₹${totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 27, 84, 78),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 27, 84, 78),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Replace _buildMenuSections() method:

  Widget _buildMenuSections() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Group items by category
          final Map<String, List<Map<String, dynamic>>> groupedItems = {};

          for (var item in _menuItems) {
            final category = item['category']?.toString() ?? 'Daily Menu Items';
            if (!groupedItems.containsKey(category)) {
              groupedItems[category] = [];
            }

            // Apply search filter
            final name = item['name']?.toString().toLowerCase() ?? '';
            if (searchQuery.isEmpty || name.contains(searchQuery)) {
              groupedItems[category]!.add(item);
            }
          }

          // Remove empty categories after filtering
          groupedItems.removeWhere((key, value) => value.isEmpty);

          final categoryNames = groupedItems.keys.toList();

          if (index >= categoryNames.length) return null;

          final categoryName = categoryNames[index];
          final items = groupedItems[categoryName]!;

          return _buildCategorySection(categoryName, items);
        },
        childCount: () {
          // Count categories
          final Map<String, List<Map<String, dynamic>>> groupedItems = {};
          for (var item in _menuItems) {
            final category = item['category']?.toString() ?? 'Daily Menu Items';
            if (!groupedItems.containsKey(category)) {
              groupedItems[category] = [];
            }
            final name = item['name']?.toString().toLowerCase() ?? '';
            if (searchQuery.isEmpty || name.contains(searchQuery)) {
              groupedItems[category]!.add(item);
            }
          }
          groupedItems.removeWhere((key, value) => value.isEmpty);
          return groupedItems.length;
        }(),
      ),
    );
  }

  // Add this new method for expandable categories:

  Widget _buildCategorySection(
    String categoryName,
    List<Map<String, dynamic>> items,
  ) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Row(
          children: [
            Icon(
              categoryName == 'Daily Menu Items' ? Icons.star : Icons.category,
              color: const Color.fromARGB(255, 27, 84, 78),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              categoryName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${items.length} items',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color.fromARGB(255, 27, 84, 78),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        children:
            items.map((item) {
              final itemId = item['id']?.toString() ?? '';
              return _buildMenuItem(itemId, item);
            }).toList(),
      ),
    );
  }

  // Flat Menu Item Design
  Widget _buildMenuItem(String itemId, Map<String, dynamic> data) {
    return ValueListenableBuilder<Map<String, CartItem>>(
      valueListenable: cartNotifier,
      builder: (context, cart, _) {
        final cartItem = cart[itemId];
        final quantity = cartItem?.quantity ?? 0;

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Veg/Non-veg symbol
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child:
                    (data['type']?.toString().toLowerCase() == 'veg' ||
                            data['type']?.toString().toLowerCase() == 'jain')
                        ? Symbols.vegSymbol
                        : Symbols.nonVegSymbol,
              ),
              const SizedBox(width: 12),
              // Item Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name']?.toString() ?? 'Unknown Item',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹ ${_getPrice(data['price'])}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 27, 84, 78),
                      ),
                    ),
                    if (data['description'] != null &&
                        data['description'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        data['description'].toString(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Food Image with Compact Overlapping Quantity Controls
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          data['image_url'] != null &&
                                  data['image_url'].toString().isNotEmpty
                              ? Image.network(
                                data['image_url'].toString(),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.restaurant,
                                      color: Colors.grey[400],
                                      size: 40,
                                    ),
                                  );
                                },
                              )
                              : Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.restaurant,
                                  color: Colors.grey[400],
                                  size: 40,
                                ),
                              ),
                    ),
                  ),
                  // Compact iOS-style Glassmorphic Quantity Controls
                  Positioned(
                    bottom: -8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildQuantityControl(itemId, quantity, data),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Compact iOS-style Glassmorphic Quantity Control
  Widget _buildQuantityControl(
    String itemId,
    int quantity,
    Map<String, dynamic> data,
  ) {
    if (quantity > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _compactIconButton(
                  icon: Icons.remove_rounded,
                  onPressed: () => _removeFromCart(itemId),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 27, 84, 78),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                _compactIconButton(
                  icon: Icons.add_rounded,
                  onPressed: () => _addToCart(itemId, data),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _addToCart(itemId, data),
                borderRadius: BorderRadius.circular(50),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text(
                    'ADD',
                    style: TextStyle(
                      color: Color.fromARGB(255, 27, 84, 78),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  // Compact Icon Button for Quantity Controls
  Widget _compactIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            color: const Color.fromARGB(255, 27, 84, 78),
            size: 16,
          ),
        ),
      ),
    );
  }

  String _getPrice(dynamic price) {
    if (price == null) return '0';
    if (price is String) {
      return price;
    } else if (price is int || price is double) {
      return price.toString();
    }
    return '0';
  }

  double _getPriceAsDouble(dynamic price) {
    if (price == null) return 0.0;
    if (price is String) {
      return double.tryParse(price) ?? 0.0;
    } else if (price is int) {
      return price.toDouble();
    } else if (price is double) {
      return price;
    }
    return 0.0;
  }

  void _addToCart(String itemId, Map<String, dynamic> itemData) async {
    final cart = Map<String, CartItem>.from(cartNotifier.value);
    if (cart.containsKey(itemId)) {
      cart[itemId]!.quantity++;
    } else {
      cart[itemId] = CartItem(
        id: itemId,
        name: itemData['name']?.toString() ?? 'Unknown',
        price: _getPriceAsDouble(itemData['price']),
        messId: widget.messId,
        messName: _messData!['name']?.toString() ?? 'Unknown Mess',
      );
    }
    cartNotifier.value = cart;
    await CartHelper.saveCart(cart);
  }

  void _removeFromCart(String itemId) async {
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

  // Get day name from weekday number
  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }
}
