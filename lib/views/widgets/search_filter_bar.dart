import 'dart:ui';
import 'package:flutter/material.dart';

class SearchFilterBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterPressed;

  const SearchFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            // ✅ Added Teal Border
            border: Border.all(color: const Color(0xFF00695C), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search for food, messes...',
                    hintStyle: TextStyle(color: Colors.black54),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: Colors.grey.withOpacity(0.3),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                color: const Color(0xFF00695C),
                onPressed: onFilterPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
