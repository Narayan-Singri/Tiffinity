import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/views/auth/welcome_page.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  // Verification States
  late VerificationModel _phoneState;
  late VerificationModel _emailState;

  // Animation for Background
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    // Initialize empty states
    _phoneState = VerificationModel(type: 'Phone');
    _emailState = VerificationModel(type: 'Email');

    _loadUserData();

    // Setup Liquid Animation
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _phoneState.dispose();
    _emailState.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.currentUser;
      setState(() {
        _userData = user;

        // Populate Data
        _phoneState.value = user?['phone']?.toString() ?? '';
        _emailState.value = user?['email']?.toString() ?? '';

        // Assume verified if data exists (or you can fetch real status from DB)
        // For this UI demo, we start as unverified to show the Verify button
        _phoneState.isVerified = false;
        _emailState.isVerified = false;

        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ───────────── LOGIC (Frontend Only) ─────────────

  void _startVerification(VerificationModel model) {
    if (model.value.isEmpty) return;
    setState(() {
      model.status = VerificationStatus.otpSent;
      model.startTimer(() => setState(() {})); // Update UI on tick
    });
  }

  void _verifyOtp(VerificationModel model, String otp) {
    if (otp.length == 6) {
      // Simulate API verification delay
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          model.status = VerificationStatus.verified;
          model.isVerified = true;
          model.timer?.cancel();
        });
        HapticFeedback.lightImpact();
      });
    }
  }

  Future<void> _handleLogout() async {
    HapticFeedback.mediumImpact();
    await AuthService().logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomePage()),
            (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7F8),
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8), // Premium Off-White
      body: Stack(
        children: [
          // 1. Animated Liquid Background
          _buildLiquidBackground(),

          // 2. Glass Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileHeader(),
                  const SizedBox(height: 30),

                  // Contact & Verification Section
                  _buildSectionTitle("Contact Details"),
                  _glassContainer(
                    child: Column(
                      children: [
                        _buildVerificationRow(
                          icon: Icons.email_outlined,
                          label: "Email Address",
                          model: _emailState,
                        ),
                        _buildDivider(),
                        _buildVerificationRow(
                          icon: Icons.phone_iphone_rounded,
                          label: "Phone Number",
                          model: _phoneState,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Menu Section
                  _buildSectionTitle("My Account"),
                  _glassContainer(
                    child: Column(
                      children: [
                        _menuItem(Icons.calendar_month_rounded, 'My Subscriptions'),
                        _menuItem(Icons.shopping_bag_outlined, 'My Orders'),
                        _menuItem(Icons.location_on_outlined, 'My Addresses'),
                        _menuItem(Icons.account_balance_wallet_outlined, 'Wallet Balance'),
                        _menuItem(Icons.favorite_border_rounded, 'Favourites'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Support Section
                  _buildSectionTitle("Support & More"),
                  _glassContainer(
                    child: Column(
                      children: [
                        _menuItem(Icons.group_outlined, 'Invite Friends'),
                        _menuItem(Icons.language, 'App Language'),
                        _menuItem(Icons.support_agent_rounded, 'Help & Support'),
                        _menuItem(Icons.quiz_outlined, "FAQ's"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  _buildLogoutButton(),
                  const SizedBox(height: 40),

                  Text(
                    "v1.0.1",
                    style: TextStyle(color: Colors.teal.withOpacity(0.3), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── UI COMPONENTS ─────────────

  Widget _buildLiquidBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Stack(
          children: [
            // Top Right Blob
            Positioned(
              top: -100 + (30 * _backgroundController.value),
              right: -100,
              child: _blob(400, Colors.teal.withOpacity(0.1)),
            ),
            // Bottom Left Blob
            Positioned(
              bottom: 100 - (50 * _backgroundController.value),
              left: -100,
              child: _blob(350, Colors.tealAccent.withOpacity(0.05)),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 60, spreadRadius: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final String name = _userData?['name']?.toString() ?? 'User';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.teal.withOpacity(0.1), Colors.teal.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D3142),
            letterSpacing: 0.5,
          ),
        ),
        // Pill and SizedBox removed here
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade400,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _glassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildVerificationRow({
    required IconData icon,
    required String label,
    required VerificationModel model,
  }) {
    bool isVerifying = model.status == VerificationStatus.otpSent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.teal, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      model.value.isEmpty ? "Not set" : model.value,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                    ),
                  ],
                ),
              ),

              // Verify Button Logic
              if (model.isVerified)
                const Icon(Icons.check_circle, color: Colors.teal, size: 20)
              else
                InkWell(
                  onTap: () => _startVerification(model),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isVerifying ? Colors.grey.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isVerifying ? Colors.transparent : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      isVerifying ? "Sent" : "Verify",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isVerifying ? Colors.grey : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Expandable OTP Section
          if (isVerifying) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.withOpacity(0.2)),
                    ),
                    child: TextField(
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(letterSpacing: 8, fontWeight: FontWeight.bold, color: Colors.teal),
                      decoration: const InputDecoration(
                        counterText: "",
                        border: InputBorder.none,
                        hintText: "••••••",
                        contentPadding: EdgeInsets.only(bottom: 2),
                      ),
                      onChanged: (val) => _verifyOtp(model, val),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (model.resendCooldown > 0)
                  Text(
                    "${model.resendCooldown}s",
                    style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                  )
                else
                  TextButton(
                    onPressed: () => _startVerification(model),
                    child: const Text("Resend", style: TextStyle(color: Colors.teal, fontSize: 12)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.withOpacity(0.1), indent: 60, endIndent: 20);
  }

  Widget _menuItem(IconData icon, String title) {
    return InkWell(
      onTap: () {}, // Add navigation here
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2D3142)),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: _handleLogout,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.red.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5)
            ),
          ],
          border: Border.all(color: Colors.red.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Centers the content
          children: const [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            SizedBox(width: 10), // Spacing between icon and text
            Text(
              "Logout",
              style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────── MODELS ─────────────

enum VerificationStatus { notVerified, otpSent, verified }

class VerificationModel {
  String type;
  String value;
  VerificationStatus status;
  bool isVerified;
  Timer? timer;
  int resendCooldown;

  VerificationModel({
    required this.type,
    this.value = '',
    this.status = VerificationStatus.notVerified,
    this.isVerified = false,
    this.resendCooldown = 30,
  });

  void startTimer(VoidCallback onTick) {
    resendCooldown = 30;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendCooldown == 0) {
        t.cancel();
      } else {
        resendCooldown--;
        onTick();
      }
    });
  }

  void dispose() {
    timer?.cancel();
  }
}