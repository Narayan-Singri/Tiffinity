// lib/views/pages/admin_pages/add_weekly_items_page.dart

import 'package:Tiffinity/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:Tiffinity/services/menu_service.dart';
import 'package:Tiffinity/views/widgets/filter_chips.dart' as CustomChips;
import 'package:Tiffinity/views/pages/admin_pages/add_menu_item_page.dart';

class AddWeeklyItemsPage extends StatefulWidget {
  final int messId;
  final String weekStartDate;
  final String selectedDay;
  final List<Map<String, dynamic>> allItems;

  const AddWeeklyItemsPage({
    Key? key,
    required this.messId,
    required this.weekStartDate,
    required this.selectedDay,
    required this.allItems,
  }) : super(key: key);

  @override
  State<AddWeeklyItemsPage> createState() => _AddWeeklyItemsPageState();
}

class _AddWeeklyItemsPageState extends State<AddWeeklyItemsPage> {
  final Set<int> _selectedItems = {};
  final Map<int, Map<String, bool>> _daySelections = {};
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedCategories = {};

  List<Category> _categories = [];
  String _searchQuery = '';
  String _typeFilter = 'All';
  String? _categoryFilter;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _initializeDaySelections();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeDaySelections() {
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

  Future<void> _loadCategories() async {
    try {
      final categories = await MenuService.getCategories(widget.messId);
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    return widget.allItems.where((item) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final name = item['name']?.toString().toLowerCase() ?? '';
        final description = item['description']?.toString().toLowerCase() ?? '';
        if (!name.contains(_searchQuery.toLowerCase()) &&
            !description.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      // ✅ Type filter - CHANGED from 'item_type' to 'type'
      if (_typeFilter != 'All') {
        final itemType = item['type']?.toString().toLowerCase() ?? '';
        final normalizedType = itemType.replaceAll(' ', '').replaceAll('-', '');
        if (_typeFilter == 'Veg' && normalizedType != 'veg') return false;
        if (_typeFilter == 'Non-Veg' && normalizedType != 'nonveg')
          return false;
        if (_typeFilter == 'Jain' && normalizedType != 'jain') return false;
      }

      // Category filter
      if (_categoryFilter != null && _categoryFilter != 'All') {
        final itemCategoryId = item['category_id']?.toString() ?? '';
        if (itemCategoryId != _categoryFilter) return false;
      }

      return true;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _groupedItems {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in _filteredItems) {
      // ✅ Use 'category' field (which contains the category NAME)
      final categoryName = item['category']?.toString() ?? 'Uncategorized';

      if (!grouped.containsKey(categoryName)) {
        grouped[categoryName] = [];
      }
      grouped[categoryName]!.add(item);
    }

    return grouped;
  }

  Future<void> _openAddMenuItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMenuItemPage(messId: widget.messId),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menu item added! Please reopen to select it.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
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
          const SizedBox(height: 12),
          _buildFilterChips(),
          const SizedBox(height: 16),
          _buildItemsList(),
          if (_selectedItems.isNotEmpty) _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Add Menu Items',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          _buildNewItemButton(),
        ],
      ),
    );
  }

  Widget _buildNewItemButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 27, 84, 78),
            const Color.fromARGB(255, 27, 84, 78).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openAddMenuItem,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text(
                  'New Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          CustomChips.FilterChip(
            label: 'All',
            isSelected: _typeFilter == 'All',
            onTap: () => setState(() => _typeFilter = 'All'),
          ),
          const SizedBox(width: 8),
          CustomChips.FilterChip(
            label: 'Veg',
            isSelected: _typeFilter == 'Veg',
            onTap: () => setState(() => _typeFilter = 'Veg'),
            icon: '🟢',
          ),
          const SizedBox(width: 8),
          CustomChips.FilterChip(
            label: 'Non-Veg',
            isSelected: _typeFilter == 'Non-Veg',
            onTap: () => setState(() => _typeFilter = 'Non-Veg'),
            icon: '🔴',
          ),
          const SizedBox(width: 8),
          CustomChips.FilterChip(
            label: 'Jain',
            isSelected: _typeFilter == 'Jain',
            onTap: () => setState(() => _typeFilter = 'Jain'),
            icon: '🟡',
          ),
          const SizedBox(width: 16),
          if (_categories.isNotEmpty) ...[
            Container(
              width: 1,
              color: Colors.grey[300],
              margin: const EdgeInsets.symmetric(vertical: 10),
            ),
            const SizedBox(width: 16),
            CustomChips.FilterChip(
              label: 'All Categories',
              isSelected: _categoryFilter == null || _categoryFilter == 'All',
              onTap: () => setState(() => _categoryFilter = 'All'),
            ),
            const SizedBox(width: 8),
            ..._categories.map((cat) {
              final catId = cat.id.toString();
              final catName = cat.name;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CustomChips.FilterChip(
                  label: catName,
                  isSelected: _categoryFilter == catId,
                  onTap: () => setState(() => _categoryFilter = catId),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (_isLoadingCategories) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (_groupedItems.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No items found',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _groupedItems.length,
        itemBuilder: (context, index) {
          final categoryName = _groupedItems.keys.elementAt(index);
          final items = _groupedItems[categoryName]!;
          final isExpanded = _expandedCategories.contains(categoryName);

          return Column(
            children: [
              _buildCategoryHeader(categoryName, items.length, isExpanded),
              if (isExpanded)
                ...items.map((item) {
                  final id = int.tryParse(item['id'].toString()) ?? 0;
                  final isSelected = _selectedItems.contains(id);
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8),
                    child: _buildAddableItem(item, id, isSelected),
                  );
                }).toList(),
              const SizedBox(height: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
              color: const Color.fromARGB(255, 27, 84, 78),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                categoryName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 27, 84, 78),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
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
        color:
            isSelected
                ? const Color.fromARGB(255, 27, 84, 78).withOpacity(0.05)
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
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildCheckbox(isSelected),
                    const SizedBox(width: 12),
                    Expanded(child: _buildItemInfo(item)),
                  ],
                ),
                if (isSelected) _buildDaySelector(id),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool isSelected) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color:
            isSelected ? const Color.fromARGB(255, 27, 84, 78) : Colors.white,
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
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : null,
    );
  }

  Widget _buildItemInfo(Map<String, dynamic> item) {
    // ✅ Get the raw type from the correct field
    final rawItemType = item['type']?.toString() ?? '';

    // Normalize for comparison
    final itemType = rawItemType
        .toLowerCase()
        .trim()
        .replaceAll(' ', '')
        .replaceAll('-', '');

    // Check if it's Jain
    final isJain = itemType == 'jain';

    // Helper to get color
    Color getTypeColor() {
      if (itemType == 'veg') return Colors.green;
      if (itemType == 'jain') return Colors.green;
      if (itemType == 'nonveg') return Colors.red;
      return Colors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Veg/Non-Veg/Jain indicator column
            Column(
              children: [
                // Circle indicator
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    border: Border.all(color: getTypeColor(), width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.circle, size: 10, color: getTypeColor()),
                ),

                // ✅ Jain Tag below the circle
                if (isJain) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        255,
                        27,
                        84,
                        78,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: const Color.fromARGB(255, 27, 84, 78),
                        width: 0.8,
                      ),
                    ),
                    child: const Text(
                      'JAIN',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 27, 84, 78),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 8),

            Expanded(
              child: Text(
                item['name']?.toString() ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
    );
  }

  Widget _buildDaySelector(int id) {
    return Column(
      children: [
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
                final isDaySelected = _daySelections[id]?[dayKey] ?? false;

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
                        color: isDaySelected ? Colors.white : Colors.grey[700],
                        fontSize: 12,
                        fontWeight:
                            isDaySelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return Container(
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
    );
  }

  Future<void> _addSelectedItems() async {
    final items =
        _selectedItems.map((id) {
          final days = _daySelections[id]!;
          final menuItem = widget.allItems.firstWhere(
            (item) => int.parse(item['id'].toString()) == id,
            orElse: () => {},
          );
          final price = menuItem['price']?.toString() ?? '0';

          return {
            'menu_item_id': id,
            'price': price,
            'monday': days['monday'] == true ? 1 : null,
            'tuesday': days['tuesday'] == true ? 1 : null,
            'wednesday': days['wednesday'] == true ? 1 : null,
            'thursday': days['thursday'] == true ? 1 : null,
            'friday': days['friday'] == true ? 1 : null,
            'saturday': days['saturday'] == true ? 1 : null,
            'sunday': days['sunday'] == true ? 1 : null,
          };
        }).toList();

    final success = await MenuService.addWeeklyMenu(
      messId: widget.messId,
      weekStartDate: widget.weekStartDate,
      items: items,
    );

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Items added to weekly schedule'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
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
