
import 'dart:async';

import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/pages/admin_pages/admin_setup_page.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_location_page.dart';
import 'package:Tiffinity/views/widgets/auth_gradient_button.dart';
import 'package:Tiffinity/views/widgets/otp_boxes.dart';
import 'package:flutter/material.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;
  final String role;

  const EmailVerificationPage({
    super.key,
    required this.email,
    required this.role,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  late final AnimationController _controller;
  bool _loading = false;
  int _resendIn = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendIn <= 0) {
        timer.cancel();
      } else {
        if (mounted) setState(() => _resendIn--);
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showMessage('Please enter valid 6-digit OTP');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await _authService.verifyEmailOtp(
        email: widget.email,
        otp: otp,
      );
      final user = result['user'] as Map<String, dynamic>;

      if (!mounted) return;
      if (widget.role == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => AdminSetupPage(userId: user['uid'])),
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

  Future<void> _resendOtp() async {
    if (_resendIn > 0) return;
    try {
      await _authService.resendVerificationOtp(
        email: widget.email,
        role: widget.role,
      );
      _startResendTimer();
      _showMessage('OTP sent again to ${widget.email}');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00554C), Color(0xFF00796B), Color(0xFFDCF8F3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Spacer(),
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
                          children: [
                            const Icon(
                              Icons.mark_email_read_rounded,
                              color: Color(0xFF00796B),
                              size: 62,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Verify Your Email',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF12403B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enter the 6-digit OTP sent to\n${widget.email}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 18),
                            OtpBoxes(controller: _otpController),
                            const SizedBox(height: 20),
                            AuthGradientButton(
                              text: _loading ? 'Verifying...' : 'Verify & Continue',
                              onTap: _loading ? () {} : _verifyOtp,
                              isLoading: _loading,
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _resendOtp,
                              child: Text(
                                _resendIn > 0
                                    ? 'Resend OTP in ${_resendIn}s'
                                    : 'Resend OTP',
                                style: const TextStyle(
                                  color: Color(0xFF00796B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
