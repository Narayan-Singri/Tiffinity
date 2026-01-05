import 'package:Tiffinity/views/pages/admin_pages/admin_widget_tree.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_location_page.dart';
import 'package:flutter/material.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/auth/both_signup_page.dart';
import 'package:Tiffinity/views/widgets/auth_field.dart';
import 'package:Tiffinity/views/widgets/auth_gradient_button.dart';

class BothLoginPage extends StatefulWidget {
  final String role;

  const BothLoginPage({super.key, required this.role});

  @override
  State<BothLoginPage> createState() => _BothLoginPageState();
}

class _BothLoginPageState extends State<BothLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (result['success']) {
        final user = result['user'];
        final storedRole = user['role'] ?? '';

        // Verify selected role matches stored role
        if (storedRole != widget.role) {
          _showError(
            "You are registered as a ${storedRole.toUpperCase()}. Please select ${storedRole.toUpperCase()} role to login.",
          );
          return;
        }

        if (mounted) {
          setState(() => _isLoading = false);
        }

        // Navigate based on role
        // Navigate based on role
        // Navigate based on role
        if (mounted) {
          if (storedRole == 'admin') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminWidgetTree()),
              (route) => false,
            );
          } else {
            // ✅ CUSTOMER: Navigate to location page first (Swiggy style)
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        CustomerLocationPage(userId: user['uid'].toString()),
              ),
              (route) => false,
            );
          }
        }
      } else {
        _showError(result['message'] ?? 'Login failed');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Error"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // ✅ Wrap with Center to vertically center content
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // ✅ Center content
              children: [
                const Text(
                  'Login', // ✅ Changed from 'Customer Login' or 'Admin Login' to just 'Login'
                  style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                AuthField(
                  hintText: "Email",
                  icon: Icons.email,
                  controller: emailController,
                ),
                const SizedBox(height: 15),
                AuthField(
                  hintText: "Password",
                  icon: Icons.lock,
                  controller: passwordController,
                  isPassword: true,
                ),
                const SizedBox(height: 20),
                AuthGradientButton(
                  text: _isLoading ? 'Loading...' : 'Sign in',
                  onTap: _isLoading ? () {} : _handleLogin,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BothSignupPage(role: widget.role),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: Theme.of(context).textTheme.titleMedium,
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: const Color.fromARGB(255, 27, 84, 78),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
