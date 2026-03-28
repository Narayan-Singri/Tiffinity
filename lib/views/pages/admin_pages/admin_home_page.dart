import 'package:Tiffinity/views/pages/admin_pages/admin_setup_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/weekly_menu_management_page.dart';
import 'package:flutter/material.dart';
import 'package:Tiffinity/services/mess_service.dart';
import 'package:Tiffinity/services/order_service.dart';
import 'package:Tiffinity/services/user_service.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/pages/admin_pages/order_details_page.dart';
import 'package:Tiffinity/services/notification_service.dart';
import 'package:Tiffinity/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Tiffinity/services/menu_service.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  Map<String, dynamic>? _messData;
  List<Map<String, dynamic>> _orders = [];
  Map<String, String> _customerNames = {};
  String _selectedStatus = "All";
  String _searchQuery = "";
  bool _isLoading = true;
  static bool _notificationsInitialized = false;

  // Warning Banner Variables
  bool _showMenuWarning = false;
  int _activeSubsTomorrow = 0;

  final List<String> _statusFilters = [
    'All',
    'subscriptions',
    'pending',
    'accepted',
    'confirmed',
    'ready',
    'out_for_delivery',
    'delivered',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeNotificationsOnce();
  }

  Future<void> _initializeNotificationsOnce() async {
    if (_notificationsInitialized) return;
    _notificationsInitialized = true;
    try {
      await NotificationService().initialize();
      debugPrint('✅ Notifications initialized for admin');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = await AuthService.currentUser;
      if (currentUser == null) return;

      final mess = await MessService.getMessByOwner(currentUser['uid']);
      if (mess != null) {
        final prefs = await SharedPreferences.getInstance();
        final savedMessId = prefs.getInt('mess_id');
        final messId = int.parse(mess['id'].toString());
        if (savedMessId == null) {
          await prefs.setInt('mess_id', messId);
        }

        try {
          final orders = await OrderService.getMessOrders(messId);
          setState(() {
            _messData = mess;
            if (orders is List) {
              this._orders = orders
                  .where((e) => e is Map)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            } else {
              this._orders = [];
            }
            _isLoading = false;
          });

          // Check for tomorrow's menu warning
          _checkTomorrowMenuStatus(messId);

          if (this._orders.isNotEmpty) {
            for (var order in this._orders) {
              if (order.containsKey('customer_id')) {
                _fetchCustomerName(order['customer_id']?.toString() ?? '');
              }
            }
          }
        } catch (orderError) {
          debugPrint('Error loading orders: $orderError');
          setState(() {
            _messData = mess;
            _orders = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _messData = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading admin data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkTomorrowMenuStatus(int messId) async {
    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      // 1. Calculate the Week Start Date (Monday) for tomorrow
      final weekday = tomorrow.weekday; // 1 = Monday, 7 = Sunday
      final weekStart = tomorrow.subtract(Duration(days: weekday - 1));
      final weekStartStr = "${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}";

      // 2. Get the specific day name
      final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      final tomorrowName = dayNames[weekday - 1];

      // 3. Fetch the Weekly Menu
      final weeklyMenu = await MenuService.getWeeklyMenu(
        messId: messId,
        weekStartDate: weekStartStr,
      );

      // 4. Check if ANY item is available for tomorrow
      final hasItemsForTomorrow = weeklyMenu.any((item) => item.days[tomorrowName] == 1);

      if (hasItemsForTomorrow) {
        if (mounted) setState(() => _showMenuWarning = false);
        return;
      }

      // 5. If no food is scheduled, check subscribers
      final plans = await SubscriptionService.getMessPlans(messId);
      final activePlans = plans.where((p) => p['is_active'] == 1 || p['is_active'] == '1').toList();

      if (activePlans.isNotEmpty) {
        int totalSubscribers = 0;

        // 🔴 FIX: Execute all subscriber fetch calls concurrently instead of sequentially
        final subscriberFutures = activePlans.map((plan) {
          return SubscriptionService.getPlanSubscribers(int.parse(plan['id'].toString()));
        });

        // Wait for all API calls to finish at the same time
        final allSubscribers = await Future.wait(subscriberFutures);

        for (var subs in allSubscribers) {
          totalSubscribers += subs.length;
        }

        if (totalSubscribers > 0 && mounted) {
          setState(() {
            _activeSubsTomorrow = totalSubscribers;
            _showMenuWarning = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking menu status: $e");
    }
  }

  Future<void> _fetchCustomerName(String customerId) async {
    if (_customerNames.containsKey(customerId)) return;
    try {
      final user = await UserService.getUser(customerId);
      if (user != null && mounted) {
        setState(() {
          _customerNames[customerId] = user['name'] ?? 'Customer';
        });
      }
    } catch (e) {
      debugPrint('Error fetching customer name: $e');
    }
  }

  Future<void> _toggleOnlineStatus(bool status) async {
    if (_messData == null) return;
    try {
      final success = await MessService.toggleMessStatus(
        _messData!['id'],
        status,
      );
      if (success && mounted) {
        setState(() {
          _messData!['isOnline'] = status ? 1 : 0;
        });
      }
    } catch (e) {
      debugPrint('Error toggling status: $e');
    }
  }

  // --- UI Helpers ---

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'accepted':
      case 'active':
        return const Color(0xFF2196F3);
      case 'confirmed':
        return const Color(0xFF4CAF50);
      case 'ready':
        return const Color(0xFF9C27B0);
      case 'out_for_delivery':
        return const Color(0xFFFF5722);
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
      case 'active':
        return Icons.thumb_up_alt_outlined;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'ready':
        return Icons.shopping_bag_outlined;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      int hour = date.hour;
      String period = 'AM';
      if (hour >= 12) {
        period = 'PM';
        if (hour > 12) hour -= 12;
      }
      if (hour == 0) hour = 12;
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    } catch (e) {
      return 'N/A';
    }
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 27, 84, 78),
          ),
        ),
      );
    }

    if (_messData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_mall_directory, color: Colors.grey[400], size: 100),
              const SizedBox(height: 24),
              const Text(
                'No mess found for your account.',
                style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create Your Mess'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 27, 84, 78),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final currentUser = await AuthService.currentUser;
                  if (currentUser != null && mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminSetupPage(userId: currentUser['uid']),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    final isOnline = _toBool(_messData!['isOnline']);
    final rawMessName = _messData!['name']?.toString() ?? 'My Mess';
    final messName = rawMessName.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    final filteredOrders = _orders.where((order) {
      final subId = order['subscription_id'];
      final isSubField = order['is_subscription'];
      final type = order['order_type'];
      final orderId = order['id']?.toString() ?? '';

      final isSubscriptionOrder = (subId != null && subId.toString() != '0') ||
          (isSubField == 1 || isSubField == '1' || isSubField == true) ||
          (type == 'subscription') ||
          orderId.startsWith('SUB');

      bool matchesStatus = false;
      if (_selectedStatus == "All") {
        matchesStatus = true;
      } else if (_selectedStatus.toLowerCase() == "subscriptions") {
        matchesStatus = isSubscriptionOrder;
      } else {
        matchesStatus = order['status'].toString().toLowerCase() == _selectedStatus.toLowerCase();
      }

      final matchesSearch = _searchQuery.isEmpty ||
          order['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (_customerNames[order['customer_id']] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesStatus && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        color: const Color.fromARGB(255, 27, 84, 78),
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Professional App Bar
            SliverAppBar(
              expandedHeight: 140.0,
              floating: false,
              pinned: true,
              backgroundColor: const Color.fromARGB(255, 27, 84, 78),
              elevation: 2,
              shadowColor: Colors.black38,
              shape: const ContinuousRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(60),
                  bottomRight: Radius.circular(60),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  messName,
                  style: const TextStyle(
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
                      Positioned(
                        right: -20,
                        top: 10,
                        child: Icon(
                          Icons.soup_kitchen,
                          size: 130,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                      onPressed: () {},
                    ),
                  ),
                ),
              ],
            ),

            // Dashboard Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusToggle(isOnline),

                    if (_showMenuWarning) ...[
                      const SizedBox(height: 16),
                      _buildWarningBanner(),
                    ],

                    const SizedBox(height: 24),
                    const Text(
                      'Dashboard',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    _buildMetricsGrid(),
                    const SizedBox(height: 24),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildFilterChips(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Orders List
            if (_orders.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState('No orders yet', 'When customers order, they will appear here.', Icons.receipt_long_outlined),
              )
            else if (filteredOrders.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState('No results found', 'Try changing your search or filter.', Icons.search_off),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return _buildOrderCard(filteredOrders[index]);
                    },
                    childCount: filteredOrders.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WeeklyMenuManagementPage()),
        ).then((_) => _loadData());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Missing Menu for Tomorrow",
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "You have $_activeSubsTomorrow active subscribers expecting food, but no menu is scheduled. Tap to add items.",
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: Colors.red.shade700, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle(bool isOnline) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isOnline ? Colors.white : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline ? Colors.green.shade200 : Colors.red.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isOnline ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOnline ? Colors.green.shade100 : Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline ? Icons.storefront : Icons.store_mall_directory,
              color: isOnline ? Colors.green.shade700 : Colors.red.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? "Mess is Open" : "Mess is Closed",
                  style: TextStyle(
                    color: isOnline ? Colors.green.shade800 : Colors.red.shade800,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOnline ? "Accepting new orders" : "Currently not accepting orders",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isOnline,
            onChanged: _toggleOnlineStatus,
            activeColor: Colors.white,
            activeTrackColor: Colors.green,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.red.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final total = _orders.length;
    final pending = _orders.where((o) => o['status'] == 'pending').length;
    final preparing = _orders.where((o) => o['status'] == 'accepted' || o['status'] == 'ready').length;

    final subscriptions = _orders.where((o) {
      final subId = o['subscription_id'];
      final isSub = o['is_subscription'];
      final type = o['order_type'];
      final orderId = o['id']?.toString() ?? '';

      return (subId != null && subId.toString() != '0') ||
          (isSub == 1 || isSub == '1' || isSub == true) ||
          (type == 'subscription') ||
          orderId.startsWith('SUB');
    }).length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricCard('Total Orders', total.toString(), Icons.receipt_long, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Pending', pending.toString(), Icons.schedule, Colors.orange)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Subscriptions', subscriptions.toString(), Icons.workspace_premium, Colors.purple)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Preparing', preparing.toString(), Icons.soup_kitchen, Colors.green)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String count, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.shade50, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search order ID or customer name...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _statusFilters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _statusFilters[index];
          final isSelected = _selectedStatus.toLowerCase() == filter.toLowerCase();

          final displayLabel = filter == 'All'
              ? 'All Orders'
              : filter == 'subscriptions'
              ? 'Subscriptions'
              : filter.replaceAll('_', ' ').toUpperCase();

          return FilterChip(
            label: Text(
              displayLabel,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            selected: isSelected,
            onSelected: (bool selected) {
              setState(() => _selectedStatus = filter);
            },
            backgroundColor: Colors.white,
            selectedColor: const Color.fromARGB(255, 27, 84, 78),
            checkmarkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? const Color.fromARGB(255, 27, 84, 78) : Colors.grey.shade300,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5)
            ]),
            child: Icon(icon, size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // --- THE NEW, PREMIUM ORDER CARD DESIGN ---
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final customerId = order['customer_id'];
    final customerName = _customerNames[customerId] ?? 'Loading...';
    final formattedTime = _formatTime(order['created_at']?.toString());

    final isSubscription = (order['subscription_id'] != null && order['subscription_id'].toString() != '0') ||
        (order['is_subscription'] == 1 || order['is_subscription'] == '1') ||
        (order['id'] != null && order['id'].toString().startsWith('SUB'));

    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // More rounded, modern corners
        // Subtle outline based on type
        border: Border.all(
          color: isSubscription ? Colors.purple.shade200 : Colors.grey.shade100,
          width: isSubscription ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSubscription ? Colors.purple.withOpacity(0.08) : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20), // Keeps header inside borders
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsPage(
                    orderId: order['id'].toString(),
                    orderData: order,
                    isSubscriptionOrder: isSubscription, // ✅ CRITICAL FIX: Pass the flag here
                  ),
                ),
              ).then((_) => _loadData());
            },
            child: Column( // Use a column to easily stack the premium header on top
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // --- PREMIUM SUBSCRIPTION TICKET HEADER ---
                if (isSubscription)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade700, Colors.purple.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          "ACTIVE SUBSCRIPTION",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // --- MAIN CARD BODY ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Circular Icon Status Box (More modern than square)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSubscription ? Colors.purple.shade50 : statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSubscription ? Icons.local_dining : statusIcon,
                          color: isSubscription ? Colors.purple.shade600 : statusColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Order Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Order #${order['id'] ?? ''}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isSubscription ? Colors.purple.shade900 : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Show time here only if it's NOT a subscription (since subs have it in the header)
                                if (!isSubscription)
                                  Text(
                                    formattedTime,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              customerName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // Modern Status Pill with Dot Indicator
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: statusColor.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.circle, color: statusColor, size: 8),
                                      const SizedBox(width: 4),
                                      Text(
                                        status.replaceAll('_', ' ').toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Modern Action Arrow
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}