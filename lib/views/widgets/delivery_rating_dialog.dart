import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:Tiffinity/services/rating_service.dart';
import 'package:Tiffinity/services/auth_services.dart';

class DeliveryRatingDialog extends StatefulWidget {
  final Map<String, dynamic> order;

  const DeliveryRatingDialog({super.key, required this.order});

  @override
  State<DeliveryRatingDialog> createState() => _DeliveryRatingDialogState();
}

class _DeliveryRatingDialogState extends State<DeliveryRatingDialog> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

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
                const Icon(Icons.delivery_dining, size: 48, color: primary),
                const SizedBox(height: 16),

                const Text(
                  "How was your delivery?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  "Rate your delivery partner",
                  style: TextStyle(color: Colors.grey[600]),
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

                const SizedBox(height: 16),

                TextField(
                  controller: _reviewController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: "Write a short review (optional)",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
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

    await RatingService.submitDeliveryRating(
      orderId: widget.order['id'].toString(),
      deliveryPartnerId: widget.order['delivery_partner_id'].toString(),
      customerId: currentUser['uid'],
      rating: _rating,
      review: _reviewController.text.trim(),
    );

    if (mounted) Navigator.pop(context);
  }
}
