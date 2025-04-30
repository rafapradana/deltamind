import 'dart:math' as Math;
import 'package:flutter/material.dart';

/// A widget that paints a Google G logo
class GoogleLogo extends StatelessWidget {
  /// Creates a Google logo with the specified size
  const GoogleLogo({super.key, this.size = 24});

  /// The size of the logo
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Define Google colors
    const Color red = Color(0xFFEA4335);
    const Color blue = Color(0xFF4285F4);
    const Color green = Color(0xFF34A853);
    const Color yellow = Color(0xFFFBBC05);

    final Paint paint =
        Paint()
          ..style = PaintingStyle.fill
          ..strokeWidth = 1;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;

    // Create a clean circular background
    paint.color = Colors.white;
    canvas.drawCircle(Offset(centerX, centerY), radius, paint);

    // Draw the 'G' shape with Google colors
    final Path path = Path();

    // Start from the right middle
    path.moveTo(centerX + radius * 0.7, centerY);

    // Top right curve (blue)
    paint.color = blue;
    path.arcTo(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius * 0.7),
      -Math.pi / 4,
      -Math.pi / 2,
      false,
    );
    canvas.drawPath(path, paint);
    path.reset();

    // Top left curve (red)
    paint.color = red;
    path.moveTo(centerX, centerY - radius * 0.7);
    path.arcTo(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius * 0.7),
      -3 * Math.pi / 4,
      -Math.pi / 2,
      false,
    );
    canvas.drawPath(path, paint);
    path.reset();

    // Bottom left curve (yellow)
    paint.color = yellow;
    path.moveTo(centerX - radius * 0.7, centerY);
    path.arcTo(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius * 0.7),
      Math.pi / 4,
      Math.pi / 2,
      false,
    );
    canvas.drawPath(path, paint);
    path.reset();

    // Bottom right curve (green)
    paint.color = green;
    path.moveTo(centerX, centerY + radius * 0.7);
    path.arcTo(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius * 0.7),
      3 * Math.pi / 4,
      Math.pi / 2,
      false,
    );
    canvas.drawPath(path, paint);

    // Draw the inner white circle for the G
    paint.color = Colors.white;
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.4, paint);

    // Draw the C-shape opening on the right
    paint.color = Colors.white;
    canvas.drawRect(
      Rect.fromLTRB(
        centerX,
        centerY - radius * 0.3,
        centerX + radius,
        centerY + radius * 0.3,
      ),
      paint,
    );

    // Draw the small blue rectangle on the right
    paint.color = blue;
    canvas.drawRect(
      Rect.fromLTRB(
        centerX + radius * 0.4,
        centerY - radius * 0.15,
        centerX + radius * 0.7,
        centerY + radius * 0.15,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
