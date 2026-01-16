import 'package:flutter/material.dart';
import 'package:Tiffinity/services/mess_service.dart';
import 'subscription_detail_page.dart';

class MySubscriptionsPage extends StatefulWidget {
  const MySubscriptionsPage({super.key});

  @override
  State<MySubscriptionsPage> createState() => _MySubscriptionsPageState();
}

class _MySubscriptionsPageState extends State<MySubscriptionsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _messes = [];

  @override
  void initState() {
    super.initState();
    _loadMesses();
  }

  Future<void> _loadMesses() async {
    setState(() => _isLoading = true);
    try {
      final messesRaw = await MessService.getAllMesses();
      final messes = messesRaw
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      setState(() {
        _messes = messes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subscriptions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMesses,
              child: _messes.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No subscriptions found')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final mess = _messes[index];
                        final messName = mess['name']?.toString() ?? 'Mess';
                        final messType = mess['mess_type']?.toString() ?? '';
                        final status = (mess['isOnline']?.toString() == '1')
                            ? 'Active'
                            : 'Paused';
                        final items = _mockItemsForMess(messName);

                        return _SubscriptionCard(
                          title: messName,
                          period: messType.isNotEmpty ? messType : 'Plan',
                          nextRenewal: 'Tomorrow',
                          status: status,
                          items: items,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubscriptionDetailPage(
                                  messName: messName,
                                  nextDay: 'Tomorrow',
                                  items: items,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: _messes.length,
                    ),
            ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final String title;
  final String period;
  final String nextRenewal;
  final String status;
  final List<String> items;
  final VoidCallback onTap;

  const _SubscriptionCard({
    required this.title,
    required this.period,
    required this.nextRenewal,
    required this.status,
    required this.items,
    required this.onTap,
  });

  Color _statusColor() {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant_menu, color: Color.fromARGB(255, 27, 84, 78)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$period • Next renewal $nextRenewal',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Today: ${items.join(', ')}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor().withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<String> _mockItemsForMess(String messName) {
  if (messName.toLowerCase().contains('veg')) {
    return ['Paneer Masala', 'Jeera Rice', 'Phulka', 'Dal Fry'];
  }
  if (messName.toLowerCase().contains('spice') ||
      messName.toLowerCase().contains('non-veg')) {
    return ['Chicken Curry', 'Steamed Rice', 'Tandoori Roti', 'Curd'];
  }
  return ['Dal', 'Rice', 'Roti', 'Sabzi'];
}
