import 'package:flutter/material.dart';
import 'package:Tiffinity/services/mess_service.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/widgets/card_widget.dart';
import 'package:Tiffinity/views/widgets/search_filter_bar.dart';
import 'package:Tiffinity/data/address_notifier.dart';
import 'customer_location_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  List<Map<String, dynamic>> _messes = [];
  List<Map<String, dynamic>> _filteredMesses = [];
  bool _isLoading = true;
  String _selectedAddress = 'Select location';
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSelectedAddress();

    // ✅ Listen to address changes
    selectedAddressNotifier.addListener(_updateAddress);
  }

  @override
  void dispose() {
    selectedAddressNotifier.removeListener(_updateAddress);
    super.dispose();
  }

  void _updateAddress() {
    final address = selectedAddressNotifier.value;
    if (address != null && mounted) {
      setState(() {
        _selectedAddress = '${address['room_no']}, ${address['building']}...';
      });
    }
  }

  Future<void> _loadSelectedAddress() async {
    final address = await AddressHelper.loadSelectedAddress();
    if (address != null && mounted) {
      setState(() {
        _selectedAddress = '${address['room_no']}, ${address['building']}...';
      });
      selectedAddressNotifier.value = address;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.currentUser;
      if (user != null) {
        setState(() => _userId = user['uid'].toString());
      }

      // ✅ GET AND CAST MESSES
      final messesRaw = await MessService.getAllMesses();
      final messes =
          messesRaw
              .map((mess) => Map<String, dynamic>.from(mess as Map))
              .toList();

      setState(() {
        _messes = messes;
        _filteredMesses = messes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading messes: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterMesses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMesses = _messes;
      } else {
        _filteredMesses =
            _messes.where((mess) {
              final name = mess['name']?.toString().toLowerCase() ?? '';
              final type = mess['mess_type']?.toString().toLowerCase() ?? '';
              return name.contains(query.toLowerCase()) ||
                  type.contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  void _openLocationPage() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to select address')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerLocationPage(userId: _userId!),
      ),
    );

    // Reload address after returning
    _loadSelectedAddress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ✅ Custom App Bar with Address
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: const Color(0xFF00695C),
              title: GestureDetector(
                onTap: _openLocationPage,
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Deliver to',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _selectedAddress,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFF00695C),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SearchFilterBar(
                  onSearchChanged: _filterMesses,
                  onFilterPressed: () {}, // ✅ Add empty callback
                ),
              ),
            ),

            // ✅ Greeting Section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello! 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What would you like to eat today?',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            // Popular Messes Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Popular Near You',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          color: Color(0xFF00695C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Messes List
            _isLoading
                ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
                : _filteredMesses.isEmpty
                ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messes found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final mess = _filteredMesses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CardWidget(
                          title: mess['name']?.toString() ?? 'Unknown',
                          description: mess['description']?.toString() ?? '',
                          ratings: '4.2',
                          distance: '1.5',
                          isVeg:
                              mess['mess_type']?.toString().toLowerCase() ==
                              'veg',
                          messId: mess['id'].toString(),
                          messImage: mess['image_url']?.toString(),
                          phone: mess['phone']?.toString(),
                          address: mess['address']?.toString(),
                          messType: mess['mess_type']?.toString(),
                        ),
                      );
                    }, childCount: _filteredMesses.length),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
