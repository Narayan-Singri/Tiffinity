import 'package:Tiffinity/views/pages/admin_pages/admin_home_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/admin_profile_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/admin_subscriptions_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/menu_management_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/weekly_menu_management_page.dart';
import 'package:Tiffinity/views/widgets/admin_navbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:Tiffinity/data/notifiers.dart';

class AdminWidgetTree extends StatelessWidget {
  const AdminWidgetTree({super.key});

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

        return Scaffold(
          body: currentPage,
          bottomNavigationBar: const AdminNavbarWidget(),
        );
      },
    );
  }
}
