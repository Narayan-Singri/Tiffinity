import 'package:Tiffinity/data/constants.dart';
import 'package:Tiffinity/data/notifiers.dart';
import 'package:Tiffinity/views/auth/welcome_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/admin_widget_tree.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_widget_tree.dart';
import 'package:Tiffinity/services/notification_service.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // Initialize Firebase only for messaging
  await Firebase.initializeApp();
  await NotificationService().initialize();

  // Load cart data
  await CartHelper.loadCart();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    initThemeMode();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void initThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool repeat = prefs.getBool(KConstants.themeModeKey) ?? false;
    isDarkModeNotifier.value = repeat;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
          ),
          home: FutureBuilder<bool>(
            future: AuthService.isLoggedIn(),
            builder: (context, snapshot) {
              // Show loading while checking auth state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final bool isLoggedIn = snapshot.data ?? false;

              // User is not logged in
              if (!isLoggedIn) {
                return const WelcomePage();
              }

              // User is logged in - check their role
              return FutureBuilder<Map<String, dynamic>?>(
                future: AuthService.currentUser,
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final user = userSnapshot.data;
                  if (user != null && user['role'] != null) {
                    String role = user['role'];
                    if (role == 'customer') {
                      return const CustomerWidgetTree();
                    } else if (role == 'admin') {
                      return const AdminWidgetTree();
                    }
                  }

                  // Fallback if no role found
                  return const WelcomePage();
                },
              );
            },
          ),
        );
      },
    );
  }
}
