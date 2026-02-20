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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF005C52), Color(0xFF009688), Color(0xFFE9FFFA)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.role == 'admin'
                              ? 'Mess Owner Login'
                              : 'Welcome Back',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF12403B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue ordering your meals.',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AuthField(
                          hintText: "Email",
                          icon: Icons.email_outlined,
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        AuthField(
                          hintText: "Password",
                          icon: Icons.lock_outline_rounded,
                          controller: passwordController,
                          isPassword: true,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ForgotPasswordPage(
                                        initialEmail:
                                            emailController.text.trim(),
                                      ),
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF00796B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        AuthGradientButton(
                          text: _isLoading ? 'Loading...' : 'Sign in',
                          onTap: _isLoading ? () {} : _handleLogin,
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => EmailOtpLoginPage(role: widget.role),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            side: const BorderSide(
                              color: Color(0xFFB5E3DB),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BothSignupPage(role: widget.role),
                        ),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                        children: const [
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF013B33),
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
