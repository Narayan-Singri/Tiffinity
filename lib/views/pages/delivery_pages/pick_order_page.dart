import 'package:flutter/material.dart';
import '../../../data/delivery_order_model.dart';
import '../../widgets/delivery_app_bar.dart';
import '../../widgets/collapsible_section_tile.dart';
import '../../widgets/primary_bottom_button.dart';
import 'reach_pickup_page.dart';

class PickOrderPage extends StatelessWidget {
  final DeliveryOrder order;

  const PickOrderPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final baseId = order.id.substring(0, order.id.length - 4);
    final lastDigits = order.id.substring(order.id.length - 4);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const DeliveryAppBar(title: 'Pick order'),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Pick order in 2 mins',
                style: TextStyle(
                  color: Color(0xFF2F80ED),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ORDER ID',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: baseId,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: lastDigits,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  CollapsibleSectionTile(
                    title: 'Order details',
                    subtitle: order.restaurantName,
                    leadingIcon: Icons.receipt_long,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          order.items
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    '${item.quantity} x ${item.name}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  CollapsibleSectionTile(
                    title: 'Restaurant details',
                    leadingIcon: Icons.storefront,
                    child: Text(
                      order.restaurantAddress,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  CollapsibleSectionTile(
                    title: 'Customer details',
                    leadingIcon: Icons.person,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.customerAddress,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: PrimaryBottomButton(
        label: 'Picked order',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ReachPickupPage(order: order)),
          );
        },
      ),
    );
  }
}
