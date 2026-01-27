import 'package:flutter/material.dart';

class VegNonVegLogo extends StatelessWidget {
  final dynamic type;
  final double size;

  const VegNonVegLogo({super.key, required this.type, this.size = 18});

  String _normalize(dynamic t) {
    return (t?.toString().toLowerCase().replaceAll(' ', '').replaceAll('-', '') ?? 'veg');
  }

  @override
  Widget build(BuildContext context) {
    final norm = _normalize(type);
    final bool isNonVeg = norm == 'nonveg';
    // FSSAI-style colors: green for veg/jain, brown for non-veg.
    final Color color = isNonVeg ? Colors.brown.shade700 : Colors.green.shade700;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _VegNonVegPainter(color: color, strokeWidth: size * 0.1),
      ),
    );
  }
}

class _VegNonVegPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _VegNonVegPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = 3; // slight rounding to match common glyph

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth.clamp(1.0, 2.0);

    canvas.drawRRect(rect, borderPaint);

    final double dotSize = size.shortestSide * 0.45;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, dotSize / 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _VegNonVegPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
