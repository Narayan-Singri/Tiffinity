import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Tiffinity/services/subscription_service.dart';

class SubscriptionDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(Map<String, dynamic>)? onItemsUpdated;

  const SubscriptionDetailPage({
    super.key,
    required this.order,
    this.onItemsUpdated,
  });

  @override
  State<SubscriptionDetailPage> createState() => _SubscriptionDetailPageState();
}

class _SubscriptionDetailPageState extends State<SubscriptionDetailPage> {
  Map<String, List<Map<String, dynamic>>> _itemsByDate = {};
  Map<String, Map<int, bool>> _selectedItems = {};
  String? _tomorrowDate;
  bool _isSaving = false;
  bool _isLoading = true;
  int? _messId;

  @override
  void initState() {
    super.initState();
    _messId =
        widget.order['mess_id'] as int? ?? widget.order['messId'] as int? ?? 1;
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    setState(() => _isLoading = true);
    try {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));

      final todayStr = DateFormat('yyyy-MM-dd').format(today);
      final tomorrowStr = DateFormat('yyyy-MM-dd').format(tomorrow);

      print('📅 Loading menus for Mess ID: $_messId');
      print('📅 Today: $todayStr, Tomorrow: $tomorrowStr');

      // Fetch today's and tomorrow's menus
      final menus = await SubscriptionService.getMenus(
        messId: _messId!,
        startDate: todayStr,
        endDate: tomorrowStr,
      );

      print('📦 Fetched ${menus.length} menu records from backend');

      final grouped = <String, List<Map<String, dynamic>>>{};

      // Extract lunch items for today and tomorrow
      for (var menu in menus) {
        final mealTime = menu['meal_time']?.toString() ?? '';
        final date = menu['date']?.toString() ?? '';
        final items = menu['items'];

        print('📋 Menu: date=$date, mealTime=$mealTime');

        // Only process lunch items for today and tomorrow
        if (mealTime.toLowerCase() == 'lunch' &&
            (date == todayStr || date == tomorrowStr)) {
          List<Map<String, dynamic>> parsedItems = [];

          if (items is String) {
            try {
              final decoded = jsonDecode(items);
              parsedItems =
                  (decoded as List)
                      .map((item) => Map<String, dynamic>.from(item))
                      .toList();
            } catch (e) {
              print('⚠️ Error decoding items JSON: $e');
            }
          } else if (items is List) {
            parsedItems =
                items.map((item) => Map<String, dynamic>.from(item)).toList();
          }

          if (parsedItems.isNotEmpty) {
            grouped[date] = parsedItems;
            print('✅ Added ${parsedItems.length} items for $date');
          }
        }
      }

      // If no menu items found, fall back to selected_items from order
      if (grouped.isEmpty) {
        print(
          '⚠️ No menu items found from backend, using order selected_items',
        );
        _organizeItemsByDate();
      } else {
        _itemsByDate = grouped;
      }

      _identifyTomorrow();
      _initializeSelections();

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error loading menu items: $e');
      // Fallback to selected_items
      _organizeItemsByDate();
      _identifyTomorrow();
      _initializeSelections();
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading menu: $e')));
      }
    }
  }

  void _organizeItemsByDate() {
    final items =
        (widget.order['selected_items'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final grouped = <String, List<Map<String, dynamic>>>{};

    print('📦 Organizing ${items.length} items from order by date...');

    for (final item in items) {
      final date = item['date']?.toString() ?? '';
      if (date.isNotEmpty) {
        grouped.putIfAbsent(date, () => []);
        grouped[date]!.add(item);
      }
    }

    // Sort dates chronologically
    final sortedKeys =
        grouped.keys.toList()..sort((a, b) {
          try {
            return DateTime.parse(a).compareTo(DateTime.parse(b));
          } catch (e) {
            return a.compareTo(b);
          }
        });

    _itemsByDate = {for (var key in sortedKeys) key: grouped[key]!};

    print(
      '✅ Organized into ${_itemsByDate.length} date groups: ${_itemsByDate.keys.toList()}',
    );
  }

  void _identifyTomorrow() {
    // Get current date (normalized to midnight for accurate comparison)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final tomorrowStr = DateFormat('yyyy-MM-dd').format(tomorrow);

    print('🗓️ Current DateTime: $now');
    print('🗓️ Today (normalized): $todayStr');
    print('🗓️ Tomorrow: $tomorrowStr');
    print('🗓️ Available dates from backend: ${_itemsByDate.keys.toList()}');

    // Priority 1: Check if tomorrow's date exists in the backend data
    if (_itemsByDate.containsKey(tomorrowStr)) {
      _tomorrowDate = tomorrowStr;
      print('✅ Tomorrow\'s date found in backend data: $_tomorrowDate');
    }
    // Priority 2: If tomorrow not available, use today's date as editable
    else if (_itemsByDate.containsKey(todayStr)) {
      _tomorrowDate = todayStr;
      print(
        '⚠️ Tomorrow\'s date not found. Using today\'s date as editable: $_tomorrowDate',
      );
    }
    // Priority 3: Find any future date
    else {
      print(
        '❌ Neither today nor tomorrow found. Looking for any future date...',
      );
      for (final dateStr in _itemsByDate.keys) {
        try {
          final itemDate = DateTime.parse(dateStr);
          final itemDateNormalized = DateTime(
            itemDate.year,
            itemDate.month,
            itemDate.day,
          );

          print(
            '  Checking date: $dateStr (normalized: ${DateFormat('yyyy-MM-dd').format(itemDateNormalized)})',
          );

          if (itemDateNormalized.isAfter(today)) {
            _tomorrowDate = dateStr;
            print('✅ Using next future date as editable: $_tomorrowDate');
            break;
          }
        } catch (e) {
          print('⚠️ Error parsing date $dateStr: $e');
        }
      }

      if (_tomorrowDate == null) {
        print('❌ No future dates found. Using today\'s date if available.');
        if (_itemsByDate.isNotEmpty) {
          _tomorrowDate = _itemsByDate.keys.last;
          print('✅ Using latest available date: $_tomorrowDate');
        }
      }
    }
  }

  void _initializeSelections() {
    if (_tomorrowDate == null) return;

    final tomorrowItems = _itemsByDate[_tomorrowDate] ?? [];
    _selectedItems[_tomorrowDate!] = {};

    for (final item in tomorrowItems) {
      final itemId = item['id'];
      if (itemId != null) {
        _selectedItems[_tomorrowDate!]![itemId] = true;
      }
    }
  }

  void _toggleItem(String date, int itemId, bool value) {
    setState(() {
      _selectedItems[date] ??= {};
      _selectedItems[date]![itemId] = value;
    });
  }

  Future<void> _saveSelection() async {
    if (_tomorrowDate == null) return;

    final List<int> selectedIds =
        _selectedItems[_tomorrowDate]!.entries
            .where((e) => e.value == true)
            .map((e) => e.key)
            .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Ensure this key matches your API response ('id' or 'order_id')
      final String orderId =
          widget.order['id']?.toString() ??
          widget.order['order_id']?.toString() ??
          '';

      final result = await SubscriptionService.updateOrderItems(
        orderId: orderId,
        date: _tomorrowDate!,
        selectedItemIds: selectedIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Selection Saved Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _formatDate(String dateStr) {
    try {
      // Parse the date from backend (assumes yyyy-MM-dd format)
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();

      // Normalize dates to midnight for accurate day comparison
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(date.year, date.month, date.day);

      // Calculate difference in days from today
      final difference = dateOnly.difference(today).inDays;

      print(
        '📅 Formatting date: $dateStr | Difference from today: $difference days',
      );

      if (difference == 0) {
        return 'Today (${DateFormat('MMM d').format(date)})';
      } else if (difference == 1) {
        return 'Tomorrow (${DateFormat('MMM d').format(date)})';
      } else if (difference == -1) {
        return 'Yesterday (${DateFormat('MMM d').format(date)})';
      } else if (difference > 1 && difference <= 7) {
        // Show day name for dates within a week
        return '${DateFormat('EEEE').format(date)} (${DateFormat('MMM d').format(date)})';
      } else if (difference < -1 && difference >= -7) {
        // For past dates within a week
        return '${DateFormat('EEEE').format(date)} (${DateFormat('MMM d').format(date)})';
      } else {
        return DateFormat('EEEE, MMM d, yyyy').format(date);
      }
    } catch (e) {
      print('⚠️ Error formatting date $dateStr: $e');
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final messName = widget.order['mess_name']?.toString() ?? 'Mess';
    final planName = widget.order['plan_name']?.toString() ?? 'Plan';
    final status = widget.order['status']?.toString() ?? 'pending';

    return Scaffold(
      appBar: AppBar(
        title: Text(messName),
        backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        planName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _statusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.order['start_date']} to ${widget.order['end_date']}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${widget.order['total_amount']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Items by Date
            const Text(
              'Order Items',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_itemsByDate.isEmpty)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No menu items available',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ..._itemsByDate.entries.map((entry) {
                final date = entry.key;
                final items = entry.value;
                final isTomorrow = date == _tomorrowDate;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                          255,
                          27,
                          84,
                          78,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: const Color.fromARGB(255, 27, 84, 78),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(date),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 27, 84, 78),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'LUNCH',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (isTomorrow) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'EDITABLE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map((item) {
                      if (isTomorrow) {
                        return _EditableItemCard(
                          item: item,
                          selected: _selectedItems[date]?[item['id']] ?? true,
                          onToggle:
                              (value) => _toggleItem(date, item['id'], value),
                        );
                      } else {
                        return _ItemCard(item: item);
                      }
                    }),
                    if (isTomorrow) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              27,
                              84,
                              78,
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              _isSaving
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    'Confirm Selection for Tomorrow',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? 'Item';
    final price = item['price']?.toString() ?? '0';
    final type = item['type']?.toString() ?? 'veg';
    final imageUrl = item['image_url']?.toString();
    final isJain = type.toLowerCase() == 'jain';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Item Image (shows placeholder when missing)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child:
                (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.restaurant, color: Colors.grey[400]);
                      },
                    )
                    : Icon(Icons.restaurant, color: Colors.grey[400]),
          ),
          const SizedBox(width: 12),

          // Veg/Non-veg indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: type == 'non-veg' ? Colors.red : Colors.green,
              border: Border.all(
                color: type == 'non-veg' ? Colors.red : Colors.green,
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Item name and Jain label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isJain) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'JAIN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Price
          Text(
            '₹$price',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool selected;
  final Function(bool) onToggle;

  const _EditableItemCard({
    required this.item,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? 'Item';
    final price = item['price']?.toString() ?? '0';
    final type = item['type']?.toString() ?? 'veg';
    final imageUrl = item['image_url']?.toString();
    final isJain = type.toLowerCase() == 'jain';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              selected
                  ? const Color.fromARGB(255, 27, 84, 78)
                  : Colors.grey[300]!,
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (value) => onToggle(value ?? false),
            activeColor: const Color.fromARGB(255, 27, 84, 78),
          ),
          const SizedBox(width: 8),

          // Item Image (shows placeholder when missing)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child:
                (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.restaurant, color: Colors.grey[400]);
                      },
                    )
                    : Icon(Icons.restaurant, color: Colors.grey[400]),
          ),
          const SizedBox(width: 12),

          // Veg/Non-veg indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: type == 'non-veg' ? Colors.red : Colors.green,
              border: Border.all(
                color: type == 'non-veg' ? Colors.red : Colors.green,
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Item name and Jain label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: selected ? null : TextDecoration.lineThrough,
                  ),
                ),
                if (isJain) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'JAIN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Price
          Text(
            '₹$price',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              decoration: selected ? null : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}
