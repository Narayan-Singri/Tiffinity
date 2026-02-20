import 'dart:async';

import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/pages/admin_pages/admin_widget_tree.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_location_page.dart';
import 'package:Tiffinity/views/widgets/auth_field.dart';
import 'package:Tiffinity/views/widgets/auth_gradient_button.dart';
import 'package:Tiffinity/views/widgets/otp_boxes.dart';
import 'package:flutter/material.dart';

class EmailOtpLoginPage extends StatefulWidget {
  final String role;
  const EmailOtpLoginPage({super.key, required this.role});

  @override
  State<EmailOtpLoginPage> createState() => _EmailOtpLoginPageState();
}

class _EmailOtpLoginPageState extends State<EmailOtpLoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  String _otpPurpose = AuthService.otpPurposeLogin;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
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
      final purpose = await _authService.requestLoginOtp(
        email: email,
        role: widget.role,
      );
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _otpPurpose = purpose;
      });
      _startResendTimer();
      _showMessage(
        purpose == AuthService.otpPurposeVerify
            ? 'Account not verified. Verification OTP sent to $email'
            : 'Login OTP sent to $email',
      );
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showMessage('Enter a valid 6-digit OTP');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await _authService.verifyLoginOtp(
        email: email,
        otp: otp,
        role: widget.role,
        purpose: _otpPurpose,
      );
      final user = result['user'] as Map<String, dynamic>;
      if (!mounted) return;
      if (widget.role == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminWidgetTree()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerLocationPage(userId: user['uid'].toString()),
          ),
          (route) => false,
        );
      }
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF006A5E), Color(0xFF00A28E), Color(0xFFEBFFF9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      const Text(
                        'Login With OTP',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF073E39),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
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
                          hintText: 'Email Address',
                          icon: Icons.email_outlined,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        if (_otpSent) OtpBoxes(controller: _otpController),
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
                        const SizedBox(height: 6),
                        AuthGradientButton(
                          text:
                              _otpSent
                                  ? (_loading ? 'Verifying...' : 'Verify OTP')
                                  : (_loading ? 'Sending...' : 'Send OTP'),
                          onTap: _loading ? () {} : (_otpSent ? _verifyOtp : _sendOtp),
                          isLoading: _loading,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
