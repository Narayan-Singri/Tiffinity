import 'package:flutter/material.dart';
import 'package:Tiffinity/services/mess_service.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/widgets/card_widget.dart';
import 'package:Tiffinity/views/widgets/search_filter_bar.dart';
import 'package:Tiffinity/data/address_notifier.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_profile_page.dart';
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
    _loadSelectedAddress();
  }

  void _openProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // 1. Standard App Bar (Scrolls away)
            SliverAppBar(
              floating: false, // Standard scroll behavior
              pinned: false, // Scrolls out of view
              backgroundColor: const Color(0xFF00695C),
              elevation: 0,
              title: GestureDetector(
                onTap: _openLocationPage,
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deliver to',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _selectedAddress,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: _openProfilePage,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Overlapping Search Bar Section (Scrolls away)
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  // Teal Background Extension (Top Half)
                  Container(
                    height: 35, // Half height of search bar approx
                    decoration: const BoxDecoration(
                      color: Color(0xFF00695C),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                  ),
                  // Search Bar Centered
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SearchFilterBar(
                      onSearchChanged: _filterMesses,
                      onFilterPressed: () {},
                    ),
                  ),
                ],
              ),
            ),

            // 3. Greeting Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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
                      'What are you craving today?',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Popular Messes Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Messes List
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
