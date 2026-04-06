import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for SystemNavigator.pop()
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
  DateTime? currentBackPressTime; // Variable to track the last back press

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

    return ValueListenableBuilder<int>(
      valueListenable: customerSelectedPageNotifier,
      builder: (context, selectedIndex, _) {
        final safeIndex = selectedIndex >= pages.length ? 0 : selectedIndex;

        return PopScope(
          canPop: false, // Never let the system automatically pop/close the app
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;

            if (safeIndex != 0) {
              // If not on Home tab, go to Home tab
              customerSelectedPageNotifier.value = 0;
            } else {
              // We are on the Home tab, implement double tap to exit
              final now = DateTime.now();
              if (currentBackPressTime == null ||
                  now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {

                // First tap: Update time and show message
                currentBackPressTime = now;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Press back again to exit'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                // Second tap within 2 seconds: Force exit the app
                SystemNavigator.pop();
              }
            }
          },
          child: Scaffold(
            extendBody: true,
            body: pages[safeIndex],
            bottomNavigationBar: const CustomerNavBarWidget(),
          ),
        );
      },
    );
  }
}