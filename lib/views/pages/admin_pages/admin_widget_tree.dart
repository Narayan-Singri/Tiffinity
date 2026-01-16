import 'package:flutter/material.dart';
import 'package:Tiffinity/views/pages/admin_pages/admin_home_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/menu_management_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/weekly_menu_management_page.dart'; // NEW
import 'package:Tiffinity/views/pages/admin_pages/admin_profile_page.dart';

class AdminWidgetTree extends StatefulWidget {
  const AdminWidgetTree({super.key});

  @override
  State<AdminWidgetTree> createState() => _AdminWidgetTreeState();
}

class _AdminWidgetTreeState extends State<AdminWidgetTree> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const AdminHomePage(),
    const MenuManagementPage(),
    const WeeklyMenuManagementPage(), // NEW: Weekly Menu Page
    const AdminProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color.fromARGB(255, 27, 84, 78),
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_rounded),
              label: 'Menu Items',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded), // NEW
              label: 'Weekly Menu', // NEW
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
