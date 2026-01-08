import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:Tiffinity/data/notifiers.dart';

class CustomerNavBarWidget extends StatelessWidget {
  const CustomerNavBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Reduced side margins slightly (20) to fit 4 items comfortably
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: 65,
            decoration: BoxDecoration(
              // Subtle Teal Tint background
              color: const Color(0xFFE0F2F1).withOpacity(0.9),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00695C).withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ValueListenableBuilder<int>(
              valueListenable: customerSelectedPageNotifier,
              builder: (context, selectedIndex, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      context,
                      Icons.home_rounded,
                      'Home',
                      0,
                      selectedIndex,
                    ),
                    _buildNavItem(
                      context,
                      Icons.receipt_long_rounded,
                      'Orders',
                      1,
                      selectedIndex,
                    ),
                    _buildNavItem(
                      context,
                      Icons.subscriptions_rounded,
                      'Plans',
                      2,
                      selectedIndex,
                    ),
                    // ✅ Added Profile Option
                    _buildNavItem(
                      context,
                      Icons.person_rounded,
                      'Profile',
                      3,
                      selectedIndex,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    int selectedIndex,
  ) {
    final isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () {
        customerSelectedPageNotifier.value = index;
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8, // Tighter padding for 4 items
          vertical: 10,
        ),
        decoration:
            isSelected
                ? BoxDecoration(
                  color: const Color(0xFF00695C),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00695C).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                )
                : const BoxDecoration(color: Colors.transparent),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.blueGrey[700],
              size: 24, // Slightly smaller icon to save space
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12, // Slightly smaller text
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
