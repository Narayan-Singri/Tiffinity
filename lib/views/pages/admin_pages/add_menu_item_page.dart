import 'package:Tiffinity/models/category_model.dart';
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
  final _formKey = GlobalKey<FormState>();
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

  Color get _primaryColor => const Color.fromARGB(255, 27, 84, 78);

  @override
  void initState() {
    super.initState();
    loadCategories();

    if (widget.existingItem != null) {
      nameController.text = widget.existingItem!['name'] ?? '';
      priceController.text = widget.existingItem!['price']?.toString() ?? '';
      descriptionController.text = widget.existingItem!['description'] ?? '';
      selectedType = widget.existingItem!['type'] ?? 'veg';
      isAvailable = _toBool(widget.existingItem!['is_available']);

      final itemCategory = widget.existingItem!['category']?.toString();
      if (itemCategory != null && itemCategory.isNotEmpty) {
        setState(() {
          selectedCategory = itemCategory;
        });
      }
    }
  }

  Future<void> loadCategories() async {
    final categories = await MenuService.getCategories(widget.messId);

    setState(() {
      availableCategories = categories;

      if (selectedCategory == null || selectedCategory!.isEmpty) {
        if (availableCategories.isNotEmpty) {
          selectedCategory = availableCategories.first.name;
        } else {
          selectedCategory = 'Daily Menu Items';
        }
      }
    });
  }

  Future<void> _showCreateCategoryDialog() async {
    final TextEditingController categoryController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.category, color: Color.fromARGB(255, 27, 84, 78)),
            SizedBox(width: 8),
            Text('New Category'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: categoryController,
              decoration: _inputDecoration(hint: 'e.g., Monday Specials'),
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
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = categoryController.text.trim();
              if (name.length >= 2) {
                Navigator.pop(context, name);
              } else {
                _showSnackbar('Category name must be at least 2 characters', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final success = await MenuService.createCategory(
        messId: widget.messId,
        name: result,
      );

      if (success) {
        await loadCategories();
        setState(() {
          selectedCategory = result;
        });
        if (mounted) _showSnackbar('Category "$result" created successfully', isError: false);
      } else {
        if (mounted) _showSnackbar('Failed to create category', isError: true);
      }
    }
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return true;
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upload Food Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  child: Icon(Icons.photo_library, color: _primaryColor),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  child: Icon(Icons.camera_alt, color: _primaryColor),
                ),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        final fileSizeMB = fileSize / (1024 * 1024);

        if (fileSize > 32 * 1024 * 1024) {
          if (mounted) _showSnackbar("Image too large (${fileSizeMB.toStringAsFixed(2)}MB). 32MB allowed.", isError: true);
          return;
        }

        setState(() => foodImage = file);
        if (mounted) _showSnackbar("Image selected successfully", isError: false);
      }
    } catch (e) {
      _showSnackbar('Error picking image: $e', isError: true);
    }
  }

  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(priceController.text.trim());
    if (price == null || price <= 0) {
      _showSnackbar('Please enter a valid price', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      String? imageUrl;

      if (foodImage != null) {
        imageUrl = await ImageService.uploadToImgBB(foodImage!);

        if (imageUrl == 'SIZE_EXCEEDED' || imageUrl == null) {
          if (mounted) _showSnackbar('Image upload failed. Please try again.', isError: true);
          setState(() => isLoading = false);
          return;
        }
      }

      if (imageUrl == null && widget.existingItem != null) {
        imageUrl = widget.existingItem!['image_url'];
      }

      if (widget.existingItem != null) {
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
          _showSnackbar('Menu item updated successfully', isError: false);
        } else {
          _showSnackbar('Failed to update menu item', isError: true);
        }
      } else {
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
          _showSnackbar('Menu item added successfully', isError: false);
        } else {
          _showSnackbar('Failed to add menu item', isError: true);
        }
      }
    } catch (e) {
      _showSnackbar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0).copyWith(bottom: 100),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildImageUploader(),
                        const SizedBox(height: 16),
                        _buildDetailsCard(),
                        const SizedBox(height: 16),
                        _buildClassificationCard(),
                        const SizedBox(height: 16),
                        _buildAvailabilityCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  // ============================================
  // APP BAR
  // ============================================
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      backgroundColor: _primaryColor,
      elevation: 2,
      shadowColor: Colors.black38,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(60),
          bottomRight: Radius.circular(60),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
        title: Text(
          widget.existingItem != null ? 'Edit Menu Item' : 'Add Menu Item',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        background: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(60),
            bottomRight: Radius.circular(60),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 18, 65, 60),
                      Color.fromARGB(255, 27, 84, 78)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                right: -20,
                top: 10,
                child: Icon(
                  Icons.restaurant_menu,
                  size: 130,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // IMAGE UPLOADER
  // ============================================
  Widget _buildImageUploader() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: foodImage != null
                  ? Image.file(foodImage!, fit: BoxFit.cover)
                  : (widget.existingItem != null && widget.existingItem!['image_url'] != null)
                  ? Image.network(
                widget.existingItem!['image_url'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
              )
                  : _buildImagePlaceholder(),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt, size: 16, color: _primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      foodImage != null || widget.existingItem?['image_url'] != null ? 'Change' : 'Upload',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: _primaryColor.withOpacity(0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 60, color: _primaryColor.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text(
            'Tap to add item photo',
            style: TextStyle(color: _primaryColor.withOpacity(0.7), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ============================================
  // DETAILS CARD
  // ============================================
  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(Icons.edit, 'Item Name *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: nameController,
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: _inputDecoration(hint: 'e.g., Paneer Butter Masala'),
            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          _buildFieldLabel(Icons.currency_rupee, 'Price *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: priceController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            decoration: _inputDecoration(hint: 'e.g., 120'),
            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          _buildFieldLabel(Icons.description_outlined, 'Description (Optional)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: descriptionController,
            maxLines: 3,
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: _inputDecoration(hint: 'Describe the dish...'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // CLASSIFICATION CARD
  // ============================================
  Widget _buildClassificationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(Icons.fastfood_outlined, 'Food Type'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTypeChip('veg', 'Veg', Colors.green),
              const SizedBox(width: 8),
              _buildTypeChip('non-veg', 'Non-Veg', Colors.red),
              const SizedBox(width: 8),
              _buildTypeChip('jain', 'Jain', Colors.orange),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel(Icons.category_outlined, 'Category'),
              InkWell(
                onTap: _showCreateCategoryDialog,
                child: Text(
                  '+ Create New',
                  style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (availableCategories.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
              child: const Center(
                child: Text(
                  'No categories yet. Create one above!',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            DropdownButtonFormField<String>(
              value: availableCategories.any((cat) => cat.name == selectedCategory)
                  ? selectedCategory
                  : availableCategories.first.name,
              decoration: _inputDecoration(hint: 'Select Category'),
              icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
              items: availableCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category.name,
                  child: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedCategory = value),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, Color color) {
    final isSelected = selectedType == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // AVAILABILITY CARD
  // ============================================
  Widget _buildAvailabilityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: SwitchListTile(
        title: const Text('Available in Menu', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(isAvailable ? 'Customers can order this item' : 'Hidden from customers (Out of Stock)', style: const TextStyle(fontSize: 12)),
        value: isAvailable,
        onChanged: (value) => setState(() => isAvailable = value),
        activeColor: Colors.white,
        activeTrackColor: Colors.green,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade300,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  // ============================================
  // UI HELPERS
  // ============================================
  Widget _buildFieldLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade300)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // ============================================
  // FLOATING BOTTOM BUTTON
  // ============================================
  Widget _buildBottomButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: isLoading ? null : _saveMenuItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                widget.existingItem != null ? 'UPDATE ITEM' : 'ADD ITEM',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}