import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/app_theme.dart';

class PlacementReadinessGauge extends StatefulWidget {
  final double score; // 0 to 100
  final double size;

  const PlacementReadinessGauge({
    super.key,
    required this.score,
    this.size = 200,
  });

  @override
  State<PlacementReadinessGauge> createState() => _PlacementReadinessGaugeState();
}

class _PlacementReadinessGaugeState extends State<PlacementReadinessGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(PlacementReadinessGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(begin: _animation.value, end: widget.score).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _GaugePainter(_animation.value),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;

  _GaugePainter(this.score);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.12;

    // Background Arc
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Progress Arc
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.accentWarm, AppColors.primary, AppColors.accent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressSweep = (score / 100) * sweepAngle;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      progressSweep,
      false,
      progressPaint,
    );

    // Text (Score)
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${score.toInt()}',
        style: TextStyle(
          fontSize: size.width * 0.25,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 1.2),
    );

    // Label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'READINESS',
        style: TextStyle(
          fontSize: size.width * 0.08,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      center - Offset(labelPainter.width / 2, -labelPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
