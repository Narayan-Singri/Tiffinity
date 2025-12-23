import 'package:flutter/material.dart';
import '../../../data/delivery_order_model.dart';
import '../../widgets/delivery_app_bar.dart';
import '../../widgets/map_header_widget.dart';
import '../../widgets/delivery_info_card.dart';
import '../../widgets/audio_progress_stub.dart';
import '../../widgets/contact_buttons_row.dart';
import '../../widgets/primary_bottom_button.dart';
import 'reach_drop_page.dart';

class ReachPickupPage extends StatelessWidget {
  final DeliveryOrder order;

  const ReachPickupPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const DeliveryAppBar(title: 'Reach pickup'),
      body: Column(
        children: [
          const MapHeaderWidget(),
          const SizedBox(height: 8),
          DeliveryInfoCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.restaurantName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.restaurantAddress,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                const AudioProgressStub(),
                const SizedBox(height: 12),
                ContactButtonsRow(onCall: () {}, onGoToMap: () {}),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Order: ${order.id}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Customer: ${order.customerName}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: PrimaryBottomButton(
        label: 'Reached pickup location',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ReachDropPage(order: order)),
          );
        },
      ),
    );
  }
}
