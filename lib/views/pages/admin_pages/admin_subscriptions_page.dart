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
  bool _isSelectionMode = false;
  final Set<int> _selectedPlanIds = {};

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

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedPlanIds.clear();
      }
    });
  }

  void _togglePlanSelection(int planId) {
    setState(() {
      if (_selectedPlanIds.contains(planId)) {
        _selectedPlanIds.remove(planId);
      } else {
        _selectedPlanIds.add(planId);
      }
    });
  }

  Future<void> _deleteSelectedPlans() async {
    if (_selectedPlanIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Plans'),
            content: Text(
              'Are you sure you want to delete ${_selectedPlanIds.length} plan(s)? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Deleting plans...'),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      int successCount = 0;
      int failCount = 0;
      String? lastError;

      for (final planId in _selectedPlanIds) {
        try {
          final result = await SubscriptionService.deletePlan(planId);
          if (result['status'] == 'success') {
            successCount++;
          } else {
            failCount++;
            lastError = result['message'] ?? 'Unknown error';
          }
        } catch (e) {
          failCount++;
          lastError = e.toString();
          print('Error deleting plan $planId: $e');
        }
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      setState(() {
        _selectedPlanIds.clear();
        _isSelectionMode = false;
      });

      await _loadPlans();

      if (mounted) {
        if (failCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All plans deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successCount deleted, $failCount failed'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete plans: ${lastError ?? "Unknown error"}',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Selection Mode Top Bar
            if (_isSelectionMode)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: _toggleSelectionMode,
                    ),
                    Text(
                      '${_selectedPlanIds.length} selected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    if (_selectedPlanIds.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _deleteSelectedPlans,
                        icon: Icon(Icons.delete, size: 18),
                        label: Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              )
            else
              // Normal Mode Top Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      'Subscription Plans',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    OutlinedButton.icon(
                      onPressed: _toggleSelectionMode,
                      icon: Icon(Icons.checklist, size: 18),
                      label: Text('Select'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child:
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
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
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
                            final subscriberCount =
                                plan['subscriber_count'] ?? 0;
                            final isSelected = _selectedPlanIds.contains(
                              plan['id'],
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side:
                                    isSelected
                                        ? BorderSide(
                                          color: Colors.orange,
                                          width: 2,
                                        )
                                        : BorderSide.none,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  if (_isSelectionMode) {
                                    _togglePlanSelection(plan['id']);
                                  } else {
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
                                  }
                                },
                                onLongPress: () {
                                  if (!_isSelectionMode) {
                                    setState(() {
                                      _isSelectionMode = true;
                                      _selectedPlanIds.add(plan['id']);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      colors:
                                          isActive
                                              ? [
                                                Colors.orange.shade50,
                                                Colors.white,
                                              ]
                                              : [
                                                Colors.grey.shade200,
                                                Colors.white,
                                              ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (_isSelectionMode)
                                            Checkbox(
                                              value: isSelected,
                                              onChanged:
                                                  (value) =>
                                                      _togglePlanSelection(
                                                        plan['id'],
                                                      ),
                                              activeColor: Colors.orange,
                                            ),
                                          Expanded(
                                            child: Text(
                                              plan['name'],
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (!_isSelectionMode)
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
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
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
                                          plan['description']
                                              .toString()
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          plan['description'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
            ),
          ],
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
