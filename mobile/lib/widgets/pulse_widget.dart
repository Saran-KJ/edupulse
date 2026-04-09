import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class PulseWidget extends StatefulWidget {
  final String riskLevel;
  final double size;
  final double momentum; // 0.0 to 1.0 (how fast it pulses)

  const PulseWidget({
    super.key,
    this.riskLevel = 'Low',
    this.size = 200,
    this.momentum = 0.5,
  });

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (1500 - (widget.momentum * 1000)).toInt()),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
        vsync: this, 
        duration: const Duration(seconds: 10)
    )..repeat();

    _pulseScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didUpdateWidget(PulseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.momentum != widget.momentum) {
      _pulseController.duration = Duration(milliseconds: (1500 - (widget.momentum * 1000)).toInt());
      if (_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Color _getRiskColor() {
    switch (widget.riskLevel.toUpperCase()) {
      case 'HIGH':
        return AppColors.riskHigh;
      case 'MEDIUM':
        return AppColors.riskMedium;
      case 'LOW':
      default:
        return AppColors.riskLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRiskColor();

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Aura 1 (Fast Outer Glow)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: widget.size * _pulseScale.value * 1.1,
                height: widget.size * _pulseScale.value * 1.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.15),
                      color.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Aura 2 (Atmospheric Glow)
          RotationTransition(
            turns: _rotationController,
            child: Container(
              width: widget.size * 0.9,
              height: widget.size * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          ),

          // The Core Pulse
          ScaleTransition(
            scale: _pulseScale,
            child: Container(
              width: widget.size * 0.6,
              height: widget.size * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.3),
                  colors: [
                    Colors.white,
                    color,
                    color.withValues(alpha: 0.8),
                  ],
                  stops: const [0.1, 0.7, 1.0],
                ),
              ),
              child: CustomPaint(
                painter: PulseRhythmPainter(color: Colors.white.withValues(alpha: 0.3)),
              ),
            ),
          ),

          // Center Icon
          Icon(
            _getPulseIcon(),
            color: Colors.white,
            size: widget.size * 0.25,
          ),
        ],
      ),
    );
  }

  IconData _getPulseIcon() {
    switch (widget.riskLevel.toUpperCase()) {
      case 'HIGH':
        return Icons.warning_rounded;
      case 'MEDIUM':
        return Icons.bolt_rounded;
      case 'LOW':
      default:
        return Icons.favorite_rounded;
    }
  }
}

class PulseRhythmPainter extends CustomPainter {
  final Color color;
  PulseRhythmPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final centerY = size.height / 2;
    final width = size.width;

    path.moveTo(0, centerY);
    // Simple EKG path
    path.lineTo(width * 0.3, centerY);
    path.lineTo(width * 0.35, centerY - 15);
    path.lineTo(width * 0.45, centerY + 25);
    path.lineTo(width * 0.5, centerY - 40);
    path.lineTo(width * 0.55, centerY + 10);
    path.lineTo(width * 0.6, centerY);
    path.lineTo(width, centerY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
