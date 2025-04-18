import 'package:flutter/material.dart';
import 'dart:async';

/// Verwaltet alle Animationen in der App
class AnimationManager {
  /// Standarddauer für Animationen
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 600);
  static const Duration fastDuration = Duration(milliseconds: 150);

  /// Slide-In-Animation von unten
  static Animation<Offset> slideInFromBottom(Animation<double> animation) {
    return Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));
  }

  /// Slide-In-Animation von oben
  static Animation<Offset> slideInFromTop(Animation<double> animation) {
    return Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));
  }

  /// Slide-In-Animation von links
  static Animation<Offset> slideInFromLeft(Animation<double> animation) {
    return Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));
  }

  /// Slide-In-Animation von rechts
  static Animation<Offset> slideInFromRight(Animation<double> animation) {
    return Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));
  }

  /// Fade-In-Animation
  static Animation<double> fadeIn(Animation<double> animation) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeIn,
    ));
  }

  /// Scale-Animation
  static Animation<double> scaleIn(Animation<double> animation) {
    return Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
    ));
  }

  /// Rotation-Animation
  static Animation<double> rotateIn(Animation<double> animation) {
    return Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.elasticOut,
    ));
  }

  /// Pulse-Animation für Hervorhebungen
  static Animation<double> pulse(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }
  
  /// Blueprint-Hintergrund-Animation
  static Animation<double> gridLineAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.02,
      end: 0.08,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }
  
  /// Animation für Kartenübergänge
  static Widget animatedCard({
    required Widget child, 
    required bool isVisible,
    Duration? duration,
    Curve curve = Curves.easeInOut,
  }) {
    return AnimatedSwitcher(
      duration: duration ?? defaultDuration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final scaleAnimation = scaleIn(animation);
        final fadeAnimation = fadeIn(animation);
        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      child: isVisible ? child : const SizedBox.shrink(),
    );
  }
  
  /// Sequenz-Animation für mehrere Elemente in Reihenfolge
  static List<Widget> staggeredChildren({
    required List<Widget> children,
    Duration staggerDuration = const Duration(milliseconds: 50),
    bool fromBottom = true,
  }) {
    final animatedChildren = <Widget>[];
    
    for (int i = 0; i < children.length; i++) {
      final delay = Duration(milliseconds: i * staggerDuration.inMilliseconds);
      
      animatedChildren.add(
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: defaultDuration,
          delay: delay,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: fromBottom 
                    ? Offset(0, 20 * (1 - value))
                    : Offset(20 * (1 - value), 0),
                child: child,
              ),
            );
          },
          child: children[i],
        ),
      );
    }
    
    return animatedChildren;
  }
  
  /// Spezielle Animation für den Sprachentausch
  static Widget languageSwapAnimation({
    required BuildContext context,
    required Widget leftWidget,
    required Widget rightWidget,
    required bool isSwapping,
  }) {
    return Stack(
      children: [
        AnimatedPositioned(
          duration: isSwapping ? slowDuration : defaultDuration,
          curve: Curves.elasticOut,
          left: isSwapping ? MediaQuery.of(context).size.width * 0.5 : 0,
          right: isSwapping ? 0 : MediaQuery.of(context).size.width * 0.5,
          top: 0,
          bottom: 0,
          child: AnimatedOpacity(
            duration: fastDuration,
            opacity: isSwapping ? 0.3 : 1.0,
            child: leftWidget,
          ),
        ),
        AnimatedPositioned(
          duration: isSwapping ? slowDuration : defaultDuration,
          curve: Curves.elasticOut,
          left: isSwapping ? 0 : MediaQuery.of(context).size.width * 0.5,
          right: isSwapping ? MediaQuery.of(context).size.width * 0.5 : 0,
          top: 0,
          bottom: 0,
          child: AnimatedOpacity(
            duration: fastDuration,
            opacity: isSwapping ? 0.3 : 1.0,
            child: rightWidget,
          ),
        ),
      ],
    );
  }
  
  /// Typwriter-Effekt für die Übersetzungsanzeige
  static Widget typewriterEffect({
    required String text,
    required bool animate,
    Duration? duration,
    TextStyle? style,
  }) {
    if (!animate || text.isEmpty) {
      return Text(
        text.isEmpty ? 'Übersetzung erscheint hier...' : text,
        style: style,
      );
    }
    
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: text.length),
      duration: duration ?? Duration(milliseconds: text.length * 20),
      builder: (context, value, child) {
        return Text(
          text.substring(0, value),
          style: style,
        );
      },
    );
  }
  
  /// Pulsierender Knopf-Effekt
  static Widget pulsingButton({
    required Widget child,
    required VoidCallback onPressed,
    required bool isPulsing,
    Color? color,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 1.0,
        end: isPulsing ? 1.1 : 1.0,
      ),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isPulsing ? 6 : 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: child,
      ),
    );
  }

  /// Erstellt eine Fade-In-Animation mit dem bereitgestellten Controller
  static Widget fadeInAnimation({
    required AnimationController controller,
    required Widget child,
    Curve curve = Curves.easeIn,
  }) {
    final Animation<double> fadeAnimation = CurvedAnimation(
      parent: controller,
      curve: curve,
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: child,
    );
  }

  /// Erstellt eine Slide-In-Animation von oben
  static Widget slideInFromTopAnimation({
    required AnimationController controller,
    required Widget child,
    Curve curve = Curves.easeOutQuint,
    double beginOffset = -0.2,
  }) {
    final Animation<Offset> slideAnimation = Tween<Offset>(
      begin: Offset(0, beginOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));

    return SlideTransition(
      position: slideAnimation,
      child: child,
    );
  }

  /// Erstellt eine Slide-In-Animation von unten
  static Widget slideInFromBottomAnimation({
    required AnimationController controller,
    required Widget child,
    Curve curve = Curves.easeOutQuint,
    double beginOffset = 0.2,
  }) {
    final Animation<Offset> slideAnimation = Tween<Offset>(
      begin: Offset(0, beginOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));

    return SlideTransition(
      position: slideAnimation,
      child: child,
    );
  }

  /// Erstellt eine rotierende Animation für Icons wie z.B. den Sprachumschalter
  static Widget rotateAnimation({
    required AnimationController controller,
    required Widget child,
    Curve curve = Curves.elasticOut,
    double turns = 0.5,
  }) {
    final Animation<double> rotateAnimation = Tween<double>(
      begin: 0.0,
      end: turns,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));

    return RotationTransition(
      turns: rotateAnimation,
      child: child,
    );
  }

  /// Erstellt eine Scale-Animation (Größenänderung)
  static Widget scaleAnimation({
    required AnimationController controller,
    required Widget child,
    Curve curve = Curves.easeOutBack,
    double beginScale = 0.8,
  }) {
    final Animation<double> scaleAnimation = Tween<double>(
      begin: beginScale,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));

    return ScaleTransition(
      scale: scaleAnimation,
      child: child,
    );
  }

  /// Kombiniert Fade-In mit Slide-In von unten für einen schönen Eintrittseffekt
  static Widget fadeSlideInAnimation({
    required AnimationController controller,
    required Widget child,
    Curve curve = Curves.easeOutCubic,
  }) {
    final Animation<double> fadeAnimation = CurvedAnimation(
      parent: controller,
      curve: curve,
    );

    final Animation<Offset> slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}

/// Aufzählung für verschiedene Animationstypen bei gestaffelten Animationen
enum AnimationType {
  fadeScale,
  slideFromBottom,
  slideFromSide,
}

/// Widget für den Schreibmaschineneffekt
class TypewriterAnimatedText extends StatefulWidget {
  final String text;
  final AnimationController controller;
  final TextStyle? style;
  final TextAlign textAlign;
  final Duration characterDelay;

  const TypewriterAnimatedText({
    Key? key,
    required this.text,
    required this.controller,
    this.style,
    this.textAlign = TextAlign.start,
    this.characterDelay = const Duration(milliseconds: 50),
  }) : super(key: key);

  @override
  State<TypewriterAnimatedText> createState() => _TypewriterAnimatedTextState();
}

class _TypewriterAnimatedTextState extends State<TypewriterAnimatedText> {
  String _displayText = '';
  Timer? _timer;
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addStatusListener(_animationStatusListener);
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeStatusListener(_animationStatusListener);
    super.dispose();
  }

  void _animationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      _startTypewriterEffect();
    } else if (status == AnimationStatus.reverse) {
      _resetTypewriterEffect();
    }
  }

  void _startTypewriterEffect() {
    _charIndex = 0;
    _displayText = '';
    
    _timer = Timer.periodic(widget.characterDelay, (timer) {
      if (_charIndex < widget.text.length) {
        setState(() {
          _displayText = widget.text.substring(0, _charIndex + 1);
          _charIndex++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _resetTypewriterEffect() {
    _timer?.cancel();
    setState(() {
      _displayText = '';
      _charIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
} 