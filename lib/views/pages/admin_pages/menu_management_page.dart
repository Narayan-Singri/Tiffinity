import 'package:flutter/material.dart';
import 'package:Tiffinity/services/menu_service.dart';
import 'package:Tiffinity/services/mess_service.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/pages/admin_pages/add_menu_item_page.dart';

class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage> {
  List<Map<String, dynamic>> menuItems = [];
  int? messId;
  bool isLoading = true;

  // New state variables for Search and Filter
  String _searchQuery = "";
  String _selectedFilter = "All";
  final List<String> _filters = ["All", "Available", "Out of Stock"];

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  // Helper function to convert int to bool
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return true; // Default to available
  }

  Future<void> _loadMenuItems() async {
    setState(() => isLoading = true);

    try {
      final currentUser = await AuthService.currentUser;
      if (currentUser == null) return;

      final mess = await MessService.getMessByOwner(currentUser['uid']);

      if (mess != null) {
        final items = await MenuService.getMenuItems(mess['id']);
        setState(() {
          messId = mess['id'];
          menuItems = items;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading menu: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteMenuItem(int itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Item'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this menu item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await MenuService.deleteMenuItem(itemId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu item deleted'), backgroundColor: Colors.red),
        );
        _loadMenuItems();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete item')),
        );
      }
    }
  }

  Future<void> _toggleAvailability(int itemId, bool currentStatus) async {
    final success = await MenuService.updateMenuItem(
      itemId: itemId,
      isAvailable: !currentStatus,
    );

    if (success) {
      _loadMenuItems();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update availability')),
      );
    }
  }

  // --- UI Helpers ---

  List<Map<String, dynamic>> get _filteredItems {
    return menuItems.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          (item['name']?.toString().toLowerCase() ?? '')
              .contains(_searchQuery.toLowerCase());

      final isAvailable = _toBool(item['is_available']);
      bool matchesFilter = true;
      if (_selectedFilter == "Available") matchesFilter = isAvailable;
      if (_selectedFilter == "Out of Stock") matchesFilter = !isAvailable;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color.fromARGB(255, 27, 84, 78)),
        ),
      );
    }

    if (messId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Menu Management'),
          backgroundColor: const Color.fromARGB(255, 27, 84, 78),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No mess found. Please create a mess first.', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    final filteredList = _filteredItems;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        color: const Color.fromARGB(255, 27, 84, 78),
        onRefresh: _loadMenuItems,
        child: CustomScrollView(
          slivers: [
            // Professional Rounded App Bar
            SliverAppBar(
              expandedHeight: 140.0,
              floating: false,
              pinned: true,
              backgroundColor: const Color.fromARGB(255, 27, 84, 78),
              elevation: 2,
              shadowColor: Colors.black38,
              shape: const ContinuousRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(60),
                  bottomRight: Radius.circular(60),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: const Text(
                  'Menu Management',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                background: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(60),
                    bottomRight: Radius.circular(60),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromARGB(255, 18, 65, 60),
                              Color.fromARGB(255, 27, 84, 78)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -20,
                        top: 10,
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 130,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Dashboard & Filters Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricsGrid(),
                    const SizedBox(height: 24),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildFilterChips(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Items List
            if (menuItems.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(
                  'No menu items yet',
                  'Tap the + button below to add your first dish.',
                  Icons.restaurant_menu,
                ),
              )
            else if (filteredList.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(
                  'No results found',
                  'Try changing your search or filter.',
                  Icons.search_off,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100), // Space for FAB
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return _buildMenuItemCard(filteredList[index]);
                    },
                    childCount: filteredList.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMenuItemPage(messId: messId!),
            ),
          );
          if (result == true) _loadMenuItems();
        },
        backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final available = menuItems.where((i) => _toBool(i['is_available'])).length;
    final outOfStock = menuItems.length - available;

    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Items', menuItems.length.toString(), Icons.fastfood, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Available', available.toString(), Icons.check_circle, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Out of Stock', outOfStock.toString(), Icons.remove_circle, Colors.red)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String count, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.shade50, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search menu items...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return FilterChip(
            label: Text(
              filter,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            selected: isSelected,
            onSelected: (bool selected) {
              setState(() => _selectedFilter = filter);
            },
            backgroundColor: Colors.white,
            selectedColor: const Color.fromARGB(255, 27, 84, 78),
            checkmarkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? const Color.fromARGB(255, 27, 84, 78) : Colors.grey.shade300,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5)
            ]),
            child: Icon(icon, size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item) {
    final isAvailable = _toBool(item['is_available']);
    final imageUrl = item['image_url']?.toString();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    // Auto-capitalize item name
    final rawName = item['name']?.toString() ?? 'Unnamed';
    final itemName = rawName.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isAvailable ? 0.04 : 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isAvailable ? Colors.transparent : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image Box
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: hasImage
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Icon(Icons.restaurant, color: Colors.grey.shade400, size: 30),
                    )
                        : Icon(Icons.restaurant, color: Colors.grey.shade400, size: 30),
                  ),
                ),
                if (!isAvailable)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.remove_circle_outline, color: Colors.white, size: 30),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? Colors.black87 : Colors.grey.shade600,
                      decoration: isAvailable ? TextDecoration.none : TextDecoration.lineThrough,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${item['price']}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isAvailable ? const Color.fromARGB(255, 27, 84, 78) : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isAvailable ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      isAvailable ? 'AVAILABLE' : 'OUT OF STOCK',
                      style: TextStyle(
                        color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Actions Popup
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                      SizedBox(width: 12),
                      Text('Edit Item'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                          isAvailable ? Icons.remove_circle_outline : Icons.check_circle_outline,
                          size: 20,
                          color: isAvailable ? Colors.orange : Colors.green
                      ),
                      const SizedBox(width: 12),
                      Text(isAvailable ? 'Mark Out of Stock' : 'Mark Available'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete Item', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'edit') {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMenuItemPage(
                        messId: messId!,
                        existingItem: item,
                      ),
                    ),
                  );
                  if (result == true) _loadMenuItems();
                } else if (value == 'toggle') {
                  _toggleAvailability(item['id'], isAvailable);
                } else if (value == 'delete') {
                  _deleteMenuItem(item['id']);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}