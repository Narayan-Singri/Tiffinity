import 'package:Tiffinity/views/pages/admin_pages/admin_widget_tree.dart';
import 'package:flutter/material.dart';

class AdminMainScaffold extends StatelessWidget {
  const AdminMainScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: AdminWidgetTree());
  }
}
