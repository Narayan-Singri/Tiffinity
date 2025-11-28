import 'package:flutter/material.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/auth/both_login_page.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_home_page.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_orders_page.dart';
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
      const CustomerHomePage(),
      const CustomerOrdersPage(),
      const CustomerProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tiffinity',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BothLoginPage(role: 'customer'),
                  ),
                );
                // Recheck login status after returning from login page
                _checkLoginStatus();
              },
            ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: customerSelectedPageNotifier,
        builder: (context, selectedIndex, _) {
          return pages[selectedIndex];
        },
      ),
      bottomNavigationBar: const CustomerNavBarWidget(),
    );
  }
}
