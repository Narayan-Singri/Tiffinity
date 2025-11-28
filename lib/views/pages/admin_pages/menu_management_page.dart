import 'package:flutter/material.dart';
import 'package:Tiffinity/services/menu_service.dart';
import 'package:Tiffinity/services/mess_service.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/pages/admin_pages/add_menu_item_page.dart';

class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage> {
  List<Map<String, dynamic>> _menuItems = [];
  int? _messId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  // ✅ Helper function to convert int to bool
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return true; // Default to available
  }

  Future<void> _loadMenuItems() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = await AuthService.currentUser;
      if (currentUser == null) return;

      // Get mess by owner
      final mess = await MessService.getMessByOwner(currentUser['uid']);

      if (mess != null) {
        final menuItems = await MenuService.getMenuItems(mess['id']);
        setState(() {
          _messId = mess['id'];
          _menuItems = menuItems;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading menu: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMenuItem(int itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Item'),
            content: const Text(
              'Are you sure you want to delete this menu item?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await MenuService.deleteMenuItem(itemId);
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Menu item deleted')));
        _loadMenuItems();
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete item')));
      }
    }
  }

  Future<void> _toggleAvailability(int itemId, bool currentStatus) async {
    final success = await MenuService.updateMenuItem(
      itemId: itemId,
      isAvailable: !currentStatus,
    );

    if (success) {
      _loadMenuItems();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update availability')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_messId == null) {
      return const Scaffold(
        body: Center(child: Text('No mess found. Please create a mess first.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        foregroundColor: Colors.white,
      ),
      body:
          _menuItems.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No menu items yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap + to add your first item',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadMenuItems,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    final isAvailable = _toBool(
                      item['is_available'],
                    ); // ✅ Convert int to bool

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      child: ListTile(
                        leading:
                            item['image_url'] != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item['image_url'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.restaurant,
                                          color: Colors.grey[400],
                                        ),
                                      );
                                    },
                                  ),
                                )
                                : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.restaurant,
                                    color: Colors.grey[400],
                                  ),
                                ),
                        title: Text(
                          item['name'] ?? 'Unnamed',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₹${item['price']}'),
                            Text(
                              isAvailable ? 'Available' : 'Not Available',
                              style: TextStyle(
                                color: isAvailable ? Colors.green : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
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
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(
                                        isAvailable
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isAvailable
                                            ? 'Mark Unavailable'
                                            : 'Mark Available',
                                      ),
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
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => AddMenuItemPage(
                                        messId: _messId!,
                                        existingItem: item,
                                      ),
                                ),
                              );
                              if (result == true) {
                                _loadMenuItems();
                              }
                            } else if (value == 'toggle') {
                              _toggleAvailability(item['id'], isAvailable);
                            } else if (value == 'delete') {
                              _deleteMenuItem(item['id']);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMenuItemPage(messId: _messId!),
            ),
          );
          if (result == true) {
            _loadMenuItems();
          }
        },
        backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
