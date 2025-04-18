import 'package:flutter/material.dart';
import '../animations/animation_manager.dart';

class LanguageSelector extends StatelessWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final VoidCallback onSwitchLanguages;
  final AnimationController? switchAnimationController;

  const LanguageSelector({
    Key? key,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.onSwitchLanguages,
    this.switchAnimationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLanguageBox(context, sourceLanguage, isSource: true),
          
          // Animierter Sprachtausch-Button
          _buildSwitchButton(context),
          
          _buildLanguageBox(context, targetLanguage, isSource: false),
        ],
      ),
    );
  }

  Widget _buildLanguageBox(BuildContext context, String language, {required bool isSource}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isSource 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          language,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isSource 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchButton(BuildContext context) {
    // Verwende die Rotationsanimation wenn ein Controller vorhanden ist
    if (switchAnimationController != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: AnimationManager.languageSwapAnimation(
          controller: switchAnimationController!,
          child: _buildIconButton(context),
        ),
      );
    }
    
    // Fallback ohne Animation
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: _buildIconButton(context),
    );
  }
  
  Widget _buildIconButton(BuildContext context) {
    return IconButton(
      onPressed: onSwitchLanguages,
      icon: Icon(
        Icons.swap_horiz_rounded,
        color: Theme.of(context).colorScheme.primary,
        size: 28,
      ),
      tooltip: 'Sprachen tauschen',
      splashRadius: 24,
    );
  }
} 