import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// A scalable, resolution-independent mosque logo for the Islamic App.
class IslamicAppLogo extends StatelessWidget {
  final double size;

  const IslamicAppLogo({
    super.key,
    this.size = 220,
  }) : assert(size > 0);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Islamic App logo',
      image: true,
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: const CustomPaint(
            isComplex: true,
            willChange: false,
            painter: _IslamicLogoPainter(),
          ),
        ),
      ),
    );
  }
}

class _IslamicLogoPainter extends CustomPainter {
  const _IslamicLogoPainter();

  static const double _canvasSize = 220;
  static const Offset _center = Offset(110, 110);

  // The crescent and star paths are unit shapes. Scaling them on the canvas
  // avoids rebuilding and combining paths every time the logo is painted.
  static final Path _crescentPath = Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 1)),
    Path()
      ..addOval(
        Rect.fromCircle(
          center: const Offset(0.365, -0.157),
          radius: 0.826,
        ),
      ),
  );

  static final Path _fourPointStarPath = Path()
    ..moveTo(0, -1)
    ..quadraticBezierTo(0, 0, 1, 0)
    ..quadraticBezierTo(0, 0, 0, 1)
    ..quadraticBezierTo(0, 0, -1, 0)
    ..quadraticBezierTo(0, 0, 0, -1)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final shortestSide = math.min(size.width, size.height);
    if (shortestSide <= 0 || !shortestSide.isFinite) return;

    final scale = shortestSide / _canvasSize;
    final offset = Offset(
      (size.width - shortestSide) / 2,
      (size.height - shortestSide) / 2,
    );

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    canvas.save();
    canvas.clipPath(
      Path()..addOval(
        const Rect.fromCircle(center: _center, radius: 110),
      ),
    );

    _drawBackground(canvas);
    _drawMinaret(canvas);
    _drawDomeAndArch(canvas);

    _drawCrescent(
      canvas,
      center: const Offset(123.2, 59.4),
      radius: 25.3,
      angle: -0.35,
    );
    _drawCrescent(
      canvas,
      center: const Offset(123.2, 82.5),
      radius: 4.84,
      angle: -0.25,
    );
    _drawCrescent(
      canvas,
      center: const Offset(77, 42.9),
      radius: 4.4,
      angle: -0.25,
    );

    _drawFourPointStar(canvas, const Offset(143, 62.7), 5.28);
    _drawFourPointStar(canvas, const Offset(158.4, 84.7), 7.04);
    _drawFourPointStar(canvas, const Offset(96.8, 78.1), 3.96);
    _drawDecorativeDots(canvas);

    canvas.restore();
    canvas.restore();
  }

  void _drawBackground(Canvas canvas) {
    final circleRect = Rect.fromCircle(center: _center, radius: 110);

    final backgroundPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.15, -0.2),
        radius: 0.9,
        colors: [
          Color(0xFF133B4E),
          Color(0xFF0A2233),
          Color(0xFF061421),
        ],
      ).createShader(circleRect);

    canvas.drawCircle(_center, 110, backgroundPaint);

    final glowCenter = const Offset(123.2, 121);
    final glowRadius = 60.5;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD89B).withValues(alpha: 0.32),
          const Color(0xFF28969C).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: glowCenter, radius: glowRadius),
      );
    canvas.drawCircle(glowCenter, glowRadius, glowPaint);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE8C58F),
          Color(0xFF4A9A9E),
          Color(0xFF173F50),
          Color(0xFFD5AD79),
        ],
      ).createShader(circleRect);
    canvas.drawCircle(_center, 106.8, rimPaint);

    final innerRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65
      ..color = const Color(0xFFFFE5B4).withValues(alpha: 0.22);
    canvas.drawCircle(_center, 103.8, innerRimPaint);
  }

  void _drawMinaret(Canvas canvas) {
    const bounds = Rect.fromLTWH(57.2, 46.2, 39.6, 143);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.76
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF3D299),
          Color(0xFF47B5B8),
          Color(0xFF1F6E7A),
        ],
      ).createShader(bounds);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1E7E85),
          Color(0xFF0D2F40),
        ],
      ).createShader(const Rect.fromLTWH(61.6, 46.2, 30.8, 48.4));

    final topDome = Path()
      ..moveTo(66, 68.2)
      ..quadraticBezierTo(66, 50.6, 77, 47.3)
      ..quadraticBezierTo(88, 50.6, 88, 68.2)
      ..close();
    canvas.drawPath(topDome, fillPaint);
    canvas.drawPath(topDome, strokePaint);

    canvas.drawRect(
      const Rect.fromLTWH(68.2, 68.2, 17.6, 123.2),
      strokePaint,
    );

    for (final y in [68.2, 118.8]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(62.7, y, 28.6, 4.84),
          const Radius.circular(2.2),
        ),
        strokePaint,
      );
    }

    for (final y in [79.2, 132]) {
      final arch = Path()
        ..moveTo(71.5, y + 13.2)
        ..lineTo(71.5, y + 4.4)
        ..quadraticBezierTo(77, y - 1.1, 82.5, y + 4.4)
        ..lineTo(82.5, y + 13.2);
      canvas.drawPath(arch, strokePaint);
    }
  }

  void _drawDomeAndArch(Canvas canvas) {
    const domeBounds = Rect.fromLTWH(79.2, 85.8, 88, 114.4);

    final domeFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF6D7A3),
          Color(0xFFD9A66C),
          Color(0xFF429E9F),
          Color(0xFF154354),
        ],
      ).createShader(domeBounds);

    final domeBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.76
      ..color = const Color(0xFFF5D59E);

    final mosqueBody = Path()
      ..moveTo(81.4, 193.6)
      ..lineTo(81.4, 136.4)
      ..quadraticBezierTo(81.4, 99, 123.2, 86.9)
      ..quadraticBezierTo(165, 99, 165, 136.4)
      ..lineTo(165, 193.6)
      ..close();

    canvas.drawPath(mosqueBody, domeFill);
    canvas.drawPath(mosqueBody, domeBorder);

    final mainArch = Path()
      ..moveTo(111.1, 193.6)
      ..lineTo(111.1, 156.2)
      ..quadraticBezierTo(111.1, 143, 123.2, 137.5)
      ..quadraticBezierTo(135.3, 143, 135.3, 156.2)
      ..lineTo(135.3, 193.6)
      ..close();

    final archInnerFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFE5B8),
          Color(0xFFC98E5B),
          Color(0xFF164A5A),
        ],
      ).createShader(mainArch.getBounds());

    canvas.drawPath(mainArch, archInnerFill);
    canvas.drawPath(mainArch, domeBorder);
  }

  void _drawCrescent(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double angle,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.scale(radius, radius);

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFEBC2),
          Color(0xFFE5B378),
        ],
      ).createShader(const Rect.fromLTRB(-1, -1, 1, 1));

    canvas.drawPath(_crescentPath, paint);
    canvas.restore();
  }

  void _drawFourPointStar(Canvas canvas, Offset center, double radius) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(radius, radius);
    canvas.drawPath(
      _fourPointStarPath,
      Paint()..color = const Color(0xFFFFE5B4),
    );
    canvas.restore();
  }

  void _drawDecorativeDots(Canvas canvas) {
    final dotPaint = Paint()
      ..color = const Color(0xFFFFE5B4).withValues(alpha: 0.85);

    for (final point in const [
      Offset(90.2, 46.2),
      Offset(94.6, 63.8),
      Offset(156.2, 101.2),
      Offset(149.6, 46.2),
    ]) {
      canvas.drawCircle(point, 1.1, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IslamicLogoPainter oldDelegate) => false;
}
