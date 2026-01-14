// views/pages/admin_pages/weekly_menu_management_page.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:Tiffinity/data/constants.dart';
import 'package:Tiffinity/services/menu_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Tiffinity/models/weekly_menu_model.dart';

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
  bool _isWeeklyMode = true; // Toggle between weekly and daily mode

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
    print('🚀 WEEKLY MENU PAGE INIT STARTED');
    _tabController = TabController(length: _days.length, vsync: this);
    _selectedWeekStart = _getWeekStart(DateTime.now());
    print('📅 Selected week start: $_selectedWeekStart');
    _loadMessId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  String _formatWeekStart(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadMessId() async {
    print('⭐ _loadMessId() STARTED');
    try {
      final prefs = await SharedPreferences.getInstance();
      print('✅ SharedPreferences loaded');
      final messId = prefs.getInt('mess_id');
      print('🔑 Mess ID from prefs: $messId');

      if (messId != null) {
        setState(() => _messId = messId);
        print('✅ Mess ID set: $_messId');
        print('🔄 Calling _loadData()...');
        await _loadData();
      } else {
        print('❌ No mess_id found in SharedPreferences');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mess not configured. Please complete setup first.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR in _loadMessId: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadData() async {
    if (_messId == null) {
      print('❌ No mess ID found');
      return;
    }

    print('🔄 Starting to load data for mess_id: $_messId');
    setState(() => _isLoading = true);

    try {
      final weekStartStr = _formatWeekStart(_selectedWeekStart);
      print('📅 Week start date: $weekStartStr');

      // Step 1: Get weekly menu
      print('🔄 Fetching weekly menu...');
      final weeklyMenu = await MenuService.getWeeklyMenu(
        messId: _messId!,
        weekStartDate: weekStartStr,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ Weekly menu API timed out');
          return <WeeklyMenuItem>[];
        },
      );
      print('✅ Weekly menu loaded: ${weeklyMenu.length} items');

      // Step 2: Get all menu items
      print('🔄 Fetching all menu items...');
      final allItems = await MenuService.getMenuItems(_messId!).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ Menu items API timed out');
          return <Map<String, dynamic>>[];
        },
      );
      print('✅ All menu items loaded: ${allItems.length} items');

      if (mounted) {
        setState(() {
          _weeklyMenu = weeklyMenu;
          _allMenuItems = allItems;
          _isLoading = false;
        });
        print('✅ UI updated successfully');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading data: $e');
      print('📍 Stack trace: $stackTrace');

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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
                  _buildGlassAppBar(),
                  _buildModeToggle(),
                  if (_isWeeklyMode) _buildWeekSelector(),
                  _buildDayTabs(),
                  _buildMenuList(),
                ],
              ),
      floatingActionButton: _buildAddMenuFAB(),
    );
  }

  // ============================================
  // GLASSMORPHIC APP BAR
  // ============================================
  Widget _buildGlassAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
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
              titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
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
                    _isWeeklyMode ? 'Plan Entire Week' : 'Daily Updates',
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
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _glassIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Center(child: Icon(icon, color: Colors.white, size: 20)),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // MODE TOGGLE (Weekly vs Daily)
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
              child: _buildModeOption(
                icon: Icons.view_week_rounded,
                label: 'Weekly Plan',
                isSelected: _isWeeklyMode,
                onTap: () => setState(() => _isWeeklyMode = true),
              ),
            ),
            Expanded(
              child: _buildModeOption(
                icon: Icons.today_rounded,
                label: 'Daily Update',
                isSelected: !_isWeeklyMode,
                onTap: () => setState(() => _isWeeklyMode = false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 27, 84, 78),
                      const Color.fromARGB(255, 27, 84, 78).withOpacity(0.8),
                    ],
                  )
                  : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isSelected
                  ? [
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
                  ]
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // WEEK SELECTOR (Only in Weekly Mode)
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
            _weekNavButton(
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
            _weekNavButton(
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

  Widget _weekNavButton({required IconData icon, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
          ),
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
          onTap: (index) {
            setState(() => _selectedDay = _days[index]);
          },
          tabs: _days.map((day) => _buildDayTab(day)).toList(),
        ),
      ),
    );
  }

  Widget _buildDayTab(String day) {
    final isSelected = _selectedDay == day;
    final dayName = day[0].toUpperCase() + day.substring(1, 3);

    return Tab(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 27, 84, 78),
                      const Color.fromARGB(255, 27, 84, 78).withOpacity(0.8),
                    ],
                  )
                  : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow:
              isSelected
                  ? [
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
                  ]
                  : null,
        ),
        child: Text(
          dayName,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ============================================
  // MENU LIST
  // ============================================
  Widget _buildMenuList() {
    // ✅ Show only items where day value is 0 or 1 (not null)
    final filteredItems =
        _weeklyMenu.where((item) {
          final dayValue = item.days[_selectedDay];
          // Show if day is 0 or 1, hide if null
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
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildWeeklyMenuItem(filteredItems[index]),
        childCount: filteredItems.length,
      ),
    );
  }

  Widget _buildWeeklyMenuItem(WeeklyMenuItem item) {
    final availability = item.days[_selectedDay];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Item Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.restaurant,
                                color: Colors.grey[400],
                                size: 32,
                              ),
                            );
                          },
                        )
                        : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.restaurant,
                            color: Colors.grey[400],
                            size: 32,
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 16),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child:
                            item.itemType.toLowerCase() == 'veg'
                                ? Symbols.vegSymbol
                                : Symbols.nonVegSymbol,
                      ),
                      Expanded(
                        child: Text(
                          item.itemName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (item.categoryName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                          255,
                          27,
                          84,
                          78,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.categoryName!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color.fromARGB(255, 27, 84, 78),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 27, 84, 78),
                    ),
                  ),
                ],
              ),
            ),

            // Availability Toggle
            Column(
              children: [
                _buildAvailabilityToggle(item, availability),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () => _deleteWeeklyMenuItem(item.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityToggle(WeeklyMenuItem item, int? availability) {
    // ✅ Treat null as 0 (unavailable)
    final status = availability ?? 0;

    Color getColor(int status) {
      return status == 1 ? Colors.green : Colors.red;
    }

    IconData getIcon(int status) {
      return status == 1 ? Icons.check_circle : Icons.cancel;
    }

    return GestureDetector(
      onTap: () => _cycleAvailability(item, status),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: getColor(status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: getColor(status), width: 2),
        ),
        child: Icon(getIcon(status), color: getColor(status), size: 24),
      ),
    );
  }

  Future<void> _cycleAvailability(WeeklyMenuItem item, int? current) async {
    // ✅ NEW: Simple toggle between 1 and 0 only
    int next;
    if (current == 1) {
      next = 0; // Available → Unavailable
    } else {
      next = 1; // Unavailable → Available
    }

    final success = await MenuService.updateDayAvailability(
      id: item.id,
      day: _selectedDay,
      availability: next,
    );

    if (success) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.itemName} marked as ${next == 1 ? 'available' : 'unavailable'}',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteWeeklyMenuItem(int id) async {
    final confirmed = await showDialog(
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
      // ✅ FIXED: Pass the current selected day
      final success = await MenuService.deleteWeeklyMenuItem(id, _selectedDay);

      if (success) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Item removed from ${_selectedDay[0].toUpperCase()}${_selectedDay.substring(1)}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    // ✅ Add null checks
    if (_messId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mess ID not found. Please restart the app.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_allMenuItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No menu items available. Please add items first in Menu Management.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _AddItemsSheet(
            messId: _messId!,
            weekStartDate: _formatWeekStart(_selectedWeekStart),
            selectedDay: _selectedDay,
            allItems: _allMenuItems,
            onItemsAdded: _loadData,
          ),
    );
  }
}

// ============================================
// ADD ITEMS BOTTOM SHEET
// ============================================
class _AddItemsSheet extends StatefulWidget {
  final int messId;
  final String weekStartDate;
  final String selectedDay;
  final List<Map<String, dynamic>> allItems;
  final VoidCallback onItemsAdded;

  const _AddItemsSheet({
    required this.messId,
    required this.weekStartDate,
    required this.selectedDay,
    required this.allItems,
    required this.onItemsAdded,
  });

  @override
  State<_AddItemsSheet> createState() => _AddItemsSheetState();
}

class _AddItemsSheetState extends State<_AddItemsSheet> {
  final Set<int> _selectedItems = {};
  final Map<int, Map<String, bool>> _daySelections =
      {}; // {itemId: {day: bool}}

  @override
  void initState() {
    super.initState();
    // Initialize with current day selected
    for (var item in widget.allItems) {
      final id = int.tryParse(item['id'].toString()) ?? 0;
      _daySelections[id] = {
        'monday': false,
        'tuesday': false,
        'wednesday': false,
        'thursday': false,
        'friday': false,
        'saturday': false,
        'sunday': false,
      };
      _daySelections[id]![widget.selectedDay] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Menu Items',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.allItems.length,
              itemBuilder: (context, index) {
                final item = widget.allItems[index];
                final id = int.tryParse(item['id'].toString()) ?? 0;
                final isSelected = _selectedItems.contains(id);

                return _buildAddableItem(item, id, isSelected);
              },
            ),
          ),

          // Add Button
          if (_selectedItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _addSelectedItems,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 27, 84, 78),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add ${_selectedItems.length} Item${_selectedItems.length > 1 ? 's' : ''} to Schedule',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddableItem(Map<String, dynamic> item, int id, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color:
              isSelected
                  ? const Color.fromARGB(255, 27, 84, 78)
                  : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Checkbox
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color.fromARGB(255, 27, 84, 78)
                                : Colors.white,
                        border: Border.all(
                          color:
                              isSelected
                                  ? const Color.fromARGB(255, 27, 84, 78)
                                  : Colors.grey[400]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
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
                    const SizedBox(width: 12),

                    // Item Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name']?.toString() ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${item['price']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 27, 84, 78),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Day Selection (when selected)
                if (isSelected) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ].asMap().entries.map((entry) {
                          final dayIndex = entry.key;
                          final dayLabel = entry.value;
                          final dayKey =
                              [
                                'monday',
                                'tuesday',
                                'wednesday',
                                'thursday',
                                'friday',
                                'saturday',
                                'sunday',
                              ][dayIndex];
                          final isDaySelected =
                              _daySelections[id]?[dayKey] ?? false;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _daySelections[id]![dayKey] = !isDaySelected;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDaySelected
                                        ? const Color.fromARGB(255, 27, 84, 78)
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                dayLabel,
                                style: TextStyle(
                                  color:
                                      isDaySelected
                                          ? Colors.white
                                          : Colors.grey[700],
                                  fontSize: 12,
                                  fontWeight:
                                      isDaySelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addSelectedItems() async {
    final items =
        _selectedItems.map((id) {
          final days = _daySelections[id]!;

          // Find the price for this menu item
          final menuItem = widget.allItems.firstWhere(
            (item) => int.parse(item['id'].toString()) == id,
            orElse: () => {},
          );
          final price = menuItem['price']?.toString() ?? '0';

          return {
            'menu_item_id': id,
            'price': price,
            // ✅ FIXED: Chosen days = 1, Unchosen days = 0 (not null)
            'monday': days['monday'] == true ? 1 : 0,
            'tuesday': days['tuesday'] == true ? 1 : 0,
            'wednesday': days['wednesday'] == true ? 1 : 0,
            'thursday': days['thursday'] == true ? 1 : 0,
            'friday': days['friday'] == true ? 1 : 0,
            'saturday': days['saturday'] == true ? 1 : 0,
            'sunday': days['sunday'] == true ? 1 : 0,
          };
        }).toList();

    print('📤 Sending items to API: $items');

    final success = await MenuService.addWeeklyMenu(
      messId: widget.messId,
      weekStartDate: widget.weekStartDate,
      items: items,
    );

    if (success) {
      widget.onItemsAdded();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Items added to weekly schedule'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add items. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
