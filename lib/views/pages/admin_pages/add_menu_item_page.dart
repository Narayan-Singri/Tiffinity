import 'package:Tiffinity/data/category_model.dart';
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
  String? selectedCategory;
  List<Category> availableCategories = [];

  String selectedType = 'veg';
  bool isAvailable = true;
  bool isLoading = false;
  File? foodImage;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Load categories first
    loadCategories();

    // Then load existing item data if editing
    if (widget.existingItem != null) {
      nameController.text = widget.existingItem!['name'] ?? '';
      priceController.text = widget.existingItem!['price']?.toString() ?? '';
      descriptionController.text = widget.existingItem!['description'] ?? '';
      selectedType = widget.existingItem!['type'] ?? 'veg';
      isAvailable = _toBool(widget.existingItem!['is_available']);

      // ✅ CRITICAL: Load category from existing item
      final itemCategory = widget.existingItem!['category']?.toString();
      print('🔍 Existing item category: $itemCategory'); // Debug

      if (itemCategory != null && itemCategory.isNotEmpty) {
        setState(() {
          selectedCategory = itemCategory;
        });
        print('✅ Set selectedCategory to: $selectedCategory'); // Debug
      }
    }
  }

  Future<void> loadCategories() async {
    final categories = await MenuService.getCategories(widget.messId);

    setState(() {
      availableCategories = categories;

      // ✅ ONLY set default if no category was set from existingItem
      if (selectedCategory == null || selectedCategory!.isEmpty) {
        if (availableCategories.isNotEmpty) {
          selectedCategory = availableCategories.first.name;
        } else {
          selectedCategory = 'Daily Menu Items';
        }
      }

      print('📦 Categories loaded. Selected: $selectedCategory'); // Debug
    });
  }

  Future<void> _showCreateCategoryDialog() async {
    final TextEditingController categoryController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g., Monday Specials',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  maxLength: 50,
                ),
                const SizedBox(height: 8),
                Text(
                  'Min 2 characters. Letters, numbers, spaces, and hyphens only.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = categoryController.text.trim();
                  if (name.length >= 2) {
                    Navigator.pop(context, name);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Category name must be at least 2 characters',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 27, 84, 78),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Create'),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      // Create the category
      final success = await MenuService.createCategory(
        messId: widget.messId,
        categoryName: result,
      );

      if (success) {
        // Reload categories
        await loadCategories();

        // Select the newly created category
        setState(() {
          selectedCategory = result;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Category "$result" created successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create category'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Convert int to bool
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
          content: const Text('Choose where to upload photo from'),
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
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        final fileSizeMB = fileSize / (1024 * 1024);

        if (fileSize > 32 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Image too large (${fileSizeMB.toStringAsFixed(2)}MB). 32MB allowed.",
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        setState(() {
          foodImage = file;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Image selected (\${fileSizeMB.toStringAsFixed(2)}MB)",
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
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        final fileSizeMB = fileSize / (1024 * 1024);

        if (fileSize > 32 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Image too large (${fileSizeMB.toStringAsFixed(2)}MB). 32MB allowed.',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        setState(() {
          foodImage = file;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image selected (\${fileSizeMB.toStringAsFixed(2)}MB)',
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

    setState(() {
      isLoading = true;
    });

    try {
      String? imageUrl;

      // Upload image if selected
      if (foodImage != null) {
        print('📤 Uploading food image...');
        imageUrl = await ImageService.uploadToImgBB(foodImage!);

        if (imageUrl == 'SIZE_EXCEEDED') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image too large! Maximum 32MB allowed.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          setState(() {
            isLoading = false;
          });
          return;
        }

        if (imageUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image upload failed. Check internet.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            isLoading = false;
          });
          return;
        }
      }

      // Keep existing image URL if not changing
      if (imageUrl == null && widget.existingItem != null) {
        imageUrl = widget.existingItem!['image_url'];
      }

      if (widget.existingItem != null) {
        // Update existing item
        // ✅ FIX: MenuService.updateMenuItem() returns bool, not Map
        final success = await MenuService.updateMenuItem(
          itemId: widget.existingItem!['id'],
          name: nameController.text.trim(),
          price: price,
          description: descriptionController.text.trim(),
          imageUrl: imageUrl,
          type: selectedType,
          category: selectedCategory,
          isAvailable: isAvailable,
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
        // ✅ FIX: MenuService.addMenuItem() returns bool, not Map
        final success = await MenuService.addMenuItem(
          messId: widget.messId,
          name: nameController.text.trim(),
          price: price,
          description: descriptionController.text.trim(),
          imageUrl: imageUrl,
          type: selectedType,
          category: selectedCategory,
          isAvailable: isAvailable,
        );

        if (success && mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item added successfully')),
          );
        } else {
          _showError('Failed to add menu item');
        }
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
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
                  if (foodImage != null)
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(foodImage!),
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
                      foodImage != null ||
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
                labelText: 'Price *',
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
                          groupValue: selectedType,
                          onChanged: (value) {
                            setState(() {
                              selectedType = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          visualDensity: const VisualDensity(vertical: -4),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Non-Veg'),
                          value: 'non-veg',
                          groupValue: selectedType,
                          onChanged: (value) {
                            setState(() {
                              selectedType = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          visualDensity: const VisualDensity(vertical: -4),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Jain'),
                          value: 'jain',
                          groupValue: selectedType,
                          onChanged: (value) {
                            setState(() {
                              selectedType = value!;
                            });
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

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showCreateCategoryDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create New'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color.fromARGB(
                            255,
                            27,
                            84,
                            78,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ✅ FIXED: Better empty state and dropdown validation
                  if (availableCategories.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.category,
                            size: 40,
                            color: Colors.orange[300],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No categories yet',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Create your first category to organize menu items',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      // ✅ CRITICAL FIX: Validate value before setting
                      value:
                          availableCategories.any(
                                (cat) => cat.name == selectedCategory,
                              )
                              ? selectedCategory
                              : availableCategories
                                  .first
                                  .name, // Use first as fallback
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                        hintText: 'Select a category',
                      ),
                      items:
                          availableCategories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category.name,
                              child: Text(category.name),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() => selectedCategory = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Availability Switch
            SwitchListTile(
              title: const Text('Available'),
              subtitle: Text(
                isAvailable ? 'Item is available' : 'Item is not available',
              ),
              value: isAvailable,
              onChanged: (value) {
                setState(() {
                  isAvailable = value;
                });
              },
              activeColor: const Color.fromARGB(255, 27, 84, 78),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: isLoading ? null : _saveMenuItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 27, 84, 78),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  isLoading
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
