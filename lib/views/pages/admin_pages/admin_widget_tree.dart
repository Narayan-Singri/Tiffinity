import 'package:flutter/material.dart';
import 'package:Tiffinity/data/notifiers.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/services/mess_service.dart';
import 'package:Tiffinity/views/pages/admin_pages/admin_home_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/menu_management_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/admin_profile_page.dart';
import 'package:Tiffinity/views/widgets/admin_navbar_widget.dart';

class AdminWidgetTree extends StatefulWidget {
  const AdminWidgetTree({super.key});

  @override
  State<AdminWidgetTree> createState() => _AdminWidgetTreeState();
}

class _AdminWidgetTreeState extends State<AdminWidgetTree> {
  String _messName = 'Tiffinity';

  @override
  void initState() {
    super.initState();
    _loadMessName();
  }

  Future<void> _loadMessName() async {
    try {
      final currentUser = await AuthService.currentUser;
      if (currentUser != null) {
        final mess = await MessService.getMessByOwner(currentUser['uid']);
        if (mess != null && mounted) {
          setState(() {
            _messName = mess['name'] ?? 'Tiffinity';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading mess name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const AdminHomePage(),
      const MenuManagementPage(),
      const AdminProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _messName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: adminSelectedPageNotifier,
        builder: (context, selectedPage, child) {
          return pages.elementAt(selectedPage);
        },
      ),
      bottomNavigationBar: const AdminNavbarWidget(),
    );
  }
}
