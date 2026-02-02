import 'package:flutter/material.dart';
import 'package:Tiffinity/services/subscription_service.dart';

class SubscriptionTmrwAdminPage extends StatefulWidget {
  final int planId;

  const SubscriptionTmrwAdminPage({super.key, required this.planId});

  @override
  State<SubscriptionTmrwAdminPage> createState() =>
      _SubscriptionTmrwAdminPageState();
}

class _SubscriptionTmrwAdminPageState extends State<SubscriptionTmrwAdminPage> {
  List<Map<String, dynamic>> _optedOutItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOptedOutItems();
  }

  Future<void> _loadOptedOutItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📋 Fetching opted-out items for plan ID: ${widget.planId}');
      final optedOut =
          await SubscriptionService.getPlanOptOuts(widget.planId);
      
      print('✅ Loaded ${optedOut.length} opted-out records');
      
      setState(() {
        _optedOutItems = optedOut;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading opted-out items: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Group opted-out items by user and date
  Map<String, Map<String, List<Map<String, dynamic>>>> _groupByUserAndDate() {
    final grouped =
        <String, Map<String, List<Map<String, dynamic>>>>{};

    for (var item in _optedOutItems) {
      final userId = item['user_id']?.toString() ?? 'Unknown';
      final userName = item['user_name']?.toString() ?? 'Unknown User';
      final userKey = '$userId|$userName';
      final date = item['date']?.toString() ?? 'Unknown date';

      if (!grouped.containsKey(userKey)) {
        grouped[userKey] = {};
      }

      if (!grouped[userKey]!.containsKey(date)) {
        grouped[userKey]![date] = [];
      }

      grouped[userKey]![date]!.add(item);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Opted Out Items (Tomorrow)'),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error loading data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOptedOutItems,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_optedOutItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No Opted Out Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'All customers are satisfied with tomorrow\'s menu!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final groupedByUser = _groupByUserAndDate();

    return RefreshIndicator(
      onRefresh: _loadOptedOutItems,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: groupedByUser.length,
        itemBuilder: (context, index) {
          final entries = groupedByUser.entries.toList();
          final entry = entries[index];
          final userKey = entry.key;
          final dateGroups = entry.value;

          final userParts = userKey.split('|');
          final userName = userParts.length > 1 ? userParts[1] : 'Unknown User';
          final userId = userParts.length > 0 ? userParts[0] : 'Unknown';

          // Count total opted-out items for this user
          int totalOptedOut = 0;
          dateGroups.forEach((date, items) {
            totalOptedOut += items.length;
          });

          return Card(
            margin: EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'User ID: $userId',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalOptedOut opted out',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Dates and Items
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dateGroups.entries.map((dateEntry) {
                      final date = dateEntry.key;
                      final items = dateEntry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Header
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 16, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  date,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  '${items.length} items opted out',
                                  style: TextStyle(
                                    color: Colors.blue[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12),
                          // Items for this date
                          ...items.map((item) {
                            final itemName =
                                item['item_name']?.toString() ?? 'Unknown Item';
                            final itemPrice =
                                item['item_price']?.toString() ?? '0';
                            final itemType =
                                item['item_type']?.toString() ?? 'veg';
                            final mealTime =
                                item['meal_time']?.toString() ?? 'lunch';
                            final optedOutAt =
                                item['opted_out_at']?.toString() ?? 'Unknown';

                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[50],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Veg/Non-veg indicator
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: itemType
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains('non-veg')
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          itemName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '₹$itemPrice',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.restaurant_menu,
                                          size: 14,
                                          color: Colors.grey[600]),
                                      SizedBox(width: 6),
                                      Text(
                                        mealTime.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Icon(Icons.access_time,
                                          size: 14,
                                          color: Colors.grey[600]),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          optedOutAt,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          SizedBox(height: 16),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
