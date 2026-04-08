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

  // New state for quick filters
  String _activeFilter = 'All';
  String _searchQuery = '';

  // Theme Colors to match the Admin side
  final Color _primaryColor = const Color(0xFF1B5450);
  final Color _bgColor = const Color(0xFFF4F7F8);

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
      messesRaw.map((mess) => Map<String, dynamic>.from(mess as Map)).toList();
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

  // Updated filter logic to handle both search text and quick filter chips
  void _applyFilters(String query, String filterType) {
    setState(() {
      _searchQuery = query;
      _activeFilter = filterType;

      _filteredMesses = _messes.where((mess) {
        final name = mess['name']?.toString().toLowerCase() ?? '';
        final type = mess['mess_type']?.toString().toLowerCase() ?? '';

        // 1. Text Search Match
        final matchesSearch = name.contains(_searchQuery.toLowerCase()) ||
            type.contains(_searchQuery.toLowerCase());

        // 2. Chip Filter Match
        bool matchesType = true;
        if (_activeFilter == 'Pure Veg') {
          matchesType = type == 'veg';
        } else if (_activeFilter == 'Non-Veg') {
          matchesType = type == 'non-veg' || type == 'both';
        }

        return matchesSearch && matchesType;
      }).toList();
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

  String _resolveMessRating(Map<String, dynamic> mess) {
    final dynamic value =
        mess['rating'] ??
            mess['avg_rating'] ??
            mess['moving_avg'] ??
            mess['average_rating'];
    final parsed = double.tryParse(value?.toString() ?? '');
    return (parsed ?? 0.0).toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor, // Modern soft background
      body: RefreshIndicator(
        color: _primaryColor,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // 1. Modern App Bar
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: _primaryColor,
              elevation: 0,
              toolbarHeight: 70,
              title: GestureDetector(
                onTap: _openLocationPage,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deliver to',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
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
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: _openProfilePage,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      child: const Icon(Icons.person_outline_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Overlapping Search Bar & Quick Filters
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  // Teal Background Extension for seamless blend
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar Centered
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SearchFilterBar(
                          onSearchChanged: (query) => _applyFilters(query, _activeFilter),
                          onFilterPressed: () {},
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Modern Quick Filter Chips
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          children: [
                            _buildFilterChip('All'),
                            const SizedBox(width: 10),
                            _buildFilterChip('Pure Veg'),
                            const SizedBox(width: 10),
                            _buildFilterChip('Non-Veg'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Greeting Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello! 👋',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[800],
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What are you craving today?',
                      style: TextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Popular Messes Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Popular Near You',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[800],
                        letterSpacing: -0.5,
                      ),
                    ),
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'See All',
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Messes List
            _isLoading
                ? SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: _primaryColor),
              ),
            )
                : _filteredMesses.isEmpty
                ? SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ]
                      ),
                      child: Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No messes found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your search or filters.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
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
                      ratings: _resolveMessRating(mess),
                      distance: '1.5',
                      isVeg: mess['mess_type']?.toString().toLowerCase() == 'veg',
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

  // Helper method to build filter chips
  Widget _buildFilterChip(String label) {
    bool isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () => _applyFilters(_searchQuery, label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _primaryColor : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[700],
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}