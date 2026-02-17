import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:Tiffinity/views/auth/both_login_page.dart';
import 'package:Tiffinity/views/pages/customer_pages/customer_widget_tree.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF00796B);
    const bg1 = Color(0xFF0F9FA3);
    const bg2 = Color(0xFF025C6A);

    return Scaffold(
      body: Stack(
        children: [
          // Soft gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [bg1, bg2],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Floating decorative circles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                return CustomPaint(
                  painter: _FloatingDotsPainter(t),
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Tiffinity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Healthy tiffins, every single day.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),

                  // Center plate illustration (simple circle)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final scale = 1 + math.sin(_controller.value * 2 * math.pi) * 0.02;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.6),
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                color: Colors.white.withOpacity(0.85),
                              ),
                              child: Icon(
                                Icons.fastfood_rounded,
                                color: primaryTeal,
                                size: 38,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 26),
                  const Text(
                    'Who are you?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose how you want to use Tiffinity.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Bottom sheet with role cards
                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AnimatedRoleTile(
                          delay: 0.1,
                          icon: Icons.restaurant_menu_rounded,
                          title: 'Customer',
                          description:
                          'Discover nearby messes and order your daily meals.',
                          color: primaryTeal,
                          tag: 'For eating',
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CustomerWidgetTree(),
                              ),
                                  (route) => false,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _AnimatedRoleTile(
                          delay: 0.25,
                          icon: Icons.storefront_rounded,
                          title: 'Mess Owner',
                          description:
                          'Manage subscriptions, menus and orders in one place.',
                          color: const Color(0xFFDD6B20),
                          tag: 'For selling',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                const BothLoginPage(role: 'admin'),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'You can change your role later from settings.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating dots in background
class _FloatingDotsPainter extends CustomPainter {
  final double t;
  _FloatingDotsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final dots = [
      Offset(size.width * 0.15, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.25),
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.85, size.height * 0.65),
    ];

    for (var i = 0; i < dots.length; i++) {
      final phase = t * 2 * math.pi + i;
      final dy = math.sin(phase) * 8;
      final dx = math.cos(phase) * 4;
      final center = dots[i] + Offset(dx, dy);

      paint.color = Colors.white.withOpacity(0.10 + (i * 0.03));
      canvas.drawCircle(center, 18, paint);

      paint.color = Colors.white.withOpacity(0.20 + (i * 0.05));
      canvas.drawCircle(center, 8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingDotsPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// Role tile with slide+fade animation
class _AnimatedRoleTile extends StatefulWidget {
  final double delay;
  final IconData icon;
  final String title;
  final String description;
  final String tag;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedRoleTile({
    required this.delay,
    required this.icon,
    required this.title,
    required this.description,
    required this.tag,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedRoleTile> createState() => _AnimatedRoleTileState();
}

class _AnimatedRoleTileState extends State<_AnimatedRoleTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // start after small delay
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).round()), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.color.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded,
                                  size: 14, color: widget.color),
                              const SizedBox(width: 4),
                              Text(
                                widget.tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
