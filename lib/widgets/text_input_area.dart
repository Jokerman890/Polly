import 'package:flutter/material.dart';
import '../animations/animation_manager.dart';

class TextInputArea extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onTextChanged;
  final AnimationController? fadeInController;

  const TextInputArea({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.onTextChanged,
    this.fadeInController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget inputField = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
      child: TextField(
        controller: controller,
        onChanged: onTextChanged,
        maxLines: 5,
        minLines: 3,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: Theme.of(context).hintColor,
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
    );

    // Wenn ein Animationscontroller vorhanden ist, wickel das Feld in eine FadeIn-Animation
    if (fadeInController != null) {
      return AnimationManager.fadeInAnimation(
        controller: fadeInController!,
        child: inputField,
      );
    }

    // Fallback ohne Animation
    return inputField;
  }
} 