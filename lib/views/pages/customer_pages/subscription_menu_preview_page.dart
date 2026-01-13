import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SubscriptionMenuPreviewPage extends StatefulWidget {
  final String messId;
  final String messName;
  final DateTime startDate;
  final DateTime endDate;
  final int selectedDays;
  final double selectedPrice;

  const SubscriptionMenuPreviewPage({
    super.key,
    required this.messId,
    required this.messName,
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
  // TODO: Fetch from backend API based on messId and date
  // Veg menu categories - will be populated from backend
  List<Map<String, dynamic>> _vegMenuCategories = [];

  // TODO: Fetch from backend API based on messId and date
  // Non-Veg menu categories - will be populated from backend
  List<Map<String, dynamic>> _nonVegMenuCategories = [];

  // Track selected items for today - veg
  Map<String, String?> _todayVegSelections = {};

  // Track selected items for tomorrow - veg
  Map<String, String?> _tomorrowVegSelections = {};

  // Track selected items for today - non-veg
  Map<String, String?> _todayNonVegSelections = {};

  // Track selected items for tomorrow - non-veg
  Map<String, String?> _tomorrowNonVegSelections = {};

  // Track veg/non-veg preference
  bool _isVeg = true;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMenuData();
  }

  // TODO: Replace with actual API call to backend
  Future<void> _fetchMenuData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Replace this with actual API call
    // Example: final response = await MenuService.fetchMenu(widget.messId, today, tomorrow);
    
    // Simulated data - Replace with actual backend response
    _vegMenuCategories = [
      {
        'category': 'Vegetables',
        'options': [
          {'name': 'Paneer Butter Masala', 'image': 'https://via.placeholder.com/80'},
          {'name': 'Bhindi Fry', 'image': 'https://via.placeholder.com/80'},
        ],
      },
      {
        'category': 'Rice',
        'options': [
          {'name': 'Steamed Rice', 'image': 'https://via.placeholder.com/80'},
          {'name': 'Jeera Rice', 'image': 'https://via.placeholder.com/80'},
        ],
      },
      {
        'category': 'Roti',
        'options': [
          {'name': 'Phulka (4 pcs)', 'image': 'https://via.placeholder.com/80'},
          {'name': 'Tandoori Roti (4 pcs)', 'image': 'https://via.placeholder.com/80'},
        ],
      },
      {
        'category': 'Curd',
        'options': [
          {'name': 'Plain Curd', 'image': 'https://via.placeholder.com/80'},
          {'name': 'Masala Chaas', 'image': 'https://via.placeholder.com/80'},
        ],
      },
      {
        'category': 'Dal',
        'options': [
          {'name': 'Dal Tadka', 'image': 'https://via.placeholder.com/80'},
          {'name': 'Dal Fry', 'image': 'https://via.placeholder.com/80'},
        ],
      },
      {
        'category': 'Sweets',
        'options': [
          {'name': 'Gulab Jamun', 'image': 'https://via.placeholder.com/80'},
          {'name': 'Jalebi', 'image': 'https://via.placeholder.com/80'},
        ],
      },
    ];

    _nonVegMenuCategories = [
      {
        'category': 'Main Course',
        'options': [
          {'name': 'Butter Chicken', 'image': 'https://via.placeholder.com/80'},
          {'name': 'Chicken Tikka Masala', 'image': 'https://via.placeholder.com/80'},
        ],
      },
      {
        'category': 'Rice',
        'options': [
          {'name': 'Chicken Biryani', 'image': 'https://via.placeholder.com/80'},
          {'name': 'Egg Fried Rice', 'image': 'https://via.placeholder.com/80'},
        ],
      },
      {
        'category': 'Roti',
        'options': [
          {'name': 'Butter Naan (4 pcs)', 'image': 'https://via.placeholder.com/80'},
          {'name': 'Tandoori Roti (4 pcs)', 'image': 'https://via.placeholder.com/80'},
        ],
      },
      {
        'category': 'Side Dish',
        'options': [
          {'name': 'Chicken Kebab', 'image': 'https://via.placeholder.com/80'},
          {'name': 'Fish Fry', 'image': 'https://via.placeholder.com/80'},
        ],
      },
      {
        'category': 'Dal',
        'options': [
          {'name': 'Dal Tadka', 'image': 'https://via.placeholder.com/80'},
          {'name': 'Dal Fry', 'image': 'https://via.placeholder.com/80'},
        ],
      },
      {
        'category': 'Dessert',
        'options': [
          {'name': 'Gulab Jamun', 'image': 'https://via.placeholder.com/80'},
          {'name': 'Rasmalai', 'image': 'https://via.placeholder.com/80'},
        ],
      },
    ];

    // Initialize selection maps based on categories
    for (var category in _vegMenuCategories) {
      final categoryName = category['category'] as String;
      _todayVegSelections[categoryName] = null;
      _tomorrowVegSelections[categoryName] = null;
    }

    for (var category in _nonVegMenuCategories) {
      final categoryName = category['category'] as String;
      _todayNonVegSelections[categoryName] = null;
      _tomorrowNonVegSelections[categoryName] = null;
    }

    setState(() {
      _isLoading = false;
    });
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
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
              'Select your preferred items for each meal',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),

            // Veg/Non-Veg Toggle
            Center(

              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isVeg = true;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: _isVeg
                              ? LinearGradient(
                                  colors: [Colors.green[400]!, Colors.green[600]!],
                                )
                              : null,
                          color: _isVeg ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _isVeg
                              ? [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.eco,
                              size: 18,
                              color: _isVeg ? Colors.white : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Veg',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _isVeg ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isVeg = false;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: !_isVeg
                              ? LinearGradient(
                                  colors: [Colors.red[400]!, Colors.red[600]!],
                                )
                              : null,
                          color: !_isVeg ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: !_isVeg
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.restaurant,
                              size: 18,
                              color: !_isVeg ? Colors.white : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Non-Veg',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: !_isVeg ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView(
                children: [
                  _buildDayMenu(
                    context,
                    'Today',
                    dateFormat.format(today),
                    true,
                    _isVeg ? _todayVegSelections : _todayNonVegSelections,
                  ),
                  const SizedBox(height: 16),
                  _buildDayMenu(
                    context,
                    'Tomorrow',
                    dateFormat.format(tomorrow),
                    false,
                    _isVeg ? _tomorrowVegSelections : _tomorrowNonVegSelections,
                  ),
                ],
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
                border: Border.all(color: Colors.green.shade300, width: 1.5),
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
                    Icon(Icons.arrow_forward, color: Colors.white, size: 20),
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
    final todayMissing = _getMissingSelections(
      _isVeg ? _todayVegSelections : _todayNonVegSelections,
    );
    final tomorrowMissing = _getMissingSelections(
      _isVeg ? _tomorrowVegSelections : _tomorrowNonVegSelections,
    );

    if (todayMissing.isNotEmpty || tomorrowMissing.isNotEmpty) {
      final confirmed =
          await _showSkipConfirmation(todayMissing, tomorrowMissing);
      if (confirmed != true) {
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proceeding to checkout')),
    );
    
    // TODO: Send selected items to backend
    // final selections = {
    //   'messId': widget.messId,
    //   'isVeg': _isVeg,
    //   'todaySelections': _isVeg ? _todayVegSelections : _todayNonVegSelections,
    //   'tomorrowSelections': _isVeg ? _tomorrowVegSelections : _tomorrowNonVegSelections,
    // };
    // await SubscriptionService.submitMenuSelections(selections);
  }

  List<String> _getMissingSelections(Map<String, String?> selections) {
    final categories = _isVeg ? _vegMenuCategories : _nonVegMenuCategories;
    return categories
        .map((category) => category['category'] as String)
        .where((categoryName) => selections[categoryName] == null)
        .toList();
  }

  Future<bool?> _showSkipConfirmation(
    List<String> todayMissing,
    List<String> tomorrowMissing,
  ) {
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You haven\'t selected an option for:',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              if (todayMissing.isNotEmpty)
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
                          'Today: ${todayMissing.join(', ')}',
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
              if (tomorrowMissing.isNotEmpty)
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
                          'Tomorrow: ${tomorrowMissing.join(', ')}',
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Yes, Skip',
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
    Map<String, String?> selections,
  ) {
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
            color: isToday
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isToday
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
          ...(_isVeg ? _vegMenuCategories : _nonVegMenuCategories).map((category) {
            final categoryName = category['category'] as String;
            final options = category['options'] as List;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(categoryName),
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...options.map((option) {
                    final item = option as Map<String, String>;
                    final isSelected = selections[categoryName] == item['name'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selections[categoryName] = item['name'];
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.green[50]
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.green.shade400
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[200],
                                  image: DecorationImage(
                                    image: NetworkImage(item['image']!),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item['name']!,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.green[900]
                                        : Colors.black87,
                                  ),
                                ),
                              ),
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
                                      isSelected
                                          ? Colors.green
                                          : Colors.transparent,
                                ),
                                child:
                                    isSelected
                                        ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                        : null,
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
          }).toList(),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Vegetables':
        return Icons.eco;
      case 'Rice':
        return Icons.rice_bowl;
      case 'Roti':
        return Icons.bakery_dining;
      case 'Curd':
        return Icons.icecream;
      case 'Dal':
        return Icons.soup_kitchen;
      case 'Sweets':
        return Icons.cake;
      case 'Main Course':
        return Icons.restaurant_menu;
      case 'Side Dish':
        return Icons.fastfood;
      case 'Dessert':
        return Icons.cake;
      default:
        return Icons.restaurant;
    }
  }
}
