import 'package:Tiffinity/views/pages/customer_pages/customer_location_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/auth/both_login_page.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_widget_tree.dart';
import 'package:Tiffinity/views/widgets/auth_field.dart';
import 'package:Tiffinity/views/widgets/auth_gradient_button.dart';
import 'package:Tiffinity/views/pages/admin_pages/admin_setup_page.dart';

class BothSignupPage extends StatefulWidget {
  final String role;
  const BothSignupPage({super.key, required this.role});

  @override
  State<BothSignupPage> createState() => _BothSignupPageState();
}

class _BothSignupPageState extends State<BothSignupPage> {
  bool passwordsDoNotMatch = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneNumController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneNumController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    setState(() {
      passwordsDoNotMatch = false;
      _isLoading = true;
    });

    if (!validateFields([
      nameController,
      emailController,
      passwordController,
      confirmPasswordController,
      phoneNumController,
    ])) {
      _showError("Please fill all the fields");
      setState(() => _isLoading = false);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        passwordsDoNotMatch = true;
        _isLoading = false;
      });
      return;
    }

    try {
      final result = await _authService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        phone: phoneNumController.text.trim(),
        role: widget.role,
      );

      if (result['success']) {
        final user = result['user'];

        if (!mounted) return;

        // Redirect based on role
        if (widget.role == 'admin') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => AdminSetupPage(userId: user['uid']),
            ),
            (route) => false,
          );
        } else {
          // ✅ Navigate to Location Page for Customer
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder:
                  (_) => CustomerLocationPage(
                    userId: user['uid'], // Pass user ID from signup response
                  ),
            ),
            (route) => false,
          );
        }
      }
    } on Exception catch (e) {
      _showError(e.toString());
    } catch (e) {
      _showError("Sign up failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      body: SafeArea(
        child: KeyboardDismissOnTap(
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      const Text(
                        "Sign Up.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildFormFields(),
                      const Spacer(),
                      AuthGradientButton(
                        text: "Sign Up",
                        onTap: _handleSignUp,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 16),
                      _buildSignInLink(),
                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        AuthField(
          hintText: "Name",
          icon: Icons.person,
          controller: nameController,
        ),
        const SizedBox(height: 16),
        AuthField(
          hintText: "Phone no.",
          icon: Icons.phone,
          controller: phoneNumController,
        ),
        const SizedBox(height: 16),
        AuthField(
          hintText: "Email",
          icon: Icons.email,
          controller: emailController,
        ),
        const SizedBox(height: 16),
        AuthField(
          hintText: "Password",
          icon: Icons.lock,
          isPassword: true,
          controller: passwordController,
        ),
        const SizedBox(height: 16),
        AuthField(
          hintText: "Confirm Password",
          icon: Icons.lock,
          isPassword: true,
          controller: confirmPasswordController,
        ),
        if (passwordsDoNotMatch)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Passwords do not match",
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSignInLink() {
    return RichText(
      text: TextSpan(
        text: "Already have an account? ",
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
        children: [
          TextSpan(
            text: "Sign In",
            style: const TextStyle(
              color: Color(0xFF007569),
              fontWeight: FontWeight.bold,
            ),
            recognizer:
                TapGestureRecognizer()
                  ..onTap = () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BothLoginPage(role: widget.role),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }

  bool validateFields(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      if (controller.text.trim().isEmpty) return false;
    }
    return true;
  }
}

class KeyboardDismissOnTap extends StatelessWidget {
  final Widget child;
  const KeyboardDismissOnTap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
