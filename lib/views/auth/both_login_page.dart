import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/auth/both_signup_page.dart';
import 'package:Tiffinity/views/auth/email_verification_page.dart';
import 'package:Tiffinity/views/auth/email_otp_login_page.dart';
import 'package:Tiffinity/views/auth/forgot_password_page.dart';
import 'package:Tiffinity/views/pages/admin_pages/admin_widget_tree.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_location_page.dart';
import 'package:Tiffinity/views/widgets/auth_field.dart';
import 'package:Tiffinity/views/widgets/auth_gradient_button.dart';
import 'package:flutter/material.dart';

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
        final user = result['user'] as Map<String, dynamic>;
        final storedRole = user['role'] ?? '';

        if (storedRole != widget.role) {
          _showError(
            "You are registered as a ${storedRole.toString().toUpperCase()}. "
                "Please select ${storedRole.toString().toUpperCase()} role to login.",
          );
          return;
        }

        if (!mounted) return;
        _navigateByRole(user);
      } else {
        _showError(result['message']?.toString() ?? 'Login failed');
      }
    } on AuthException catch (e) {
      final msg = e.message;
      if (msg.toLowerCase().contains('email not verified')) {
        await _handleUnverifiedUser();
        return;
      }
      _showError(msg);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleUnverifiedUser() async {
    final email = emailController.text.trim();
    try {
      await _authService.resendVerificationOtp(email: email, role: widget.role);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationPage(email: email, role: widget.role),
        ),
      );
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _navigateByRole(Map<String, dynamic> user) {
    final storedRole = user['role']?.toString() ?? '';
    if (storedRole == 'admin') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminWidgetTree()),
            (route) => false,
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerLocationPage(userId: user['uid'].toString()),
      ),
          (route) => false,
    );
  }

  // Modernized Error Handling (Floating SnackBar instead of Dialog)
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        elevation: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Enhanced Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF005C52), Color(0xFF009688), Color(0xFFE9FFFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Modern Back Button Alignment
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // 2. Entrance Animation for the Card
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 50.0, end: 0.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, value),
                              child: Opacity(
                                opacity: 1 - (value / 50.0),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  // Softer, tinted shadow instead of harsh black
                                  color: const Color(0xFF005C52).withOpacity(0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 3. Role-based Contextual Icon
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9FFFA),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFB5E3DB), width: 1),
                                  ),
                                  child: Icon(
                                    widget.role == 'admin'
                                        ? Icons.storefront_rounded
                                        : Icons.waving_hand_rounded,
                                    color: const Color(0xFF00796B),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                Text(
                                  widget.role == 'admin'
                                      ? 'Mess Owner Login'
                                      : 'Welcome Back',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF12403B),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to continue ordering your meals.',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.55),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                AuthField(
                                  hintText: "Email",
                                  icon: Icons.email_outlined,
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                AuthField(
                                  hintText: "Password",
                                  icon: Icons.lock_outline_rounded,
                                  controller: passwordController,
                                  isPassword: true,
                                ),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      splashFactory: NoSplash.splashFactory,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ForgotPasswordPage(
                                            initialEmail: emailController.text.trim(),
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Color(0xFF00796B),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),
                                AuthGradientButton(
                                  text: _isLoading ? 'Authenticating...' : 'Sign in',
                                  onTap: _isLoading ? () {} : _handleLogin,
                                ),
                                const SizedBox(height: 16),

                                // 4. Modern Soft Tinted Button for OTP
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EmailOtpLoginPage(role: widget.role),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFFF0FDF8),
                                    minimumSize: const Size(double.infinity, 54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.password_rounded,
                                    color: Color(0xFF00796B),
                                  ),
                                  label: const Text(
                                    'Login With Email OTP',
                                    style: TextStyle(
                                      color: Color(0xFF00796B),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Bottom Signup Text
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BothSignupPage(role: widget.role),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Optional: Overlay loading indicator to block interactions during auth
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00796B),
                ),
              ),
            ),
        ],
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