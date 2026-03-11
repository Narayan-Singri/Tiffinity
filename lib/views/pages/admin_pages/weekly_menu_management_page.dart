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
      debugPrint('Error in _loadMessId: $e');
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
      debugPrint('Error loading data: $e');
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
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(
              color: Color.fromARGB(255, 27, 84, 78)))
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
  // APP BAR (Professional Rounded Design)
  // ============================================
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color.fromARGB(255, 27, 84, 78),
      elevation: 2,
      shadowColor: Colors.black38,
      automaticallyImplyLeading: false,
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(60),
          bottomRight: Radius.circular(60),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Menu',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              _isWeeklyMode ? 'Plan Entire Week' : 'Today\'s Menu',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
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
              // Premium subtle calendar watermark
              Positioned(
                right: -20,
                top: 10,
                child: Icon(
                  Icons.calendar_month,
                  size: 130,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ],
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
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 27, 84, 78),
              const Color.fromARGB(255, 38, 114, 106),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
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
                fontSize: 13,
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
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 27, 84, 78),
              const Color.fromARGB(255, 38, 114, 106),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
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
                      fontSize: 13,
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        height: 60,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.transparent,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          onTap: (index) => setState(() => _selectedDay = _days[index]),
          tabs: _days
              .map(
                (day) => DayTab(day: day, isSelected: _selectedDay == day),
          )
              .toList(),
        ),
      ),
    );
  }

  // ============================================
  // MENU LIST & EMPTY STATE
  // ============================================
  Widget _buildMenuList() {
    final filteredItems = _weeklyMenu.where((item) {
      final dayValue = item.days[_selectedDay];
      return dayValue != null;
    }).toList();

    if (filteredItems.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5)
                  ],
                ),
                child: Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade300),
              ),
              const SizedBox(height: 24),
              Text(
                'No items scheduled',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the Add Items button below to assign dishes to ${_selectedDay[0].toUpperCase()}${_selectedDay.substring(1)}.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 100), // Space for FAB
      sliver: SliverList(
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
      ),
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Remove Item'),
          ],
        ),
        content: Text(
          'Remove this item from ${_selectedDay[0].toUpperCase()}${_selectedDay.substring(1)}?',
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
            child: const Text('Remove'),
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

  Future<void> _editMenuItem(WeeklyMenuItem item) async {
    final itemData = {
      'id': item.menuItemId,
      'name': item.itemName,
      'price': item.price,
      'description': item.description,
      'image_url': item.imageUrl,
      'type': item.itemType,
      'category': item.categoryName,
      'is_available': 1,
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMenuItemPage(messId: _messId!, existingItem: itemData),
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
    return FloatingActionButton.extended(
      onPressed: _showAddItemsDialog,
      backgroundColor: const Color.fromARGB(255, 27, 84, 78),
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        'Add Items',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      elevation: 4,
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
      builder: (context) => AddWeeklyItemsPage(
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