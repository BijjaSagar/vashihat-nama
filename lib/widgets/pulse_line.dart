import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class PulseLine extends StatefulWidget {
  final Color color;
  const PulseLine({super.key, this.color = AppTheme.accentColor});

  @override
  _PulseLineState createState() => _PulseLineState();
}

class _PulseLineState extends State<PulseLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return RepaintBoundary(
          child: CustomPaint(
            painter: HeartbeatPainter(_controller.value, widget.color),
            size: const Size(double.infinity, 100),
          ),
        );
      },
    );
  }
}

class HeartbeatPainter extends CustomPainter {
  final double progress;
  final Color color;

  HeartbeatPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    path.moveTo(0, centerY);

    for (double x = 0; x <= width; x++) {
      double relativeX = (x / width + progress) % 1.0;
      double y = centerY;

      // Create the heartbeat "spike" at a specific interval
      if (relativeX > 0.4 && relativeX < 0.6) {
        double localProgress = (relativeX - 0.4) / 0.2; // 0 to 1
        y = centerY - math.sin(localProgress * math.pi * 4) * (centerY * 0.8) * math.exp(-math.pow(localProgress - 0.5, 2) * 20);
      }

      path.lineTo(x, y);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HeartbeatPainter oldDelegate) => true;
}
