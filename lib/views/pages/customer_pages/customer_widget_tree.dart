import 'package:flutter/material.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_home_page.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_orders_page.dart';
import 'package:Tiffinity/views/pages/customer_pages/my_subscriptions_page.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_profile_page.dart';
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
    final List<Widget> pages = [
      const CustomerHomePage(), // Index 0: Home
      const CustomerOrdersPage(), // Index 1: Orders
      const MySubscriptionsPage(), // Index 2: Plans/Subscriptions
      const CustomerProfilePage(), // Index 3: Profile
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
