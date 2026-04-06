import 'package:Tiffinity/views/pages/admin_pages/admin_home_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/admin_profile_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/admin_subscriptions_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/menu_management_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/weekly_menu_management_page.dart';
import 'package:Tiffinity/views/widgets/admin_navbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for SystemNavigator.pop()
import 'package:Tiffinity/data/notifiers.dart';

class AdminWidgetTree extends StatefulWidget {
  const AdminWidgetTree({super.key});

  @override
  State<AdminWidgetTree> createState() => _AdminWidgetTreeState();
}

class _AdminWidgetTreeState extends State<AdminWidgetTree> {
  DateTime? currentBackPressTime; // Variable to track the last back press

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: adminSelectedPageNotifier,
      builder: (context, selectedPage, child) {
        Widget currentPage;
        switch (selectedPage) {
          case 0:
            currentPage = const AdminHomePage();
            break;
          case 1:
            currentPage = const MenuManagementPage();
            break;
          case 2:
            currentPage = const WeeklyMenuManagementPage();
            break;
          case 3:
            currentPage = const AdminSubscriptionsPage();
            break;
          case 4:
            currentPage = const AdminProfilePage();
            break;
          default:
            currentPage = const AdminHomePage();
        }

        return PopScope(
          canPop: false, // Never let the system automatically pop/close the app
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;

            if (selectedPage != 0) {
              // If not on Home tab, go to Home tab
              adminSelectedPageNotifier.value = 0;
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
            body: currentPage,
            bottomNavigationBar: const AdminNavbarWidget(),
          ),
        );
      },
    );
  }
}