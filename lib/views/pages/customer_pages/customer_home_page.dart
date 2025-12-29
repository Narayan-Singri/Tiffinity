import 'package:flutter/material.dart';
import 'package:Tiffinity/views/widgets/card_widget.dart';
import 'package:Tiffinity/services/mess_service.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  String searchQuery = '';
  List<Map<String, dynamic>> _messes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMesses();
  }

  Future<void> _loadMesses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messes = await MessService.getAllMesses();
      setState(() {
        _messes = List<Map<String, dynamic>>.from(messes);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              hintText: 'Search for mess or tiffin services',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 8.0),

          // Messes list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text('Error: $_error'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadMesses,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : _buildMessList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessList() {
    if (_messes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No messes available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Filter messes by search query
    final filteredMesses =
        _messes.where((mess) {
          if (searchQuery.isEmpty) return true;

          final name = (mess['name'] ?? '').toString().toLowerCase();
          final description =
              (mess['description'] ?? '').toString().toLowerCase();

          return name.contains(searchQuery) ||
              description.contains(searchQuery);
        }).toList();

    if (filteredMesses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No messes match your search',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMesses,
      child: ListView.builder(
        itemCount: filteredMesses.length,
        padding: const EdgeInsets.only(bottom: 16),
        itemBuilder: (context, index) {
          final mess = filteredMesses[index];

          return CardWidget(
            title: mess['name'] ?? 'Unnamed',
            description: mess['description'] ?? 'No description',
            ratings: '4.5', // You can add ratings to your database
            distance: '1.0', // You can calculate distance based on location
            isVeg:
                (mess['mess_type'] ?? 'veg').toString().toLowerCase() == 'veg',
            messId:
                mess['id']
                    .toString(), // Convert int to String for compatibility
            messImage: mess['image_url']?.toString(),
            phone: mess['phone']?.toString(),
            address: mess['address']?.toString(),
            messType: mess['mess_type']?.toString(),
          );
        },
      ),
    );
  }
}
