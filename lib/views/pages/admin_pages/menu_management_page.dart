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
  List<Map<String, dynamic>> menuItems = [];
  int? messId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  // Helper function to convert int to bool
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return true; // Default to available
  }

  Future<void> _loadMenuItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = await AuthService.currentUser;
      if (currentUser == null) return;

      // Get mess by owner
      final mess = await MessService.getMessByOwner(currentUser['uid']);

      if (mess != null) {
        final menuItems = await MenuService.getMenuItems(mess['id']);
        setState(() {
          messId = mess['id'];
          this.menuItems = menuItems;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading menu: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteMenuItem(int itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Item'),
            content: const Text(
              'Are you sure you want to delete this menu item? This action cannot be undone.',
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
      // ✅ FIX: MenuService.deleteMenuItem() returns bool
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
    // ✅ FIX: MenuService.updateMenuItem() returns bool
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
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (messId == null) {
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
          menuItems.isEmpty
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
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    final isAvailable = _toBool(item['is_available']);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      // Dim card if out of stock
                      color: isAvailable ? null : Colors.grey[200],
                      child: ListTile(
                        leading: Stack(
                          children: [
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
                                        color: Colors.grey[300],
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
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.restaurant,
                                    color: Colors.grey[400],
                                  ),
                                ),
                            // Show overlay if out of stock
                            if (!isAvailable)
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                          ],
                        ),
                        // Inside ListView.builder -> Card -> ListTile
                        title: Text(
                          (item['name'] ?? 'Unnamed')
                              .toString(), // Ensure it's a string
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16, // Ensure visible size
                            decoration:
                                isAvailable
                                    ? TextDecoration.none
                                    : TextDecoration.lineThrough,
                            // Force color to black so it's visible on white cards
                            color:
                                isAvailable ? Colors.black : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis, // Prevent layout break
                        ),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${item['price']}',
                              style: TextStyle(
                                color:
                                    isAvailable ? Colors.black87 : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Status badge with distinct styling
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isAvailable
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color:
                                      isAvailable ? Colors.green : Colors.red,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isAvailable ? 'Available' : 'Out of Stock',
                                style: TextStyle(
                                  color:
                                      isAvailable ? Colors.green : Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          itemBuilder:
                              (context) => const [
                                PopupMenuItem(
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
                                      Icon(Icons.toggle_on, size: 20),
                                      SizedBox(width: 8),
                                      Text('Toggle Availability'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
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
                                        messId: messId!,
                                        existingItem: item,
                                      ),
                                ),
                              );
                              if (result == true) _loadMenuItems();
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
              builder: (context) => AddMenuItemPage(messId: messId!),
            ),
          );
          if (result == true) _loadMenuItems();
        },
        backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
