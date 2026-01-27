import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Tiffinity/services/subscription_service.dart';
import 'subscription_checkout_page.dart';

class SubscriptionMenuPreviewPage extends StatefulWidget {
  final String messId;
  final String messName;
  final int planId;
  final DateTime startDate;
  final DateTime endDate;
  final int selectedDays;
  final double selectedPrice;

  const SubscriptionMenuPreviewPage({
    super.key,
    required this.messId,
    required this.messName,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.selectedDays,
    required this.selectedPrice,
  });

  @override
  State<SubscriptionMenuPreviewPage> createState() =>
      _SubscriptionMenuPreviewPageState();
}

class _SubscriptionMenuPreviewPageState
    extends State<SubscriptionMenuPreviewPage> {
  // Menu items fetched from backend
  List<Map<String, dynamic>> _todayMenuItems = [];
  List<Map<String, dynamic>> _tomorrowMenuItems = [];

  // Track selected items
  Map<int, bool> _todaySelections = {};
  Map<int, bool> _tomorrowSelections = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMenuData();
  }

  Future<void> _fetchMenuData() async {
    setState(() => _isLoading = true);

    try {
      // Get today and tomorrow dates
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));

      final todayDateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final tomorrowDateString =
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

      print('📅 Fetching menu for today: $todayDateString');
      print('📅 Fetching menu for tomorrow: $tomorrowDateString');
      print('🏢 Mess ID: ${widget.messId}');

      // Fetch menus for both days
      final menus = await SubscriptionService.getMenus(
        messId: int.parse(widget.messId),
        startDate: todayDateString,
        endDate: tomorrowDateString,
      );

      print('✅ Received ${menus.length} menus from backend');

      List<Map<String, dynamic>> todayItems = [];
      List<Map<String, dynamic>> tomorrowItems = [];

      // Parse menus and extract items for lunch
      for (var menu in menus) {
        if (menu['meal_time'] == 'lunch') {
          final items = menu['items'];
          List<Map<String, dynamic>> parsedItems = [];

          if (items is String) {
            final decoded = jsonDecode(items);
            parsedItems =
                (decoded as List).map((item) {
                  final mapped = Map<String, dynamic>.from(item);
                  mapped['menu_date'] = menu['date'];
                  mapped['meal_time'] = menu['meal_time'] ?? 'lunch';
                  mapped['id'] =
                      int.tryParse(mapped['id'].toString()) ?? mapped['id'];
                  return mapped;
                }).toList();
          } else if (items is List) {
            parsedItems =
                items.map((item) {
                  final mapped = Map<String, dynamic>.from(item);
                  mapped['menu_date'] = menu['date'];
                  mapped['meal_time'] = menu['meal_time'] ?? 'lunch';
                  mapped['id'] =
                      int.tryParse(mapped['id'].toString()) ?? mapped['id'];
                  return mapped;
                }).toList();
          }

          if (menu['date'] == todayDateString) {
            todayItems = parsedItems;
            print('📋 Today items: ${todayItems.length}');
          } else if (menu['date'] == tomorrowDateString) {
            tomorrowItems = parsedItems;
            print('📋 Tomorrow items: ${tomorrowItems.length}');
          }
        }
      }

      setState(() {
        _todayMenuItems = todayItems;
        _tomorrowMenuItems = tomorrowItems;

        // Initialize selections - all items selected by default
        for (var item in todayItems) {
          final itemId = int.tryParse(item['id'].toString()) ?? 0;
          if (itemId != 0) {
            _todaySelections[itemId] = true;
          }
        }
        for (var item in tomorrowItems) {
          final itemId = int.tryParse(item['id'].toString()) ?? 0;
          if (itemId != 0) {
            _tomorrowSelections[itemId] = true;
          }
        }

        _isLoading = false;
      });

      print('✅ Menu data loaded successfully');
    } catch (e) {
      print('❌ Error loading menu data: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading menu: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final dateFormat = DateFormat('EEEE, dd MMM yyyy');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Menu Preview'),
        backgroundColor: Colors.green[400],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.messName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Daily Menu Preview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Review and customize your meal selections',
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child:
                          (_todayMenuItems.isEmpty &&
                                  _tomorrowMenuItems.isEmpty)
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.restaurant_menu,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No menu items available',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Please contact the mess admin',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : RefreshIndicator(
                                onRefresh: _fetchMenuData,
                                child: ListView(
                                  children: [
                                    if (_todayMenuItems.isNotEmpty)
                                      _buildDayMenu(
                                        context,
                                        'Today',
                                        dateFormat.format(today),
                                        true,
                                        _todayMenuItems,
                                        _todaySelections,
                                      ),
                                    if (_todayMenuItems.isNotEmpty &&
                                        _tomorrowMenuItems.isNotEmpty)
                                      const SizedBox(height: 16),
                                    if (_tomorrowMenuItems.isNotEmpty)
                                      _buildDayMenu(
                                        context,
                                        'Tomorrow',
                                        dateFormat.format(tomorrow),
                                        false,
                                        _tomorrowMenuItems,
                                        _tomorrowSelections,
                                      ),
                                  ],
                                ),
                              ),
                    ),

                    const SizedBox(height: 16),

                    // Summary Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[50]!, Colors.green[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.shade300,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.calendar_month,
                              color: Colors.green[500],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.selectedDays} Days Subscription',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${widget.selectedPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Confirm Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[400]!, Colors.green[500]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _handleProceed,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Proceed to Checkout',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Future<void> _handleProceed() async {
    // Count unselected items
    final todayUnselected = _todaySelections.values.where((v) => !v).length;
    final tomorrowUnselected =
        _tomorrowSelections.values.where((v) => !v).length;

    if (todayUnselected > 0 || tomorrowUnselected > 0) {
      final confirmed = await _showSkipConfirmation(
        todayUnselected,
        tomorrowUnselected,
      );
      if (confirmed != true) return;
    }

    // Get selected items
    final selectedTodayItems =
        _todayMenuItems.where((item) {
          final itemId = int.tryParse(item['id'].toString()) ?? 0;
          return _todaySelections[itemId] == true;
        }).toList();
    final selectedTomorrowItems =
        _tomorrowMenuItems.where((item) {
          final itemId = int.tryParse(item['id'].toString()) ?? 0;
          return _tomorrowSelections[itemId] == true;
        }).toList();

    final combinedItems = [...selectedTodayItems, ...selectedTomorrowItems];

    print('✅ Selected today items: ${selectedTodayItems.length}');
    print('✅ Selected tomorrow items: ${selectedTomorrowItems.length}');
    print('📦 Total items to checkout: ${combinedItems.length}');

    final messIdInt = int.tryParse(widget.messId) ?? 0;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SubscriptionCheckoutPage(
              messId: messIdInt,
              messName: widget.messName,
              planId: widget.planId,
              startDate: widget.startDate,
              endDate: widget.endDate,
              selectedDays: widget.selectedDays,
              totalAmount: widget.selectedPrice,
              selectedItems: combinedItems,
            ),
      ),
    );
  }

  Future<bool?> _showSkipConfirmation(int todayCount, int tomorrowCount) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Skip Items?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have unselected items:',
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              if (todayCount > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.today, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Today: $todayCount item${todayCount > 1 ? 's' : ''} unselected',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (tomorrowCount > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tomorrow: $tomorrowCount item${tomorrowCount > 1 ? 's' : ''} unselected',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Continue without these items?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Go Back',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Yes, Continue',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayMenu(
    BuildContext context,
    String label,
    String date,
    bool isToday,
    List<Map<String, dynamic>> items,
    Map<int, bool> selections,
  ) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(Icons.restaurant, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No items for $label',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? Colors.green.shade400 : Colors.grey.shade300,
          width: isToday ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isToday
                    ? Colors.green.withOpacity(0.15)
                    : Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isToday
                            ? [Colors.green[300]!, Colors.green[500]!]
                            : [Colors.grey[300]!, Colors.grey[400]!],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: (isToday ? Colors.green[400]! : Colors.grey)
                          .withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isToday ? Icons.today : Icons.event,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  date,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            final itemId = int.tryParse(item['id'].toString()) ?? 0;
            final isSelected = selections[itemId] ?? true;
            final itemName = item['name']?.toString() ?? 'Item';
            final itemPrice = item['price']?.toString() ?? '0';
            final itemType = item['type']?.toString().toLowerCase() ?? 'veg';
            final imageUrl = item['image_url']?.toString() ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GestureDetector(
                onTap:
                    isToday
                        ? null
                        : () {
                          setState(() {
                            selections[itemId] = !isSelected;
                          });
                        },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isToday
                            ? Colors.grey[100]
                            : (isSelected ? Colors.green[50] : Colors.grey[50]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isToday
                              ? Colors.grey.shade400
                              : (isSelected
                                  ? Colors.green.shade400
                                  : Colors.grey.shade300),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Item image
                      if (imageUrl.isNotEmpty)
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[200],
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.restaurant,
                                  color: Colors.grey[400],
                                  size: 28,
                                );
                              },
                            ),
                          ),
                        ),
                      if (imageUrl.isNotEmpty) const SizedBox(width: 14),

                      // Item details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Veg/Non-veg indicator
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          itemType == 'nonveg' ||
                                                  itemType == 'non-veg'
                                              ? Colors.red
                                              : Colors.green,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color:
                                            itemType == 'nonveg' ||
                                                    itemType == 'non-veg'
                                                ? Colors.red
                                                : Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    itemName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isToday
                                              ? Colors.grey[700]
                                              : (isSelected
                                                  ? Colors.green[900]
                                                  : Colors.black87),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '₹$itemPrice',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (isToday) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Fixed',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue[800],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Checkbox - only show for tomorrow's items
                      if (!isToday)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.green
                                      : Colors.grey.shade400,
                              width: 2,
                            ),
                            color:
                                isSelected ? Colors.green : Colors.transparent,
                          ),
                          child:
                              isSelected
                                  ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                  : null,
                        ),
                      if (isToday)
                        Icon(
                          Icons.lock_outline,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
