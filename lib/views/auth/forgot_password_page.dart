import 'dart:async';

import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/widgets/auth_field.dart';
import 'package:Tiffinity/views/widgets/auth_gradient_button.dart';
import 'package:Tiffinity/views/widgets/otp_boxes.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final AuthService _authService = AuthService();
  late final TextEditingController _emailController;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _otpSent = false;
  bool _loading = false;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendIn <= 0) {
        timer.cancel();
      } else if (mounted) {
        setState(() => _resendIn--);
      }
    });
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Enter a valid email');
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.requestForgotPasswordOtp(email: email);
      if (!mounted) return;
      setState(() => _otpSent = true);
      _startResendTimer();
      _showMessage('Reset OTP sent to $email');
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text.trim();
    if (_otpController.text.trim().length != 6) {
      _showMessage('Enter a valid 6-digit OTP');
      return;
    }
    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters');
      return;
    }
    if (password != _confirmController.text.trim()) {
      _showMessage('Passwords do not match');
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.resetPasswordWithOtp(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
        newPassword: password,
      );
      if (!mounted) return;
      _showMessage('Password reset successful. Please login.');
      Navigator.pop(context);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Forgot Password',
          style: TextStyle(color: Color(0xFF073E39), fontWeight: FontWeight.w700),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A7A6E), Color(0xFF11A090), Color(0xFFF2FFFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      AuthField(
                        hintText: 'Registered Email',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      if (_otpSent) OtpBoxes(controller: _otpController),
                      if (_otpSent) const SizedBox(height: 14),
                      if (_otpSent)
                        AuthField(
                          hintText: 'New Password',
                          icon: Icons.lock_outline_rounded,
                          controller: _passwordController,
                          isPassword: true,
                        ),
                      if (_otpSent) const SizedBox(height: 14),
                      if (_otpSent)
                        AuthField(
                          hintText: 'Confirm Password',
                          icon: Icons.lock_outline_rounded,
                          controller: _confirmController,
                          isPassword: true,
                        ),
                      if (_otpSent) const SizedBox(height: 10),
                      if (_otpSent)
                        TextButton(
                          onPressed: _resendIn > 0 || _loading ? null : _sendOtp,
                          child: Text(
                            _resendIn > 0
                                ? 'Resend OTP in ${_resendIn}s'
                                : 'Resend OTP',
                          ),
                        ),
                      AuthGradientButton(
                        text:
                            _otpSent
                                ? (_loading
                                    ? 'Updating Password...'
                                    : 'Reset Password')
                                : (_loading ? 'Sending OTP...' : 'Send OTP'),
                        onTap: _loading ? () {} : (_otpSent ? _resetPassword : _sendOtp),
                        isLoading: _loading,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
