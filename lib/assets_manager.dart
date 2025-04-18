import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

/// Verwaltet alle Assets, die in der App verwendet werden
class AssetsManager {
  static const String _blueprintGridPath = 'assets/images/blueprint_grid.png';
  static const String _logoPath = 'assets/images/logo.png';
  
  /// Blueprint-Gitter-Hintergrund zeichnen
  static Widget buildBlueprintBackground(BuildContext context, {double opacity = 0.05}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        image: DecorationImage(
          image: AssetImage(_blueprintGridPath),
          repeat: ImageRepeat.repeat,
          opacity: opacity,
        ),
      ),
    );
  }

  /// Generiere einen proceduralen Blueprint-Hintergrund, falls das Asset fehlt
  static Widget buildFallbackBlueprintBackground(BuildContext context) {
    return CustomPaint(
      painter: BlueprintGridPainter(
        gridColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      child: Container(),
    );
  }

  /// Logo anzeigen mit Fallback
  static Widget buildLogo({double height = 40}) {
    return Image.asset(
      _logoPath,
      height: height,
      errorBuilder: (context, error, stackTrace) => Text(
        'PolyglottTranslater',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Ein Profilbild für die Whisper-Spracherkennung
  static Widget buildWhisperImage({double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.mic,
        size: size * 0.6,
        color: Colors.indigo,
      ),
    );
  }

  /// Ein Profilbild für die GPT-Übersetzung
  static Widget buildGptImage({double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.translate,
        size: size * 0.6,
        color: Colors.green,
      ),
    );
  }
}

/// Malt ein Blueprint-Gitter im Hintergrund, wenn das Blueprint-Asset fehlt
class BlueprintGridPainter extends CustomPainter {
  final Color gridColor;
  final Color backgroundColor;
  final double majorGridSpacing;
  final double minorGridSpacing;
  final double majorLineWidth;
  final double minorLineWidth;

  BlueprintGridPainter({
    required this.gridColor,
    required this.backgroundColor,
    this.majorGridSpacing = 50.0,
    this.minorGridSpacing = 10.0,
    this.majorLineWidth = 0.8,
    this.minorLineWidth = 0.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final Paint majorLinePaint = Paint()
      ..color = gridColor
      ..strokeWidth = majorLineWidth;

    final Paint minorLinePaint = Paint()
      ..color = gridColor.withOpacity(0.5)
      ..strokeWidth = minorLineWidth;

    // Zeichne horizontale Linien
    for (double y = 0; y < size.height; y += minorGridSpacing) {
      final bool isMajor = (y / majorGridSpacing).round() * majorGridSpacing == y;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isMajor ? majorLinePaint : minorLinePaint,
      );
    }

    // Zeichne vertikale Linien
    for (double x = 0; x < size.width; x += minorGridSpacing) {
      final bool isMajor = (x / majorGridSpacing).round() * majorGridSpacing == x;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMajor ? majorLinePaint : minorLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 