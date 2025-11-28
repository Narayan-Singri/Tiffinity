import 'package:flutter/material.dart';
import 'package:Tiffinity/services/menu_service.dart';
import 'package:Tiffinity/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddMenuItemPage extends StatefulWidget {
  final int messId;
  final Map<String, dynamic>? existingItem;

  const AddMenuItemPage({super.key, required this.messId, this.existingItem});

  @override
  State<AddMenuItemPage> createState() => _AddMenuItemPageState();
}

class _AddMenuItemPageState extends State<AddMenuItemPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String _selectedType = 'veg';
  bool _isAvailable = true;
  bool _isLoading = false;

  File? _foodImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      nameController.text = widget.existingItem!['name'] ?? '';
      priceController.text = widget.existingItem!['price']?.toString() ?? '';
      descriptionController.text = widget.existingItem!['description'] ?? '';
      _selectedType = widget.existingItem!['type'] ?? 'veg';
      _isAvailable = _toBool(
        widget.existingItem!['is_available'],
      ); // ✅ Convert int to bool
    }
  }

  // ✅ Helper function to convert int to bool
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return true; // Default to available
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Upload Food Photo'),
          content: const Text('Choose where to upload photo from:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImageFromDevice();
              },
              child: const Text('Device'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImageFromCamera();
              },
              child: const Text('Camera'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImageFromDevice() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        final fileSizeMB = fileSize / 1024 / 1024;

        if (fileSize > 32 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '❌ Image too large: ${fileSizeMB.toStringAsFixed(2)}MB\nMax: 32MB allowed',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        setState(() => _foodImage = file);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Image selected: ${fileSizeMB.toStringAsFixed(2)}MB',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        final fileSizeMB = fileSize / 1024 / 1024;

        if (fileSize > 32 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '❌ Image too large: ${fileSizeMB.toStringAsFixed(2)}MB\nMax: 32MB allowed',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        setState(() => _foodImage = file);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Image selected: ${fileSizeMB.toStringAsFixed(2)}MB',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      _showError('Error taking photo: $e');
    }
  }

  Future<void> _saveMenuItem() async {
    if (nameController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty) {
      _showError('Please fill all required fields');
      return;
    }

    final price = double.tryParse(priceController.text.trim());
    if (price == null || price <= 0) {
      _showError('Please enter a valid price');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      // Upload image if selected
      if (_foodImage != null) {
        print('🖼️ Uploading food image...');
        imageUrl = await ImageService.uploadToImgBB(_foodImage!);

        if (imageUrl == 'SIZE_EXCEEDED') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Image too large! Maximum 32MB allowed.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        if (imageUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Image upload failed. Check internet.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Keep existing image URL if not changing
      if (imageUrl == null && widget.existingItem != null) {
        imageUrl = widget.existingItem!['image_url'];
      }

      if (widget.existingItem != null) {
        // Update existing item
        final success = await MenuService.updateMenuItem(
          itemId: widget.existingItem!['id'],
          name: nameController.text.trim(),
          price: price,
          description: descriptionController.text.trim(),
          imageUrl: imageUrl,
          type: _selectedType,
          isAvailable: _isAvailable,
        );

        if (success && mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item updated successfully')),
          );
        } else {
          _showError('Failed to update menu item');
        }
      } else {
        // Add new item
        final result = await MenuService.addMenuItem(
          messId: widget.messId,
          name: nameController.text.trim(),
          price: price,
          description: descriptionController.text.trim(),
          imageUrl: imageUrl,
          type: _selectedType,
          isAvailable: _isAvailable,
        );

        if (result['success'] && mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item added successfully')),
          );
        } else {
          _showError(result['message'] ?? 'Failed to add menu item');
        }
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Error"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingItem != null ? 'Edit Menu Item' : 'Add Menu Item',
        ),
        backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Upload Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: Column(
                children: [
                  if (_foodImage != null)
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_foodImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else if (widget.existingItem != null &&
                      widget.existingItem!['image_url'] != null)
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.existingItem!['image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.restaurant,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: Icon(
                        Icons.restaurant,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(Icons.image),
                    label: Text(
                      _foodImage != null ||
                              widget.existingItem?['image_url'] != null
                          ? 'Change Image'
                          : 'Upload Image',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 27, 84, 78),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Name Field
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Item Name *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.restaurant_menu),
              ),
            ),
            const SizedBox(height: 16),

            // Price Field
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price (₹) *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 16),

            // Description Field
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),

            // Type Selection
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Food Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Veg'),
                          value: 'veg',
                          groupValue: _selectedType,
                          onChanged: (value) {
                            setState(() => _selectedType = value!);
                          },
                          contentPadding: EdgeInsets.zero,
                          visualDensity: const VisualDensity(vertical: -4),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Non-Veg'),
                          value: 'non-veg',
                          groupValue: _selectedType,
                          onChanged: (value) {
                            setState(() => _selectedType = value!);
                          },
                          contentPadding: EdgeInsets.zero,
                          visualDensity: const VisualDensity(vertical: -4),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Jain'),
                          value: 'jain',
                          groupValue: _selectedType,
                          onChanged: (value) {
                            setState(() => _selectedType = value!);
                          },
                          contentPadding: EdgeInsets.zero,
                          visualDensity: const VisualDensity(vertical: -4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Availability Switch
            SwitchListTile(
              title: const Text('Available'),
              subtitle: Text(
                _isAvailable ? 'Item is available' : 'Item is not available',
              ),
              value: _isAvailable,
              onChanged: (value) {
                setState(() => _isAvailable = value);
              },
              activeColor: const Color.fromARGB(255, 27, 84, 78),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveMenuItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 27, 84, 78),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Text(
                        widget.existingItem != null
                            ? 'Update Item'
                            : 'Add Item',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
