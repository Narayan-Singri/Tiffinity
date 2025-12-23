import 'package:flutter/material.dart';
import '../../../data/delivery_order_model.dart';
import '../../widgets/delivery_order_list_tile.dart';
import 'new_order_page.dart';

class DeliveryHomePage extends StatelessWidget {
  const DeliveryHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // For now a single dummy order
    final orders = [dummyDeliveryOrder];

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Partner'), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return DeliveryOrderListTile(
            order: order,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => NewOrderPage(order: order)),
              );
            },
          );
        },
      ),
    );
  }
}
