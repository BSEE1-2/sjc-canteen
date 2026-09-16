import 'dart:math' as math;
import 'package:flutter/material.dart';

class WavyProgressIndicator extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final Color color;
  final Color backgroundColor;
  final double height;
  final EdgeInsetsGeometry? margin; // Added margin property

  const WavyProgressIndicator({
    super.key,
    required this.value,
    this.color = const Color(0xFF4b652a),
    this.backgroundColor = const Color(
      0xFFe2e8f0,
    ), // Light grey for the inactive track
    this.height = 14.0,
    this.margin = const EdgeInsets.symmetric(
      horizontal: 16.0,
    ), // Default margin
  });

  @override
  State<WavyProgressIndicator> createState() => _WavyProgressIndicatorState();
}

class _WavyProgressIndicatorState extends State<WavyProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin, // Applies the spacing outside the bar
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _WavePainter(
              progress: widget.value,
              phase: _controller.value * 2 * math.pi,
              color: widget.color,
              backgroundColor: widget.backgroundColor,
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double phase;
  final Color color;
  final Color backgroundColor;

  _WavePainter({
    required this.progress,
    required this.phase,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 3.5;
    final double trackGap = 6.0;
    final double wavelength = 25.0; // Adjusted for a tighter wave look
    final double amplitude = 2.5;
    final double centerY = size.height / 2;

    final activeWidth = size.width * progress.clamp(0.0, 1.0);

    // 1. Draw Inactive Track (The light grey flat line)
    if (progress < 1.0) {
      final inactivePaint = Paint()
        ..color = backgroundColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final double inactiveStart = (activeWidth > 0)
          ? activeWidth + trackGap
          : 0;

      if (inactiveStart < size.width) {
        canvas.drawLine(
          Offset(inactiveStart, centerY),
          Offset(size.width, centerY),
          inactivePaint,
        );
      }
    }

    // 2. Draw Active Track (The green wavy line)
    if (activeWidth > 0) {
      final activePaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();

      // Start the wave at x = 0
      path.moveTo(0, centerY + math.sin(phase) * amplitude);

      for (double x = 1; x <= activeWidth; x++) {
        final y =
            centerY +
            math.sin(x * (2 * math.pi / wavelength) + phase) * amplitude;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.progress != progress;
  }
}
