// lib/views/pages/admin_pages/weekly_menu_management_page.dart

import 'dart:ui';
import 'package:Tiffinity/views/pages/admin_pages/add_menu_item_page.dart';
import 'package:flutter/material.dart';
import 'package:Tiffinity/services/menu_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Tiffinity/models/weekly_menu_model.dart';
import 'package:intl/intl.dart';
import 'package:Tiffinity/views/widgets/weekly_menu_widgets.dart';
import 'package:Tiffinity/views/widgets/weekly_menu_item_card.dart';
import 'package:Tiffinity/views/pages/admin_pages/add_weekly_items_page.dart';

class WeeklyMenuManagementPage extends StatefulWidget {
  const WeeklyMenuManagementPage({super.key});

  @override
  State<WeeklyMenuManagementPage> createState() =>
      _WeeklyMenuManagementPageState();
}

class _WeeklyMenuManagementPageState extends State<WeeklyMenuManagementPage>
    with SingleTickerProviderStateMixin {
  int? _messId;
  bool _isLoading = true;
  bool _isWeeklyMode = true;
  List<WeeklyMenuItem> _weeklyMenu = [];
  List<Map<String, dynamic>> _allMenuItems = [];
  DateTime _selectedWeekStart = DateTime.now();
  String _selectedDay = 'monday';
  late TabController _tabController;

  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _getTodayDayName();
    final todayIndex = _days.indexOf(_selectedDay);
    _tabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: todayIndex >= 0 ? todayIndex : 0,
    );
    _selectedWeekStart = _getWeekStart(DateTime.now());
    _loadMessId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getTodayDayName() {
    final today = DateTime.now();
    final dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return dayNames[today.weekday - 1];
  }

  String _getFormattedDate() {
    return DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  String _formatWeekStart(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadMessId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messId = prefs.getInt('mess_id');

      if (messId != null) {
        setState(() => _messId = messId);
        await _loadData();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('Mess not configured. Please complete setup first.');
        }
      }
    } catch (e) {
      print('Error in _loadMessId: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    if (_messId == null) return;

    setState(() => _isLoading = true);

    try {
      final weekStartStr = _formatWeekStart(_selectedWeekStart);

      final results = await Future.wait([
        MenuService.getWeeklyMenu(
          messId: _messId!,
          weekStartDate: weekStartStr,
        ).timeout(const Duration(seconds: 10)),
        MenuService.getMenuItems(_messId!).timeout(const Duration(seconds: 10)),
      ]);

      if (mounted) {
        setState(() {
          _weeklyMenu = results[0] as List<WeeklyMenuItem>;
          _allMenuItems = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(),
                  _buildModeToggle(),
                  if (_isWeeklyMode) _buildWeekSelector(),
                  if (!_isWeeklyMode) _buildTodayHeader(),
                  if (_isWeeklyMode) _buildDayTabs(),
                  _buildMenuList(),
                ],
              ),
      floatingActionButton: _buildAddMenuFAB(),
    );
  }

  // ============================================
  // APP BAR
  // ============================================
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color.fromARGB(255, 27, 84, 78).withOpacity(0.95),
                  const Color.fromARGB(255, 27, 84, 78).withOpacity(0.85),
                ],
              ),
            ),
            child: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isWeeklyMode ? 'Plan Entire Week' : 'Today\'s Menu',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  // ============================================
  // MODE TOGGLE
  // ============================================
  Widget _buildModeToggle() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ModeToggleButton(
                icon: Icons.view_week_rounded,
                label: 'Weekly Plan',
                isSelected: _isWeeklyMode,
                onTap: () => setState(() => _isWeeklyMode = true),
              ),
            ),
            Expanded(
              child: ModeToggleButton(
                icon: Icons.restaurant_menu_rounded,
                label: 'Today\'s Menu',
                isSelected: !_isWeeklyMode,
                onTap: () {
                  setState(() {
                    _isWeeklyMode = false;
                    _selectedDay = _getTodayDayName();
                    final todayIndex = _days.indexOf(_selectedDay);
                    _tabController.animateTo(todayIndex);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // TODAY'S HEADER
  // ============================================
  Widget _buildTodayHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 27, 84, 78),
              const Color.fromARGB(255, 27, 84, 78).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _getFormattedDate(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Showing items scheduled for today',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // WEEK SELECTOR
  // ============================================
  Widget _buildWeekSelector() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 27, 84, 78),
              const Color.fromARGB(255, 27, 84, 78).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            WeekNavButton(
              icon: Icons.chevron_left_rounded,
              onTap: () {
                setState(() {
                  _selectedWeekStart = _selectedWeekStart.subtract(
                    const Duration(days: 7),
                  );
                });
                _loadData();
              },
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Week of',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatWeekRange(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            WeekNavButton(
              icon: Icons.chevron_right_rounded,
              onTap: () {
                setState(() {
                  _selectedWeekStart = _selectedWeekStart.add(
                    const Duration(days: 7),
                  );
                });
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatWeekRange() {
    final end = _selectedWeekStart.add(const Duration(days: 6));
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (_selectedWeekStart.month == end.month) {
      return '${_selectedWeekStart.day}-${end.day} ${months[_selectedWeekStart.month - 1]} ${_selectedWeekStart.year}';
    } else {
      return '${_selectedWeekStart.day} ${months[_selectedWeekStart.month - 1]} - ${end.day} ${months[end.month - 1]}';
    }
  }

  // ============================================
  // DAY TABS
  // ============================================
  Widget _buildDayTabs() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        height: 60,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.transparent,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          onTap: (index) => setState(() => _selectedDay = _days[index]),
          tabs:
              _days
                  .map(
                    (day) => DayTab(day: day, isSelected: _selectedDay == day),
                  )
                  .toList(),
        ),
      ),
    );
  }

  // ============================================
  // MENU LIST
  // ============================================
  Widget _buildMenuList() {
    final filteredItems =
        _weeklyMenu.where((item) {
          final dayValue = item.days[_selectedDay];
          return dayValue != null;
        }).toList();

    if (filteredItems.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No items scheduled for ${_selectedDay[0].toUpperCase()}${_selectedDay.substring(1)}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap + button to add items',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = filteredItems[index];
        final availability = item.days[_selectedDay];

        return WeeklyMenuItemCard(
          item: item,
          availability: availability,
          onToggleAvailability: () => _cycleAvailability(item, availability),
          onDelete: () => _deleteWeeklyMenuItem(item.id),
          onEdit: () => _editMenuItem(item),
        );
      }, childCount: filteredItems.length),
    );
  }

  // ============================================
  // ACTIONS
  // ============================================
  Future<void> _cycleAvailability(WeeklyMenuItem item, int? current) async {
    final next = current == 1 ? 0 : 1;

    final success = await MenuService.updateDayAvailability(
      id: item.id,
      day: _selectedDay,
      availability: next,
    );

    if (success) {
      _loadData();
      _showSuccess(
        '${item.itemName} marked as ${next == 1 ? 'available' : 'unavailable'}',
      );
    }
  }

  Future<void> _deleteWeeklyMenuItem(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Item'),
            content: Text(
              'Remove this item from ${_selectedDay[0].toUpperCase()}${_selectedDay.substring(1)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await MenuService.deleteWeeklyMenuItem(id, _selectedDay);

      if (success) {
        _loadData();
        _showSuccess(
          'Item removed from ${_selectedDay[0].toUpperCase()}${_selectedDay.substring(1)}',
        );
      }
    }
  }

  // ✅ NEW METHOD: Edit menu item from weekly menu
  Future<void> _editMenuItem(WeeklyMenuItem item) async {
    // Convert WeeklyMenuItem to the format expected by AddMenuItemPage
    final itemData = {
      'id': item.menuItemId,
      'name': item.itemName,
      'price': item.price,
      'description': item.description,
      'image_url': item.imageUrl,
      'type': item.itemType,
      'category': item.categoryName,
      'is_available': 1, // Default to available
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                AddMenuItemPage(messId: _messId!, existingItem: itemData),
      ),
    );

    if (result == true) {
      _loadData();
      _showSuccess('Menu item updated successfully');
    }
  }

  // ============================================
  // ADD MENU FAB
  // ============================================
  Widget _buildAddMenuFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color.fromARGB(255, 27, 84, 78),
                  const Color.fromARGB(255, 27, 84, 78).withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: FloatingActionButton.extended(
              onPressed: _showAddItemsDialog,
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Add Items',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddItemsDialog() {
    if (_messId == null) {
      _showError('Mess ID not found. Please restart the app.');
      return;
    }

    if (_allMenuItems.isEmpty) {
      _showError(
        'No menu items available. Please add items first in Menu Management.',
      );
      return;
    }

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AddWeeklyItemsPage(
            messId: _messId!,
            weekStartDate: _formatWeekStart(_selectedWeekStart),
            selectedDay: _selectedDay,
            allItems: _allMenuItems,
          ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }
}
