import 'package:Tiffinity/views/pages/admin_pages/admin_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:Tiffinity/services/mess_service.dart';
import 'package:Tiffinity/services/order_service.dart';
import 'package:Tiffinity/services/user_service.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/pages/admin_pages/order_details_page.dart';
import 'package:Tiffinity/services/notification_service.dart';

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

  // ✅ Helper function to convert int to bool
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

      // Load mess data
      final mess = await MessService.getMessByOwner(currentUser['uid']);

      if (mess != null) {
        // ✅ FIX: Convert String to int
        final messId = int.parse(mess['id'].toString());

        // Load orders for this mess
        try {
          final orders = await OrderService.getMessOrders(messId);

          setState(() {
            _messData = mess;

            // ✅ IMPROVED: Better null/empty handling
            if (orders is List) {
              _orders =
                  orders
                      .where((e) => e is Map) // Filter only valid Maps
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList();
            } else {
              _orders = [];
            }

            _isLoading = false;
          });

          // Load customer names ONLY if we have orders
          if (_orders.isNotEmpty) {
            for (var order in _orders) {
              if (order.containsKey('customer_id')) {
                _fetchCustomerName(order['customer_id']?.toString() ?? '');
              }
            }
          }
        } catch (orderError) {
          debugPrint('Error loading orders: $orderError');
          setState(() {
            _messData = mess;
            _orders = []; // Set to empty array on error
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
      // ✅ FIX: Pass both messId and status
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

  void _filterOrders(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _applyFilter(String status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text("All"),
              onTap: () {
                _applyFilter("All");
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text("Pending"),
              onTap: () {
                _applyFilter("pending");
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text("Accepted"),
              onTap: () {
                _applyFilter("accepted");
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delivery_dining),
              title: const Text("Preparing"),
              onTap: () {
                _applyFilter("preparing");
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.done_all),
              title: const Text("Delivered"),
              onTap: () {
                _applyFilter("delivered");
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text("Cancelled"),
              onTap: () {
                _applyFilter("cancelled");
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_messData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.store_mall_directory,
                color: Colors.grey,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'No mess found for your admin account.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                child: const Text('Create Mess'),
                onPressed: () async {
                  final currentUser = await AuthService.currentUser;
                  if (currentUser != null && mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                AdminSetupPage(userId: currentUser['uid']),
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

    // ✅ Convert isOnline to bool
    final isOnline = _toBool(_messData!['isOnline']);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Mess Status Section
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          isOnline
                              ? [Colors.green.shade400, Colors.green.shade600]
                              : [Colors.red.shade400, Colors.red.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isOnline
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOnline ? Icons.store : Icons.store_mall_directory,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOnline ? "Mess Open" : "Mess Closed",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isOnline
                                  ? "Orders are receivable"
                                  : "Orders are stopped",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isOnline,
                        onChanged: _toggleOnlineStatus,
                        activeColor: Colors.white,
                        activeTrackColor: Colors.green.shade300,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.red.shade300,
                      ),
                    ],
                  ),
                ),

                // Summary Cards
                _buildSummaryCards(),

                const SizedBox(height: 16),

                // Search and Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: _filterOrders,
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: _showFilterOptions,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Orders List
                _buildOrdersList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalOrders = _orders.length;
    final completed = _orders.where((o) => o['status'] == 'delivered').length;
    final accepted = _orders.where((o) => o['status'] == 'accepted').length;
    final cancelled = _orders.where((o) => o['status'] == 'cancelled').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  totalOrders.toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Total Orders',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        completed.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Completed',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        accepted.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Accepted',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        cancelled.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Cancelled',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(50),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No orders yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Orders from customers will appear here',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Filter orders
    final filteredOrders =
        _orders.where((order) {
          final matchesStatus =
              _selectedStatus == "All" ||
              order['status'].toString().toLowerCase() ==
                  _selectedStatus.toLowerCase();

          final matchesSearch =
              _searchQuery.isEmpty ||
              order['id'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              (_customerNames[order['customer_id']] ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());

          return matchesStatus && matchesSearch;
        }).toList();

    if (filteredOrders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(50),
        child: Center(
          child: Text(
            'No orders match your filter',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final status = order['status'] ?? 'pending';
        final customerId = order['customer_id'];
        final customerName = _customerNames[customerId] ?? 'Loading...';

        // Format time
        String formattedTime = '';
        if (order['created_at'] != null) {
          try {
            final dateTime = DateTime.parse(order['created_at'].toString());
            formattedTime =
                '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
          } catch (e) {
            formattedTime = 'N/A';
          }
        }

        // Color coding based on status
        Color statusColor = Colors.orange;
        Color statusBgColor = Colors.orange.withOpacity(0.2);
        IconData statusIcon = Icons.schedule;

        if (status == 'delivered') {
          statusColor = Colors.green;
          statusBgColor = Colors.green.withOpacity(0.2);
          statusIcon = Icons.check_circle;
        } else if (status == 'cancelled') {
          statusColor = Colors.red;
          statusBgColor = Colors.red.withOpacity(0.2);
          statusIcon = Icons.cancel;
        } else if (status == 'accepted') {
          statusColor = Colors.blue;
          statusBgColor = Colors.blue.withOpacity(0.2);
          statusIcon = Icons.schedule;
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => OrderDetailsPage(
                      orderId: order['id'].toString(),
                      orderData: order,
                    ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order #${order['id'] ?? ''}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedTime,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
