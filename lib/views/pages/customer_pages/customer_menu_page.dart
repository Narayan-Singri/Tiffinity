import 'package:flutter/material.dart';
import 'package:Tiffinity/data/notifiers.dart';
import 'package:Tiffinity/data/constants.dart';
import 'package:Tiffinity/services/notification_service.dart';
import 'package:Tiffinity/services/mess_service.dart';
import 'package:Tiffinity/services/menu_service.dart';
import 'package:Tiffinity/services/order_service.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/widgets/checkout_login_dialog.dart';
import 'order_tracking_page.dart';
import 'package:Tiffinity/utils/order_id_generator.dart';

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
      // Load mess data
      final mess = await MessService.getMessById(int.parse(widget.messId));

      // Load menu items
      final menu = await MenuService.getMenuItems(int.parse(widget.messId));

      setState(() {
        _messData = mess;
        _menuItems = menu;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  // GET CART FOR CURRENT MESS ONLY
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
          // Hero Image Header
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
                        onPressed: () => showCartBottomSheet(context),
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
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color.fromARGB(255, 27, 84, 78),
                      const Color.fromARGB(255, 27, 84, 78).withOpacity(0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    if (_messData!['image_url'] != null &&
                        _messData!['image_url'].toString().isNotEmpty)
                      Positioned.fill(
                        child: Image.network(
                          _messData!['image_url'].toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color.fromARGB(
                                255,
                                27,
                                84,
                                78,
                              ).withOpacity(0.8),
                              child: const Center(
                                child: Icon(
                                  Icons.restaurant_menu,
                                  size: 80,
                                  color: Colors.white54,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        color: const Color.fromARGB(
                          255,
                          27,
                          84,
                          78,
                        ).withOpacity(0.8),
                        child: const Center(
                          child: Icon(
                            Icons.restaurant_menu,
                            size: 80,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // MESS INFO SECTION
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _messData!['name']?.toString() ?? 'Restaurant Name',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _messData!['mess_type']?.toString() ?? 'Cuisine Type',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '28 mins',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ],
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
                        style: TextStyle(color: Colors.black),
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

          // Menu Items
          _buildMenuSections(),
        ],
      ),

      // FLOATING CART BUTTON
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

          return FloatingActionButton.extended(
            onPressed: () => showCartBottomSheet(context),
            backgroundColor: const Color.fromARGB(255, 27, 84, 78),
            elevation: 8,
            label: SizedBox(
              width: MediaQuery.of(context).size.width - 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$itemCount items | ₹${totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'VIEW CART',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMenuSections() {
    if (_menuItems.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(50),
            child: Text("No menu items available"),
          ),
        ),
      );
    }

    // Filter items based on search
    final filteredItems =
        _menuItems.where((item) {
          if (searchQuery.isEmpty) return true;
          final name = item['name']?.toString().toLowerCase() ?? '';
          return name.contains(searchQuery);
        }).toList();

    // Group items by category (use a default category if not present)
    final groupedItems = <String, List<Map<String, dynamic>>>{};
    for (final item in filteredItems) {
      final category = item['category']?.toString() ?? 'Main Course';
      if (!groupedItems.containsKey(category)) {
        groupedItems[category] = [];
      }
      groupedItems[category]!.add(item);
    }

    if (groupedItems.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(50),
            child: Text("No items match your search"),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final categories = groupedItems.keys.toList();
        final category = categories[index];
        final categoryItems = groupedItems[category]!;

        return Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              ...categoryItems.map((item) {
                return _buildMenuItem(item['id'].toString(), item);
              }).toList(),
            ],
          ),
        );
      }, childCount: groupedItems.length),
    );
  }

  Widget _buildMenuItem(String itemId, Map<String, dynamic> data) {
    return ValueListenableBuilder<Map<String, CartItem>>(
      valueListenable: cartNotifier,
      builder: (context, cart, _) {
        final cartItem = cart[itemId];
        final quantity = cartItem?.quantity ?? 0;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          color: Colors.white,
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
                    Wrap(
                      spacing: 4,
                      alignment: WrapAlignment.start,
                      children: [
                        Text(
                          data['name']?.toString() ?? 'Unknown Item',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        if (data['type']?.toString().toLowerCase() == 'jain')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 27, 84, 78),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'Jain',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹ ${_getPrice(data['price'])}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (data['description'] != null &&
                        data['description'].toString().isNotEmpty) ...[
                      Text(
                        data['description'].toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'read more',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 27, 84, 78),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Add/Quantity Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child:
                          quantity > 0
                              ? Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 27, 84, 78),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _removeFromCart(itemId),
                                      icon: const Icon(
                                        Icons.remove,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 35,
                                        minHeight: 35,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        '$quantity',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _addToCart(itemId, data),
                                      icon: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 35,
                                        minHeight: 35,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color.fromARGB(
                                      255,
                                      27,
                                      84,
                                      78,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _addToCart(itemId, data),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'ADD',
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                255,
                                                27,
                                                84,
                                                78,
                                              ),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.add,
                                            color: Color.fromARGB(
                                              255,
                                              27,
                                              84,
                                              78,
                                            ),
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Food Image
              Container(
                width: 100,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      data['image_url'] != null &&
                              data['image_url'].toString().isNotEmpty
                          ? Image.network(
                            data['image_url'].toString(),
                            width: 100,
                            height: 80,
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
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: const Color.fromARGB(
                                      255,
                                      27,
                                      84,
                                      78,
                                    ),
                                    value:
                                        progress.expectedTotalBytes != null
                                            ? progress.cumulativeBytesLoaded /
                                                progress.expectedTotalBytes!
                                            : null,
                                  ),
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
            ],
          ),
        );
      },
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

  void showCartBottomSheet(BuildContext context) {
    final currentCart = _getCurrentMessCart();
    if (currentCart.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Cart',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ValueListenableBuilder<Map<String, CartItem>>(
                    valueListenable: cartNotifier,
                    builder: (context, cart, _) {
                      final messCart = _getCurrentMessCart();
                      final totalAmount = messCart.values.fold(
                        0.0,
                        (sum, item) => sum + item.totalPrice,
                      );

                      return ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          ...messCart.entries.map((entry) {
                            final item = entry.value;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₹${item.price.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          27,
                                          84,
                                          78,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed:
                                                () =>
                                                    _removeFromCart(entry.key),
                                            icon: const Icon(
                                              Icons.remove,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 35,
                                              minHeight: 35,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              '${item.quantity}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              _addToCart(entry.key, {
                                                'name': item.name,
                                                'price': item.price,
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 35,
                                              minHeight: 35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '₹${item.totalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${totalAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 27, 84, 78),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed:
                                () => _proceedToCheckout(context, totalAmount),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                27,
                                84,
                                78,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'PROCEED TO CHECKOUT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _proceedToCheckout(BuildContext context, double totalAmount) async {
    final currentCart = _getCurrentMessCart();
    if (currentCart.isEmpty) return;

    // Check if user is logged in
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      if (!mounted) return;
      Navigator.pop(context);
      showDialog(
        context: context,
        builder:
            (context) => CheckoutLoginDialog(
              messId: widget.messId,
              messName: _messData!['name']?.toString() ?? 'Unknown',
            ),
      );
      return;
    }

    // Show pickup time dialog
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => PickupTimeDialog(
            onConfirm: (pickupTime) async {
              await _placeOrder(pickupTime, totalAmount);
            },
          ),
    );
  }

  Future<void> _placeOrder(String pickupTime, double totalAmount) async {
    final currentCart = _getCurrentMessCart();
    if (currentCart.isEmpty) return;

    try {
      final currentUser = await AuthService.currentUser;
      if (currentUser == null) return;

      // Prepare order items
      final orderItems =
          currentCart.entries.map((entry) {
            return {
              'menu_item_id': int.parse(entry.key),
              'quantity': entry.value.quantity,
              'price': entry.value.price,
            };
          }).toList();

      // Create order
      final result = await OrderService.createOrder(
        customerId: currentUser['uid'],
        messId: int.parse(widget.messId),
        totalAmount: totalAmount,
        items: orderItems,
      );

      if (result['success']) {
        final orderId = result['order_id'];

        // Clear cart for this mess
        final updatedCart = Map<String, CartItem>.from(cartNotifier.value);
        currentCart.keys.forEach((key) => updatedCart.remove(key));
        cartNotifier.value = updatedCart;
        await CartHelper.saveCart(updatedCart);
        await CartHelper.clearPendingMess();

        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Order placed: #$orderId')));

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderTrackingPage(orderId: orderId),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Order failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Order failed: $e')));
      }
    }
  }
}

// Pickup Time Dialog Widget
class PickupTimeDialog extends StatefulWidget {
  final Function(String) onConfirm;
  const PickupTimeDialog({super.key, required this.onConfirm});

  @override
  State<PickupTimeDialog> createState() => _PickupTimeDialogState();
}

class _PickupTimeDialogState extends State<PickupTimeDialog> {
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('When will you pick up?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Please select your estimated pickup time',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                setState(() => _selectedTime = time);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color.fromARGB(255, 27, 84, 78),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTime?.format(context) ?? 'Select time',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Icon(
                    Icons.access_time,
                    color: Color.fromARGB(255, 27, 84, 78),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              _selectedTime == null
                  ? null
                  : () {
                    Navigator.pop(context);
                    widget.onConfirm(_selectedTime!.format(context));
                  },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
