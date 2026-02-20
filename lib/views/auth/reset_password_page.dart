import 'dart:async';

import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/widgets/auth_field.dart';
import 'package:Tiffinity/views/widgets/auth_gradient_button.dart';
import 'package:Tiffinity/views/widgets/otp_boxes.dart';
import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _loading = false;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
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
    setState(() => _loading = true);
    try {
      await _authService.requestForgotPasswordOtp(email: widget.email);
      _startResendTimer();
      _showMessage('Reset OTP sent to ${widget.email}');
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updatePassword() async {
    final otp = _otpController.text.trim();
    final password = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (otp.length != 6) {
      _showMessage('Enter valid 6-digit OTP');
      return;
    }
    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      _showMessage('Passwords do not match');
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.resetPasswordWithOtp(
        email: widget.email,
        otp: otp,
        newPassword: password,
      );
      if (!mounted) return;
      _showMessage('Password updated successfully');
      Navigator.pop(context);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAFFFE), Color(0xFFE8FBF7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDAF1EC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Security Verification',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0C4C43),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'OTP will be sent to ${widget.email}',
                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 16),
                    OtpBoxes(controller: _otpController),
                    const SizedBox(height: 14),
                    AuthField(
                      hintText: 'New Password',
                      icon: Icons.lock_outline_rounded,
                      controller: _newPasswordController,
                      isPassword: true,
                    ),
                    const SizedBox(height: 14),
                    AuthField(
                      hintText: 'Confirm Password',
                      icon: Icons.lock_outline_rounded,
                      controller: _confirmPasswordController,
                      isPassword: true,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _resendIn > 0 || _loading ? null : _sendOtp,
                          child: Text(
                            _resendIn > 0
                                ? 'Resend in ${_resendIn}s'
                                : 'Send OTP',
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    AuthGradientButton(
                      text:
                          _loading
                              ? 'Please wait...'
                              : 'Verify OTP & Update Password',
                      onTap: _loading ? () {} : _updatePassword,
                      isLoading: _loading,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
