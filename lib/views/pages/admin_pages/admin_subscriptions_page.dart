import 'package:Tiffinity/views/pages/admin_pages/create_plan_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/plan_details_page.dart';
import 'package:flutter/material.dart';
import 'package:Tiffinity/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminSubscriptionsPage extends StatefulWidget {
  const AdminSubscriptionsPage({super.key});

  @override
  State<AdminSubscriptionsPage> createState() => _AdminSubscriptionsPageState();
}

class _AdminSubscriptionsPageState extends State<AdminSubscriptionsPage> {
  List _plans = [];
  bool _isLoading = true;
  int? _messId;

  @override
  void initState() {
    super.initState();
    _loadMessId();
  }

  Future<void> _loadMessId() async {
    // ✅ FIX: Get mess_id from SharedPreferences instead of ApiService.getUserData()
    final prefs = await SharedPreferences.getInstance();
    final messId = prefs.getInt('mess_id');

    if (messId != null) {
      setState(() {
        _messId = messId;
      });
      _loadPlans();
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mess ID not found. Please setup your mess first.'),
          ),
        );
      }
    }
  }

  Future<void> _loadPlans() async {
    if (_messId == null) return;
    setState(() => _isLoading = true);
    try {
      final plans = await SubscriptionService.getMessPlans(_messId!);
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading plans: $e')));
      }
    }
  }

  Future<void> _togglePlanStatus(int planId, bool currentStatus) async {
    try {
      await SubscriptionService.togglePlanStatus(planId, !currentStatus);
      _loadPlans();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Plan status updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _plans.isEmpty
            ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.subscriptions_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No subscription plans yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first plan to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
            : RefreshIndicator(
              onRefresh: _loadPlans,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 100, // Space for FAB and bottom nav
                ),
                itemCount: _plans.length,
                itemBuilder: (context, index) {
                  final plan = _plans[index];
                  final isActive = plan['is_active'] == 1;
                  final subscriberCount = plan['subscriber_count'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PlanDetailsPage(
                                  planId: plan['id'],
                                  messId: plan['mess_id'],
                                ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors:
                                isActive
                                    ? [Colors.orange.shade50, Colors.white]
                                    : [Colors.grey.shade200, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    plan['name'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: isActive,
                                  onChanged:
                                      (value) => _togglePlanStatus(
                                        plan['id'],
                                        isActive,
                                      ),
                                  activeColor: Colors.orange,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${plan['duration_days']} days',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.currency_rupee,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                Text(
                                  '${plan['price']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            if (plan['description'] != null &&
                                plan['description'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                plan['description'],
                                style: TextStyle(color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$subscriberCount subscribers',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

        // Floating Action Button
        if (_messId != null)
          Positioned(
            right: 16,
            bottom: 80, // ✅ Adjusted to avoid bottom nav
            child: FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePlanPage(messId: _messId!),
                  ),
                );
                if (result == true) {
                  _loadPlans();
                }
              },
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.add),
              label: const Text('Create Plan'),
            ),
          ),
      ],
    );
  }
}
