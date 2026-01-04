import 'package:flutter/material.dart';
import 'package:Tiffinity/services/api_service.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_widget_tree.dart';

class CustomerAddressForm extends StatefulWidget {
  final String userId;
  final double latitude;
  final double longitude;
  final String detectedAddress;
  final Function(String)? onSaved;

  const CustomerAddressForm({
    super.key,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.detectedAddress,
    this.onSaved,
  });

  @override
  State<CustomerAddressForm> createState() => _CustomerAddressFormState();
}

class _CustomerAddressFormState extends State<CustomerAddressForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  String _selectedType = 'home';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    _buildingController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.postForm('save_customer_location.php', {
        'user_id': widget.userId,
        'latitude': widget.latitude.toString(),
        'longitude': widget.longitude.toString(),
        'name': _nameController.text.trim(),
        'room_no': _roomController.text.trim(),
        'building': _buildingController.text.trim(),
        'area': _areaController.text.trim(),
        'address_type': _selectedType,
      });

      if (response['success'] == true) {
        if (mounted) {
          // ✅ Create display address
          final displayAddress =
              '${_roomController.text.trim()}, ${_buildingController.text.trim()}';

          Navigator.pop(context); // Close bottom sheet

          // ✅ Call callback if provided
          if (widget.onSaved != null) {
            widget.onSaved!(displayAddress);
          } else {
            // Fallback: just close with success
            Navigator.pop(context, true);
          }
        }
      } else {
        _showError(response['message'] ?? 'Failed to save address');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Add Address Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Text(
                widget.detectedAddress,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Complete Name',
                  hintText: 'e.g., John Doe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Room/Flat Number
              TextFormField(
                controller: _roomController,
                decoration: InputDecoration(
                  labelText: 'Flat / House No.',
                  hintText: 'e.g., 301',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Building Name
              TextFormField(
                controller: _buildingController,
                decoration: InputDecoration(
                  labelText: 'Building / Apartment Name',
                  hintText: 'e.g., Skyline Heights',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.apartment_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Area/Locality
              TextFormField(
                controller: _areaController,
                decoration: InputDecoration(
                  labelText: 'Area / Locality',
                  hintText: 'e.g., Andheri West',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_city_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Address Type Chips
              const Text(
                'Save as',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildAddressTypeChip('Home', 'home', Icons.home),
                  const SizedBox(width: 12),
                  _buildAddressTypeChip('Work', 'work', Icons.work),
                  const SizedBox(width: 12),
                  _buildAddressTypeChip('Other', 'other', Icons.location_on),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Save Address',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressTypeChip(String label, String value, IconData icon) {
    final isSelected = _selectedType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00695C) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF00695C) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
