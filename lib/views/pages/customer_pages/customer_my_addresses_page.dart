import 'package:flutter/material.dart';
import 'package:Tiffinity/services/api_service.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'customer_location_page.dart';

class CustomerMyAddressesPage extends StatefulWidget {
  const CustomerMyAddressesPage({super.key});

  @override
  State<CustomerMyAddressesPage> createState() =>
      _CustomerMyAddressesPageState();
}

class _CustomerMyAddressesPageState extends State<CustomerMyAddressesPage> {
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = await AuthService.currentUser;
      if (currentUser != null) {
        _userId = currentUser['uid'].toString();
        final response = await ApiService.getRequest(
          'users/get_user_addresses.php?user_id=$_userId',
        ) as Map<String, dynamic>;

        if (response['success'] == true && response['addresses'] != null) {
          setState(() {
            _addresses = (response['addresses'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading addresses: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    try {
      final response = await ApiService.postRequest(
        'users/delete_address.php',
        {'address_id': addressId},
      );

      if (response['success'] == true) {
        _loadAddresses(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getAddressIcon(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'other':
        return Icons.location_on;
      default:
        return Icons.location_on;
    }
  }

  Color _getAddressColor(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Colors.blue;
      case 'work':
        return Colors.orange;
      case 'other':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }

  void _navigateToAddAddress() {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add address')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerLocationPage(userId: _userId!),
      ),
    ).then((_) {
      _loadAddresses(); // Refresh list when returning
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Addresses'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? _buildEmptyState()
              : _buildAddressesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddAddress,
        backgroundColor: const Color(0xFF00695C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No Addresses Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Add your first address to get started',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _navigateToAddAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00695C),
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 12,
              ),
            ),
            child: const Text(
              'Add New Address',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _addresses.length + 1,
      itemBuilder: (context, index) {
        if (index == _addresses.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
              onPressed: _navigateToAddAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF00695C),
                side: const BorderSide(color: Color(0xFF00695C), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text(
                    'Add New Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final address = _addresses[index];
        final addressType = address['address_type'] ?? 'other';
        final icon = _getAddressIcon(addressType);
        final color = _getAddressColor(addressType);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        addressType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address['name'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${address['room_no'] ?? ''}, ${address['building'] ?? ''}, ${address['area'] ?? ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (address['phone'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            address['phone'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Delete'),
                      onTap: () {
                        _deleteAddress(address['id'].toString());
                      },
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
