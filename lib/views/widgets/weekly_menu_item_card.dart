// lib/views/widgets/weekly_menu_item_card.dart

import 'package:flutter/material.dart';
import 'package:Tiffinity/models/weekly_menu_model.dart';
import 'weekly_menu_widgets.dart';

class WeeklyMenuItemCard extends StatelessWidget {
  final WeeklyMenuItem item;
  final int? availability;
  final VoidCallback onToggleAvailability;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const WeeklyMenuItemCard({
    Key? key,
    required this.item,
    required this.availability,
    required this.onToggleAvailability,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = availability ?? 0;
    final isUnavailable = status == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ "UNAVAILABLE" Tag when item is unavailable
        if (isUnavailable)
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Text(
                'UNAVAILABLE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

        // ✅ Main Card with opacity based on availability
        Opacity(
          opacity: isUnavailable ? 0.5 : 1.0,
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            decoration: BoxDecoration(
              color: isUnavailable ? Colors.grey[100] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isUnavailable ? 0.03 : 0.06),
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
                  _buildItemImage(isUnavailable),
                  const SizedBox(width: 16),
                  // Item Details
                  Expanded(child: _buildItemDetails()),
                  // Actions (Horizontal layout)
                  _buildActions(status),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemImage(bool isUnavailable) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isUnavailable ? 0.05 : 0.1),
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
                    return _buildPlaceholder();
                  },
                )
                : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.restaurant, color: Colors.grey[400], size: 32),
    );
  }

  Widget _buildItemDetails() {
    // ✅ Normalize type for comparison
    final rawType = item.itemType.toLowerCase().trim();
    final normalizedType = rawType.replaceAll(' ', '').replaceAll('-', '');

    // Determine color and if it's Jain
    final isVeg = normalizedType == 'veg';
    final isJain = normalizedType == 'jain';
    final isNonVeg = normalizedType == 'nonveg';

    Color getTypeColor() {
      if (isVeg || isJain) return Colors.green;
      if (isNonVeg) return Colors.red;
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

            // Item name
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
        if (item.categoryName != null) _buildCategoryBadge(),
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
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.1),
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
    );
  }

  Widget _buildActions(int status) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ Availability Toggle on top
        AvailabilityToggle(status: status, onTap: onToggleAvailability),
        const SizedBox(height: 12),

        // ✅ Edit and Delete buttons in horizontal row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit Button (Blue Pencil)
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.blue,
                  size: 18,
                ),
                onPressed: onEdit,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Edit Item',
              ),
            ),
            const SizedBox(width: 6),

            // Delete Button
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 18,
                ),
                onPressed: onDelete,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Delete Item',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
