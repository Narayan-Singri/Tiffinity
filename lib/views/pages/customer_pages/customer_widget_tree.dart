import 'package:flutter/material.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/auth/both_login_page.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_home_page.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_orders_page.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_profile_page.dart'; // ✅ Ensure this is imported
import 'package:Tiffinity/views/widgets/customer_navbar_widget.dart';
import 'package:Tiffinity/data/notifiers.dart';

class CustomerWidgetTree extends StatefulWidget {
  const CustomerWidgetTree({super.key});

  @override
  State<CustomerWidgetTree> createState() => _CustomerWidgetTreeState();
}

class _CustomerWidgetTreeState extends State<CustomerWidgetTree> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: List must have 4 items to match the 4 Navbar buttons
    final List<Widget> pages = [
      const CustomerHomePage(), // Index 0: Home
      const CustomerOrdersPage(), // Index 1: Orders
      const Center(
        // Index 2: Plans (Placeholder)
        child: Text(
          "My Meal Subscriptions\nComing Soon",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
      const CustomerProfilePage(), // Index 3: Profile (This was missing!)
    ];

    return Scaffold(
      extendBody: true,
      body: ValueListenableBuilder<int>(
        valueListenable: customerSelectedPageNotifier,
        builder: (context, selectedIndex, _) {
          // Safety check to prevent crashing if index is out of bounds
          if (selectedIndex >= pages.length) {
            return pages[0];
          }
          return pages[selectedIndex];
        },
      ),
      bottomNavigationBar: const CustomerNavBarWidget(),
    );
  }
}
