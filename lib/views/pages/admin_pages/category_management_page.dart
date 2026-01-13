// views/pages/admin_pages/category_management_page.dart

import 'package:Tiffinity/data/category_model.dart';
import 'package:flutter/material.dart';
import 'package:Tiffinity/services/menu_service.dart';
import 'package:Tiffinity/services/mess_service.dart';
import 'package:Tiffinity/services/auth_services.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  List<Category> categories = [];
  int? messId;
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => isLoading = true);

    try {
      final currentUser = await AuthService.currentUser;
      if (currentUser == null) return;

      final mess = await MessService.getMessByOwner(currentUser['uid']);
      if (mess != null) {
        final fetchedCategories = await MenuService.getCategories(mess['id']);
        setState(() {
          messId = mess['id'];
          categories = fetchedCategories;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g., Monday Specials',
                    prefixIcon: Icon(Icons.category),
                  ),
                  textCapitalization: TextCapitalization.words,
                  maxLength: 50,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Min 2 characters. Letters, numbers, spaces, and hyphens only.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Category name too short')),
                    );
                    return;
                  }

                  Navigator.pop(context, true);
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

    if (result == true && controller.text.trim().isNotEmpty) {
      final success = await MenuService.createCategory(
        messId: messId!,
        categoryName: controller.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category created successfully')),
          );
          _loadCategories();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create category')),
          );
        }
      }
    }
  }

  Future<void> _showEditCategoryDialog(Category category) async {
    if (category.isReserved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot edit reserved category')),
      );
      return;
    }

    final controller = TextEditingController(text: category.name);

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Category'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                prefixIcon: Icon(Icons.edit),
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: 50,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 27, 84, 78),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update'),
              ),
            ],
          ),
    );

    if (result == true && controller.text.trim() != category.name) {
      final success = await MenuService.updateCategory(
        messId: messId!,
        oldName: category.name,
        newName: controller.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Category updated' : 'Update failed'),
          ),
        );
        if (success) _loadCategories();
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    if (category.isReserved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete reserved category')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Category'),
            content: Text(
              'All ${category.itemCount} items will be moved to "Daily Menu Items". Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await MenuService.deleteCategory(
        messId: messId!,
        categoryName: category.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Category deleted' : 'Delete failed'),
          ),
        );
        if (success) _loadCategories();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (messId == null) {
      return const Scaffold(
        body: Center(child: Text('No mess found. Please create a mess first.')),
      );
    }

    final filteredCategories =
        categories
            .where(
              (cat) =>
                  cat.name.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Category List
          Expanded(
            child:
                filteredCategories.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No categories yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = filteredCategories[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  category.isReserved
                                      ? Colors.blue[100]
                                      : const Color.fromARGB(
                                        255,
                                        27,
                                        84,
                                        78,
                                      ).withOpacity(0.1),
                              child: Icon(
                                category.isReserved
                                    ? Icons.star
                                    : Icons.category,
                                color:
                                    category.isReserved
                                        ? Colors.blue
                                        : const Color.fromARGB(255, 27, 84, 78),
                              ),
                            ),
                            title: Text(
                              category.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('${category.itemCount} items'),
                            trailing:
                                category.isReserved
                                    ? const Chip(
                                      label: Text(
                                        'Default',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: Colors.blue,
                                      labelStyle: TextStyle(
                                        color: Colors.white,
                                      ),
                                    )
                                    : PopupMenuButton(
                                      itemBuilder:
                                          (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete,
                                                    size: 20,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showEditCategoryDialog(category);
                                        } else if (value == 'delete') {
                                          _deleteCategory(category);
                                        }
                                      },
                                    ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Category',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
