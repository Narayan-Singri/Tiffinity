import 'package:flutter/material.dart';

class SubscriptionPage extends StatefulWidget {
  final String messId;
  final String messName;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final int? selectedDays;
  final double? selectedSubscriptionPrice;

  const SubscriptionPage({
    super.key,
    required this.messId,
    required this.messName,
    this.initialStartDate,
    this.initialEndDate,
    this.selectedDays,
    this.selectedSubscriptionPrice,
  });

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  // Top segmented preference
  List<bool> _vegSelection = [true, false];

  // Track selected items for each category
  Map<String, String?> _selectedItems = {
    'Vegetables': null,
    'Rice': null,
    'Roti': null,
    'Curd': null,
    'Dal': null,
    'Sweets': null,
  };

  final Map<String, List<Map<String, String>>> _vegCategoryOptions = {
    'Vegetables': [
      {
        'name': 'Paneer Butter Masala',
        'image': 'https://via.placeholder.com/150',
      },
      {'name': 'Bhindi Fry', 'image': 'https://via.placeholder.com/150'},
    ],
    'Rice': [
      {'name': 'Steamed Rice', 'image': 'https://via.placeholder.com/150'},
      {'name': 'Jeera Rice', 'image': 'https://via.placeholder.com/150'},
    ],
    'Roti': [
      {'name': 'Phulka', 'image': 'https://via.placeholder.com/150'},
      {'name': 'Butter Roti', 'image': 'https://via.placeholder.com/150'},
    ],
    'Curd': [
      {'name': 'Plain Curd', 'image': 'https://via.placeholder.com/150'},
      {'name': 'Masala Chaas', 'image': 'https://via.placeholder.com/150'},
    ],
    'Dal': [
      {'name': 'Dal Tadka', 'image': 'https://via.placeholder.com/150'},
      {'name': 'Dal Fry', 'image': 'https://via.placeholder.com/150'},
    ],
    'Sweets': [
      {'name': 'Gulab Jamun', 'image': 'https://via.placeholder.com/150'},
      {'name': 'Rasgulla', 'image': 'https://via.placeholder.com/150'},
    ],
  };

  final Map<String, List<Map<String, String>>> _nonVegCategoryOptions = {
    'Vegetables': [
      {
        'name': 'Chicken Tikka Masala',
        'image': 'https://via.placeholder.com/150',
      },
      {'name': 'Mutton Curry', 'image': 'https://via.placeholder.com/150'},
    ],
    'Rice': [
      {'name': 'Biryani', 'image': 'https://via.placeholder.com/150'},
      {'name': 'Chicken Rice', 'image': 'https://via.placeholder.com/150'},
    ],
    'Roti': [
      {'name': 'Naan', 'image': 'https://via.placeholder.com/150'},
      {'name': 'Butter Naan', 'image': 'https://via.placeholder.com/150'},
    ],
    'Curd': [
      {'name': 'Plain Yogurt', 'image': 'https://via.placeholder.com/150'},
      {'name': 'Spiced Yogurt', 'image': 'https://via.placeholder.com/150'},
    ],
    'Dal': [
      {'name': 'Dal Makhani', 'image': 'https://via.placeholder.com/150'},
      {'name': 'Urad Dal', 'image': 'https://via.placeholder.com/150'},
    ],
    'Sweets': [
      {'name': 'Gulab Jamun', 'image': 'https://via.placeholder.com/150'},
      {'name': 'Rasgulla', 'image': 'https://via.placeholder.com/150'},
    ],
  };

  bool get _isVeg => _vegSelection.first;

  void _togglePreference(int index) {
    setState(() {
      _vegSelection = [index == 0, index == 1];
    });
  }

  void _showOptions(String category) {
    final categoryMap = _isVeg ? _vegCategoryOptions : _nonVegCategoryOptions;
    final items = categoryMap[category] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$category Options',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isVeg ? 'Veg' : 'Non-Veg',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isVeg ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedItems[category] = item['name']!;
                            });
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    item['image']!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                          ),
                                        ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['name']!,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          _isVeg
                                              ? Icons.eco_outlined
                                              : Icons.set_meal,
                                          color:
                                              _isVeg
                                                  ? Colors.green
                                                  : Colors.red,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  final String _thaliImageUrl =
      'https://via.placeholder.com/400x400?text=Thali';

  Widget _buildPlateItem(String label, IconData icon, Alignment alignment) {
    final isSelected = _selectedItems[label] != null;

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onTap: () => _showOptions(label),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green[100] : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
                border:
                    isSelected
                        ? Border.all(color: Colors.green, width: 2)
                        : null,
              ),
              child: Icon(
                icon,
                color:
                    isSelected
                        ? Colors.green[700]
                        : (_isVeg ? Colors.green[700] : Colors.orange[700]),
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.green[700] : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: Text(
                widget.messName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            ToggleButtons(
              isSelected: _vegSelection,
              borderRadius: BorderRadius.circular(24),
              selectedColor: Colors.white,
              color: Colors.grey[700],
              fillColor: Colors.green,
              constraints: const BoxConstraints(minWidth: 120, minHeight: 44),
              onPressed: _togglePreference,
              children: const [Text('Veg'), Text('Non-Veg')],
            ),
            const SizedBox(height: 20),
            const Text(
              'Build your thali',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 360,
                      height: 360,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFDF7E3), Color(0xFFF3E5D7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                    ),
                    ClipOval(
                      child: SizedBox(
                        width: 320,
                        height: 320,
                        child: Image.network(
                          _thaliImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.restaurant,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      width: 360,
                      height: 360,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.08),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    _buildPlateItem(
                      'Vegetables',
                      Icons.grass,
                      const Alignment(0, -0.45),
                    ),
                    _buildPlateItem(
                      'Rice',
                      Icons.rice_bowl,
                      const Alignment(0.55, -0.25),
                    ),
                    _buildPlateItem(
                      'Roti',
                      Icons.flatware,
                      const Alignment(0.55, 0.25),
                    ),
                    _buildPlateItem(
                      'Curd',
                      Icons.icecream_outlined,
                      const Alignment(0, 0.40),
                    ),
                    _buildPlateItem(
                      'Dal',
                      Icons.local_dining,
                      const Alignment(-0.55, 0.25),
                    ),
                    _buildPlateItem(
                      'Sweets',
                      Icons.cake_outlined,
                      const Alignment(-0.55, -0.25),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Items:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ..._selectedItems.entries
                      .where((e) => e.value != null)
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${e.key}: ${e.value}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  if (_selectedItems.values.every((v) => v == null))
                    Text(
                      'No items selected yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Check if all items are selected
                  final unselectedCategories =
                      _selectedItems.entries
                          .where((e) => e.value == null)
                          .map((e) => e.key)
                          .toList();

                  if (unselectedCategories.isEmpty) {
                    // All items selected, proceed directly
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selection saved. New flow coming soon'),
                      ),
                    );
                  } else {
                    // Show confirmation dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Incomplete Selection'),
                          content: Text(
                            'You have not selected items for:\n${unselectedCategories.join(', ')}\n\nAre you sure you want to continue?',
                            style: const TextStyle(fontSize: 14),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close dialog
                              },
                              child: const Text(
                                'No',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop(); // Close dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Selection saved. New flow coming soon',
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Yes',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: const Text(
                  'Confirm & Next',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
