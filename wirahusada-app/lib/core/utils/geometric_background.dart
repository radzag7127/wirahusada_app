import 'package:flutter/material.dart';

class GeometricBackground extends StatelessWidget {
  final double opacity;
  final Alignment alignment;
  final double scale;

  const GeometricBackground({
    super.key,
    this.opacity = 0.1,
    this.alignment = Alignment.bottomRight,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: GeometricBackgroundPainter(opacity: opacity, scale: scale),
        size: Size.infinite,
      ),
    );
  }
}

class GeometricBackgroundPainter extends CustomPainter {
  final double opacity;
  final double scale;

  GeometricBackgroundPainter({required this.opacity, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF207BB5).withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = const Color(0xFF135EA2).withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final baseWidth = 150.0 * scale;
    final baseHeight = 120.0 * scale;

    final startX = size.width - baseWidth * 2;
    final startY = size.height * 0.15;

    _drawTriangleLayer(
      canvas,
      paint1,
      startX,
      startY,
      baseWidth,
      baseHeight,
      0,
    );
    _drawTriangleLayer(
      canvas,
      paint2,
      startX + baseWidth * 0.3,
      startY + baseHeight * 0.5,
      baseWidth,
      baseHeight,
      1,
    );
    _drawTriangleLayer(
      canvas,
      paint1,
      startX + baseWidth * 0.6,
      startY + baseHeight * 1.0,
      baseWidth,
      baseHeight,
      2,
    );
    _drawTriangleLayer(
      canvas,
      paint2,
      startX + baseWidth * 0.9,
      startY + baseHeight * 1.5,
      baseWidth,
      baseHeight,
      3,
    );
    _drawTriangleLayer(
      canvas,
      paint1,
      startX + baseWidth * 1.2,
      startY + baseHeight * 2.0,
      baseWidth,
      baseHeight,
      4,
    );
  }

  void _drawTriangleLayer(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double width,
    double height,
    int layer,
  ) {
    final triangles = [
      [
        Offset(x, y),
        Offset(x + width * 0.8, y + height * 0.5),
        Offset(x, y + height),
      ],
      [
        Offset(x + width * 0.2, y - height * 0.3),
        Offset(x + width * 0.9, y - height * 0.1),
        Offset(x + width * 0.6, y + height * 0.4),
      ],
      [
        Offset(x - width * 0.1, y + height * 0.8),
        Offset(x + width * 0.6, y + height * 0.6),
        Offset(x + width * 0.3, y + height * 1.3),
      ],
    ];

    for (final triangle in triangles) {
      final path = Path();
      path.moveTo(triangle[0].dx, triangle[0].dy);
      path.lineTo(triangle[1].dx, triangle[1].dy);
      path.lineTo(triangle[2].dx, triangle[2].dy);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
