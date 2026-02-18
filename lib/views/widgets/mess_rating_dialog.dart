import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:Tiffinity/services/rating_service.dart';
import 'package:Tiffinity/services/auth_services.dart';

class MessRatingDialog extends StatefulWidget {
  final Map<String, dynamic> order;

  const MessRatingDialog({super.key, required this.order});

  @override
  State<MessRatingDialog> createState() => _MessRatingDialogState();
}

class _MessRatingDialogState extends State<MessRatingDialog> {
  int _rating = 0;
  bool _isSubmitting = false;

  String _buildItemSummary() {
    final items = widget.order['items'];

    if (items == null || items is! List || items.isEmpty) {
      return "How was your last order?";
    }

    final names = items.map((e) => e['food_name'] ?? '').toList();

    if (names.length == 1) {
      return "How was your ${names[0]}?";
    }

    if (names.length == 2) {
      return "How was your ${names[0]} & ${names[1]}?";
    }

    return "How was your ${names[0]} + ${names.length - 1} more items?";
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1B544E);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restaurant_menu, size: 48, color: primary),
                const SizedBox(height: 16),

                Text(
                  _buildItemSummary(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() => _rating = index + 1);
                      },
                      icon: Icon(
                        index < _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 34,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: primary,
                    ),
                    onPressed:
                        _rating == 0 || _isSubmitting ? null : _submitRating,
                    child:
                        _isSubmitting
                            ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              "Submit",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);

    final currentUser = await AuthService.currentUser;
    if (currentUser == null) return;

    await RatingService.submitMessRating(
      orderId: widget.order['id'].toString(),
      messId:
          widget.order['mess_id']?.toString() ??
          widget.order['mess_owner_id']?.toString() ??
          '',
      customerId: currentUser['uid'],
      rating: _rating,
    );

    if (mounted) Navigator.pop(context);
  }
}
