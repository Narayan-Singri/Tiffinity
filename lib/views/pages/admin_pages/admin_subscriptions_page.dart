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
            backgroundColor: Colors.red,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading plans: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _togglePlanStatus(int planId, bool currentStatus) async {
    try {
      await SubscriptionService.togglePlanStatus(planId, !currentStatus);
      _loadPlans();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan status updated'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Plans'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedPlanIds.length} plan(s)? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color.fromARGB(255, 27, 84, 78)),
                SizedBox(height: 16),
                Text('Deleting plans...', style: TextStyle(fontWeight: FontWeight.bold)),
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
        }
      }

      if (mounted) Navigator.pop(context); // Close loading dialog

      setState(() {
        _selectedPlanIds.clear();
        _isSelectionMode = false;
      });

      await _loadPlans();

      if (mounted) {
        if (failCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All selected plans deleted'), backgroundColor: Colors.green),
          );
        } else if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$successCount deleted, $failCount failed'), backgroundColor: Colors.orange),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${lastError ?? "Unknown error"}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ============================================
  // BUILD METHODS
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color.fromARGB(255, 27, 84, 78)),
      )
          : CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          if (_isSelectionMode) _buildSelectionBar(),
          if (_plans.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            _buildPlansList(),
        ],
      ),
      floatingActionButton: _messId != null
          ? FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePlanPage(messId: _messId!)),
          );
          if (result == true) _loadPlans();
        },
        backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 4,
      )
          : null,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color.fromARGB(255, 27, 84, 78),
      elevation: 2,
      shadowColor: Colors.black38,
      automaticallyImplyLeading: false,
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(60),
          bottomRight: Radius.circular(60),
        ),
      ),
      actions: [
        if (_plans.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                _isSelectionMode ? Icons.close : Icons.checklist,
                color: Colors.white,
              ),
              onPressed: _toggleSelectionMode,
              tooltip: _isSelectionMode ? 'Cancel Selection' : 'Select Plans',
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          'Subscriptions',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        background: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(60),
            bottomRight: Radius.circular(60),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 18, 65, 60),
                      Color.fromARGB(255, 27, 84, 78)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Premium subtle watermark
              Positioned(
                right: -20,
                top: 10,
                child: Icon(
                  Icons.card_membership,
                  size: 130,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${_selectedPlanIds.length}',
                style: const TextStyle(
                  color: Color.fromARGB(255, 27, 84, 78),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Plans Selected',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Spacer(),
            if (_selectedPlanIds.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _deleteSelectedPlans,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5)
              ],
            ),
            child: Icon(Icons.card_membership, size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text(
            'No plans created',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first subscription plan to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList() {
    return SliverPadding(
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final plan = _plans[index];
            return _buildPlanCard(plan);
          },
          childCount: _plans.length,
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isActive = plan['is_active'] == 1;
    final subscriberCount = plan['subscriber_count'] ?? 0;
    final isSelected = _selectedPlanIds.contains(plan['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isSelected
              ? const Color.fromARGB(255, 27, 84, 78)
              : (isActive ? Colors.transparent : Colors.grey.shade200),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (_isSelectionMode) {
              _togglePlanSelection(plan['id']);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlanDetailsPage(
                    planId: plan['id'],
                    messId: plan['mess_id'],
                  ),
                ),
              ).then((_) => _loadPlans());
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isSelectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSelected ? const Color.fromARGB(255, 27, 84, 78) : Colors.grey.shade400,
                          size: 28,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.black87 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isActive ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              isActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isSelectionMode)
                      Switch(
                        value: isActive,
                        onChanged: (value) => _togglePlanStatus(plan['id'], isActive),
                        activeColor: Colors.white,
                        activeTrackColor: const Color.fromARGB(255, 27, 84, 78),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.blue),
                          const SizedBox(width: 6),
                          Text(
                            '${plan['duration_days']} Days',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.currency_rupee, size: 16, color: Colors.green),
                          Text(
                            '${plan['price']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (plan['description'] != null && plan['description'].toString().isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 16, bottom: 8),
                    child: Divider(height: 1),
                  ),
                  Text(
                    plan['description'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_alt_outlined, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          '$subscriberCount Active Subscribers',
                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}