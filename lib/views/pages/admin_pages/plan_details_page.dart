import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Tiffinity/services/subscription_service.dart';
import 'package:Tiffinity/services/menu_service.dart';
import 'package:Tiffinity/models/category_model.dart';
import 'package:Tiffinity/views/widgets/filter_chips.dart' as CustomChips;
import 'package:Tiffinity/views/widgets/veg_nonveg_logo.dart';

class PlanDetailsPage extends StatefulWidget {
  final int planId;
  final int? messId;

  const PlanDetailsPage({super.key, required this.planId, this.messId});

  @override
  State<PlanDetailsPage> createState() => _PlanDetailsPageState();
}

class _PlanDetailsPageState extends State<PlanDetailsPage> {
  List<dynamic> _subscribers = [];
  List<Map<String, dynamic>> _subscriptionMenuItems = [];
  List<Map<String, dynamic>> _todayMenuItems = [];
  bool _isLoading = true;
  bool _isLoadingMenuItems = false;
  bool _isLoadingTodayMenuItems = false;

  @override
  void initState() {
    super.initState();
    _loadSubscribers();
    _loadSubscriptionMenuItems();
    _loadTodayMenuItems();
  }

  Future<void> _loadSubscribers() async {
    setState(() => _isLoading = true);
    try {
      final subscribers = await SubscriptionService.getPlanSubscribers(
        widget.planId,
      );
      setState(() {
        _subscribers = subscribers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subscribers: $e')),
        );
      }
    }
  }

  Future<void> _loadSubscriptionMenuItems() async {
    setState(() => _isLoadingMenuItems = true);
    try {
      // Get tomorrow's date
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final tomorrowDateString =
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

      final menus = await SubscriptionService.getMenus(
        messId: widget.messId ?? 1,
        startDate: tomorrowDateString,
        endDate: tomorrowDateString,
      );

      List<Map<String, dynamic>> allItems = [];

      // Find items for lunch meal time
      for (var menu in menus) {
        if (menu['meal_time'] == 'lunch' &&
            menu['date'] == tomorrowDateString) {
          final items = menu['items'];
          if (items is String) {
            final decoded = jsonDecode(items);
            allItems =
                (decoded as List)
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList();
          } else if (items is List) {
            allItems =
                items.map((item) => Map<String, dynamic>.from(item)).toList();
          }
          break;
        }
      }

      setState(() {
        _subscriptionMenuItems = allItems;
        _isLoadingMenuItems = false;
      });
    } catch (e) {
      print('Error loading subscription menu items: $e');
      setState(() => _isLoadingMenuItems = false);
    }
  }

  Future<void> _loadTodayMenuItems() async {
    setState(() => _isLoadingTodayMenuItems = true);
    try {
      // Get today's date
      final today = DateTime.now();
      final todayDateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final menus = await SubscriptionService.getMenus(
        messId: widget.messId ?? 1,
        startDate: todayDateString,
        endDate: todayDateString,
      );

      List<Map<String, dynamic>> allItems = [];

      // Find items for lunch meal time
      for (var menu in menus) {
        if (menu['meal_time'] == 'lunch' && menu['date'] == todayDateString) {
          final items = menu['items'];
          if (items is String) {
            final decoded = jsonDecode(items);
            allItems =
                (decoded as List)
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList();
          } else if (items is List) {
            allItems =
                items.map((item) => Map<String, dynamic>.from(item)).toList();
          }
          break;
        }
      }

      setState(() {
        _todayMenuItems = allItems;
        _isLoadingTodayMenuItems = false;
      });
    } catch (e) {
      print('Error loading today menu items: $e');
      setState(() => _isLoadingTodayMenuItems = false);
    }
  }

  Future<void> _removeMenuItem(int itemId, String itemName) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Remove Item'),
            content: Text(
              'Are you sure you want to remove "$itemName" from tomorrow\'s menu?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Remove'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      // Remove item from the list
      final updatedItems =
          _subscriptionMenuItems.where((item) => item['id'] != itemId).toList();

      // Get tomorrow's date
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final tomorrowDateString =
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

      print('🗑️ Removing item: $itemName (ID: $itemId)');
      print('📋 Updated items count: ${updatedItems.length}');

      // Update database with the filtered list
      await SubscriptionService.addMenu(
        messId: widget.messId ?? 1,
        date: tomorrowDateString,
        mealTime: 'lunch',
        items: updatedItems,
        append: false,
      );

      // Reload the list
      await _loadSubscriptionMenuItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemName removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error removing item: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing item: $e')));
      }
    }
  }

  void _showAddItemsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _AddSubscriptionItemsModal(
            planId: widget.planId,
            messId: widget.messId ?? 1,
            onItemsAdded: () {
              _loadSubscribers();
              _loadSubscriptionMenuItems(); // Reload menu items after adding
            },
          ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSubscribers =
        _subscribers.where((s) => s['status'] == 'active').length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Plan Subscribers'),
        backgroundColor: Colors.orange,
        actions: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _showAddItemsDialog,
                icon: Icon(Icons.add_shopping_cart, size: 18),
                label: Text('Add Items'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$activeSubscribers',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Active Subscribers',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadSubscribers();
                await _loadSubscriptionMenuItems();
                await _loadTodayMenuItems();
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subscribers Section
                    if (_isLoading)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(50),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_subscribers.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(50),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 80,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No subscribers yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.all(16),
                        itemCount: _subscribers.length,
                        itemBuilder: (context, index) {
                          final subscriber = _subscribers[index];
                          final status = subscriber['status'];
                          final daysRemaining =
                              subscriber['days_remaining'] ?? 0;

                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(status),
                                child: Text(
                                  subscriber['user_name'][0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                subscriber['user_name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(subscriber['email']),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '${subscriber['start_date']} to ${subscriber['end_date']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        status,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: _getStatusColor(status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  if (status == 'active') ...[
                                    SizedBox(height: 4),
                                    Text(
                                      '$daysRemaining days left',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // Menu Items Section
                    if (_subscriptionMenuItems.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Icon(Icons.restaurant_menu, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Tomorrow\'s Menu Items',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            Text(
                              '${_subscriptionMenuItems.length} items',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _subscriptionMenuItems.length,
                        itemBuilder: (context, index) {
                          final item = _subscriptionMenuItems[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    item['image_url'] != null &&
                                            item['image_url']
                                                .toString()
                                                .isNotEmpty
                                        ? Image.network(
                                          item['image_url'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.orange.withOpacity(
                                                0.1,
                                              ),
                                              child: Icon(
                                                Icons.restaurant,
                                                color: Colors.orange,
                                              ),
                                            );
                                          },
                                        )
                                        : Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.orange.withOpacity(0.1),
                                          child: Icon(
                                            Icons.restaurant,
                                            color: Colors.orange,
                                          ),
                                        ),
                              ),
                              title: Text(
                                item['name'] ?? 'Item',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (((item['type']
                                              ?.toString()
                                              .toLowerCase()
                                              .replaceAll(' ', '')
                                              .replaceAll('-', '') ??
                                          '')) ==
                                      'jain')
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        'JAIN',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  Text('₹${item['price'] ?? 0}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  VegNonVegLogo(type: item['type'], size: 12),
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    iconSize: 22,
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                    onPressed:
                                        () => _removeMenuItem(
                                          item['id'] ?? 0,
                                          item['name'] ?? 'Item',
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                    ] else if (_isLoadingMenuItems)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.restaurant,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No items added for tomorrow',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Click "Add Items" to add menu items',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Today's Menu Items Section
                    if (_todayMenuItems.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Icon(Icons.today, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Today\'s Menu Items',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            Text(
                              '${_todayMenuItems.length} items',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _todayMenuItems.length,
                        itemBuilder: (context, index) {
                          final item = _todayMenuItems[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    item['image_url'] != null &&
                                            item['image_url']
                                                .toString()
                                                .isNotEmpty
                                        ? Image.network(
                                          item['image_url'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.blue.withOpacity(
                                                0.1,
                                              ),
                                              child: Icon(
                                                Icons.restaurant,
                                                color: Colors.blue,
                                              ),
                                            );
                                          },
                                        )
                                        : Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.blue.withOpacity(0.1),
                                          child: Icon(
                                            Icons.restaurant,
                                            color: Colors.blue,
                                          ),
                                        ),
                              ),
                              title: Text(
                                item['name'] ?? 'Item',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (((item['type']
                                              ?.toString()
                                              .toLowerCase()
                                              .replaceAll(' ', '')
                                              .replaceAll('-', '') ??
                                          '')) ==
                                      'jain')
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        'JAIN',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  Text('₹${item['price'] ?? 0}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  VegNonVegLogo(type: item['type'], size: 12),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                    ] else if (_isLoadingTodayMenuItems)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSubscriptionItemsModal extends StatefulWidget {
  final int planId;
  final int messId;
  final Function() onItemsAdded;

  const _AddSubscriptionItemsModal({
    required this.planId,
    required this.messId,
    required this.onItemsAdded,
  });

  @override
  State<_AddSubscriptionItemsModal> createState() =>
      _AddSubscriptionItemsModalState();
}

class _AddSubscriptionItemsModalState
    extends State<_AddSubscriptionItemsModal> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedCategories = {};
  final Set<int> _selectedItems = {};

  List<Map<String, dynamic>> _allMenuItems = [];
  List<Category> _categories = [];
  String _searchQuery = '';
  String _typeFilter = 'All';
  String? _categoryFilter;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        MenuService.getMenuItems(widget.messId),
        MenuService.getCategories(widget.messId),
      ]);

      if (mounted) {
        setState(() {
          _allMenuItems = results[0] as List<Map<String, dynamic>>;
          _categories = results[1] as List<Category>;
          _isLoadingData = false;

          // 🔍 DEBUG: Print what we received from backend
          print('✅ Loaded ${_allMenuItems.length} menu items');
          print('✅ Loaded ${_categories.length} categories');
          print('📋 Items: $_allMenuItems');
          print('📋 Categories: $_categories');
        });
      }
    } catch (e) {
      print('❌ Error loading data: $e');
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading items: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    return _allMenuItems.where((item) {
      // Check if item is available
      final isAvailable = (item['is_available'] ?? 1) as int;
      if (isAvailable == 0) return false;

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final name = item['name']?.toString().toLowerCase() ?? '';
        final description = item['description']?.toString().toLowerCase() ?? '';
        final searchLower = _searchQuery.toLowerCase();
        if (!name.contains(searchLower) && !description.contains(searchLower)) {
          return false;
        }
      }

      // Filter by type (Veg/Non-Veg/Jain)
      if (_typeFilter != 'All') {
        final itemType = item['type']?.toString().toLowerCase() ?? 'veg';
        final normalizedType = itemType.replaceAll(' ', '').replaceAll('-', '');

        if (_typeFilter == 'Veg' && normalizedType != 'veg') return false;
        if (_typeFilter == 'Non-Veg' && normalizedType != 'nonveg')
          return false;
        if (_typeFilter == 'Jain' && normalizedType != 'jain') return false;
      }

      return true;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _groupedItems {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in _filteredItems) {
      final categoryName = item['category']?.toString() ?? 'Uncategorized';

      if (!grouped.containsKey(categoryName)) {
        grouped[categoryName] = [];
      }
      grouped[categoryName]!.add(item);
    }

    return grouped;
  }

  Future<void> _submitItems() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one item')),
      );
      return;
    }

    try {
      // Format new items for database
      final newItems =
          _selectedItems.map((id) {
            final menuItem = _allMenuItems.firstWhere(
              (item) => int.parse(item['id'].toString()) == id,
              orElse: () => {},
            );
            return {
              'id': id,
              'name': menuItem['name'] ?? 'Item',
              'price': menuItem['price'] ?? 0,
              'type': menuItem['type'] ?? 'veg',
              'quantity': '1',
              'image_url': menuItem['image_url'] ?? '',
            };
          }).toList();

      // Get tomorrow's date
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final tomorrowDateString =
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

      print('💾 PREPARING TO SAVE ITEMS');
      print('📋 New items count: ${newItems.length}');
      print('📅 Date: $tomorrowDateString');
      print('🏢 Mess ID: ${widget.messId}');

      // Fetch existing items for this date to merge with new items
      print('🔍 Fetching existing items for this date...');
      final existingMenus = await SubscriptionService.getMenus(
        messId: widget.messId,
        startDate: tomorrowDateString,
        endDate: tomorrowDateString,
      );

      List<Map<String, dynamic>> existingItems = [];

      // Find existing items for lunch meal time
      for (var menu in existingMenus) {
        if (menu['meal_time'] == 'lunch' &&
            menu['date'] == tomorrowDateString) {
          final items = menu['items'];
          if (items is String) {
            // Parse JSON string
            final decoded = jsonDecode(items);
            existingItems =
                (decoded as List)
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList();
          } else if (items is List) {
            // Already a list
            existingItems =
                items.map((item) => Map<String, dynamic>.from(item)).toList();
          }
          break;
        }
      }

      print('📦 Found ${existingItems.length} existing items');

      // Merge existing items with new items (avoid duplicates by item id)
      final existingItemIds = existingItems.map((item) => item['id']).toSet();
      final mergedItems = <Map<String, dynamic>>[...existingItems];

      for (var newItem in newItems) {
        if (!existingItemIds.contains(newItem['id'])) {
          mergedItems.add(newItem);
        } else {
          print('⚠️ Item ${newItem['name']} already exists, skipping...');
        }
      }

      print('✅ Total items to save: ${mergedItems.length}');
      print('📋 Merged items: $mergedItems');

      await SubscriptionService.addMenu(
        messId: widget.messId,
        date: tomorrowDateString,
        mealTime: 'lunch',
        items: mergedItems,
        append: false, // We're sending the complete list, not appending
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onItemsAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${newItems.length} item(s) added successfully for tomorrow',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR saving items: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding items: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildSearchBar(),
          SizedBox(height: 12),
          _buildFilterChips(),
          SizedBox(height: 16),
          _buildItemsList(),
          if (_selectedItems.isNotEmpty) _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Add Items to Subscription',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search items...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            suffixIcon:
                _searchQuery.isNotEmpty
                    ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          CustomChips.FilterChip(
            label: 'All',
            isSelected: _typeFilter == 'All',
            onTap: () => setState(() => _typeFilter = 'All'),
          ),
          SizedBox(width: 8),
          CustomChips.FilterChip(
            label: 'Veg',
            isSelected: _typeFilter == 'Veg',
            onTap: () => setState(() => _typeFilter = 'Veg'),
            icon: '🟢',
          ),
          SizedBox(width: 8),
          CustomChips.FilterChip(
            label: 'Non-Veg',
            isSelected: _typeFilter == 'Non-Veg',
            onTap: () => setState(() => _typeFilter = 'Non-Veg'),
            icon: '🔴',
          ),
          SizedBox(width: 8),
          CustomChips.FilterChip(
            label: 'Jain',
            isSelected: _typeFilter == 'Jain',
            onTap: () => setState(() => _typeFilter = 'Jain'),
            icon: '🟡',
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (_isLoadingData) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading items from backend...'),
            ],
          ),
        ),
      );
    }

    print('DEBUG: _allMenuItems count: ${_allMenuItems.length}');
    print('DEBUG: _groupedItems keys: ${_groupedItems.keys.toList()}');
    print('DEBUG: _groupedItems: $_groupedItems');

    if (_allMenuItems.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'No items available',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 8),
              Text(
                'Check your backend connection',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    if (_groupedItems.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No items match your filters',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: _groupedItems.length,
        itemBuilder: (context, index) {
          final categoryName = _groupedItems.keys.elementAt(index);
          final items = _groupedItems[categoryName]!;
          final isExpanded = _expandedCategories.contains(categoryName);

          return Column(
            children: [
              _buildCategoryHeader(categoryName, items.length, isExpanded),
              if (isExpanded)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border(
                      left: BorderSide(
                        color: Color.fromARGB(255, 27, 84, 78).withOpacity(0.3),
                        width: 1,
                      ),
                      right: BorderSide(
                        color: Color.fromARGB(255, 27, 84, 78).withOpacity(0.3),
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: Color.fromARGB(255, 27, 84, 78).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Column(
                      children: [
                        ...items.map((item) {
                          final id = int.tryParse(item['id'].toString()) ?? 0;
                          final isSelected = _selectedItems.contains(id);
                          return _buildSelectableItem(item, id, isSelected);
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryHeader(String categoryName, int count, bool isExpanded) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedCategories.remove(categoryName);
          } else {
            _expandedCategories.add(categoryName);
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 27, 84, 78).withOpacity(0.1),
          borderRadius:
              isExpanded
                  ? BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  )
                  : BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
              color: Color.fromARGB(255, 27, 84, 78),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                categoryName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 27, 84, 78),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 27, 84, 78).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 27, 84, 78),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableItem(
    Map<String, dynamic> item,
    int id,
    bool isSelected,
  ) {
    final imageUrl = item['image_url']?.toString();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color:
              isSelected ? Color.fromARGB(255, 27, 84, 78) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color:
            isSelected
                ? Color.fromARGB(255, 27, 84, 78).withOpacity(0.05)
                : Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedItems.remove(id);
              } else {
                _selectedItems.add(id);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                _buildCheckbox(isSelected),
                SizedBox(width: 12),
                // Item image if available
                if (hasImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                    ),
                  ),
                  SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['name'] ?? 'Item',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Type badge (Veg/Non-Veg) - FSSAI logo
                          VegNonVegLogo(type: item['type'], size: 12),
                        ],
                      ),
                      // Jain label (if applicable)
                      if (_isJainItem(item['type'])) ...[
                        SizedBox(height: 3),
                        Text(
                          'Jain',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                      SizedBox(height: 4),
                      // Price
                      Text(
                        '₹${item['price']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color.fromARGB(255, 27, 84, 78),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item['description'] != null &&
                          item['description'].toString().isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          item['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(dynamic type) {
    final normalizedType =
        type
            ?.toString()
            .toLowerCase()
            .replaceAll(' ', '')
            .replaceAll('-', '') ??
        'veg';
    if (normalizedType == 'nonveg') return Colors.red.withOpacity(0.2);
    // Treat Jain as Veg for color display
    return Colors.green.withOpacity(0.2);
  }

  Color _getTypeBorderColor(dynamic type) {
    final normalizedType =
        type
            ?.toString()
            .toLowerCase()
            .replaceAll(' ', '')
            .replaceAll('-', '') ??
        'veg';
    if (normalizedType == 'nonveg') return Colors.red.shade700;
    return Colors.green.shade700;
  }

  String _getTypeEmoji(dynamic type) {
    final normalizedType =
        type
            ?.toString()
            .toLowerCase()
            .replaceAll(' ', '')
            .replaceAll('-', '') ??
        'veg';
    if (normalizedType == 'nonveg') return '🔴';
    // Treat Jain as Veg for emoji display
    return '🟢';
  }

  bool _isJainItem(dynamic type) {
    final normalizedType =
        type
            ?.toString()
            .toLowerCase()
            .replaceAll(' ', '')
            .replaceAll('-', '') ??
        '';
    return normalizedType == 'jain';
  }

  Widget _buildCheckbox(bool isSelected) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? Color.fromARGB(255, 27, 84, 78) : Colors.white,
        border: Border.all(
          color:
              isSelected ? Color.fromARGB(255, 27, 84, 78) : Colors.grey[400]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child:
          isSelected ? Icon(Icons.check, color: Colors.white, size: 16) : null,
    );
  }

  Widget _buildSubmitButton() {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    final tomorrowFormatted =
        '${tomorrow.day}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.year}';

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info note
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'The items selected above are selected for tomorrow ($tomorrowFormatted)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 12),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedItems.isEmpty ? null : _submitItems,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add ${_selectedItems.length} Item${_selectedItems.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
