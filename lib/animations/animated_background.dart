import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Ein animierter Blueprint-Hintergrund, der leichte Bewegungen und Pulse zeigt
class AnimatedBlueprintBackground extends StatefulWidget {
  final Widget child;
  final double gridOpacity;
  final bool enableAnimation;

  const AnimatedBlueprintBackground({
    Key? key,
    required this.child,
    this.gridOpacity = 0.05,
    this.enableAnimation = true,
  }) : super(key: key);

  @override
  State<AnimatedBlueprintBackground> createState() => _AnimatedBlueprintBackgroundState();
}

class _AnimatedBlueprintBackgroundState extends State<AnimatedBlueprintBackground>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _moveController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    // Pulsieren des Gitters
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _opacityAnimation = Tween<double>(
      begin: widget.gridOpacity * 0.7,
      end: widget.gridOpacity * 1.2,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Leichte Bewegung des Gitters
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(5, 5),
    ).animate(
      CurvedAnimation(
        parent: _moveController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.enableAnimation) {
      _pulseController.repeat(reverse: true);
      _moveController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animierter Hintergrund
        AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _moveController]),
          builder: (context, child) {
            return CustomPaint(
              painter: BlueprintBackgroundPainter(
                baseColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.background,
                opacity: _opacityAnimation.value,
                offset: _offsetAnimation.value,
              ),
              child: Container(),
            );
          },
        ),

        // Inhalt der App
        widget.child,
      ],
    );
  }
}

/// Custom-Painter für das Blueprint-Gitter
class BlueprintBackgroundPainter extends CustomPainter {
  final Color baseColor;
  final Color backgroundColor;
  final double opacity;
  final Offset offset;
  final double majorGridSpacing;
  final double minorGridSpacing;

  BlueprintBackgroundPainter({
    required this.baseColor,
    required this.backgroundColor,
    this.opacity = 0.05,
    this.offset = Offset.zero,
    this.majorGridSpacing = 80.0,
    this.minorGridSpacing = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Hintergrund
    final Paint backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Einstellungen für das Gitter
    final gridColor = baseColor.withOpacity(opacity);
    final Paint majorGridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8;

    final Paint minorGridPaint = Paint()
      ..color = gridColor.withOpacity(0.7)
      ..strokeWidth = 0.4;

    // Zufällige Kreise für einen "Blueprint"-Look
    final Paint circlePaint = Paint()
      ..color = gridColor.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final random = math.Random(42); // Konstanter Seed für Konsistenz
    for (int i = 0; i < 15; i++) {
      final circleX = random.nextDouble() * size.width;
      final circleY = random.nextDouble() * size.height;
      final radius = 30.0 + random.nextDouble() * 100.0;
      
      canvas.drawCircle(
        Offset(circleX + offset.dx, circleY + offset.dy), 
        radius, 
        circlePaint
      );
    }

    // Zeichne horizontale Linien
    for (double y = 0; y < size.height + minorGridSpacing; y += minorGridSpacing) {
      final adjustedY = (y + offset.dy) % (size.height + minorGridSpacing);
      final bool isMajor = (y / majorGridSpacing).round() * majorGridSpacing == y;
      
      canvas.drawLine(
        Offset(0, adjustedY),
        Offset(size.width, adjustedY),
        isMajor ? majorGridPaint : minorGridPaint,
      );
    }

    // Zeichne vertikale Linien
    for (double x = 0; x < size.width + minorGridSpacing; x += minorGridSpacing) {
      final adjustedX = (x + offset.dx) % (size.width + minorGridSpacing);
      final bool isMajor = (x / majorGridSpacing).round() * majorGridSpacing == x;
      
      canvas.drawLine(
        Offset(adjustedX, 0),
        Offset(adjustedX, size.height),
        isMajor ? majorGridPaint : minorGridPaint,
      );
    }

    // Zeichne einige pulsierenden Punkte
    final accentColor = baseColor.withOpacity(opacity * 2);
    final Paint pointPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final pointX = (random.nextDouble() * size.width + offset.dx) % size.width;
      final pointY = (random.nextDouble() * size.height + offset.dy) % size.height;
      
      canvas.drawCircle(Offset(pointX, pointY), 2.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BlueprintBackgroundPainter oldDelegate) {
    return oldDelegate.opacity != opacity || 
           oldDelegate.offset != offset ||
           oldDelegate.baseColor != baseColor ||
           oldDelegate.backgroundColor != backgroundColor;
  }
} 