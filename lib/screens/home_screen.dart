import 'package:flutter/material.dart';
import '../widgets/language_selector.dart';
import '../widgets/text_input_area.dart';
import '../widgets/translation_result.dart';
import '../widgets/action_button.dart';
import '../services/translation_service.dart';
import '../animations/animation_manager.dart';
import '../animations/animated_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String sourceText = '';
  String translatedText = '';
  bool isTranslating = false;
  String sourceLanguage = 'Deutsch';
  String targetLanguage = 'Englisch';
  final TranslationService _translationService = TranslationService();
  
  // Animation Controller für die UI-Elemente
  late AnimationController _fadeInController;
  late AnimationController _languageSwitchController;
  late AnimationController _translationController;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialisiere die Animation Controller
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _languageSwitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _translationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Starte die Eingangsanimation
    _fadeInController.forward();
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _languageSwitchController.dispose();
    _translationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _switchLanguages() {
    _languageSwitchController.reset();
    _languageSwitchController.forward();
    
    setState(() {
      final temp = sourceLanguage;
      sourceLanguage = targetLanguage;
      targetLanguage = temp;
      
      // Wenn bereits Text übersetzt wurde, auch die Übersetzungen tauschen
      if (translatedText.isNotEmpty) {
        final tempText = sourceText;
        sourceText = translatedText;
        translatedText = tempText;
      }
    });
  }

  Future<void> _translateText() async {
    if (sourceText.trim().isEmpty) return;
    
    setState(() {
      isTranslating = true;
    });
    
    try {
      final result = await _translationService.translateText(
        text: sourceText,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      
      _translationController.reset();
      _translationController.forward();
      
      setState(() {
        translatedText = result;
        isTranslating = false;
      });
    } catch (e) {
      setState(() {
        translatedText = "Fehler bei der Übersetzung: $e";
        isTranslating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> uiElements = [
      // Sprachauswahl mit Animation
      AnimationManager.slideInFromBottom(
        controller: _fadeInController,
        beginOffset: 0.3,
        child: LanguageSelector(
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
          onSwitchLanguages: _switchLanguages,
          switchAnimationController: _languageSwitchController,
        ),
      ),
      
      const SizedBox(height: 20),
      
      // Texteingabefeld mit Animation
      AnimationManager.fadeScale(
        controller: _fadeInController,
        beginScale: 0.9,
        beginOpacity: 0.0,
        child: TextInputArea(
          hintText: 'Text zum Übersetzen eingeben',
          onTextChanged: (text) {
            setState(() {
              sourceText = text;
            });
          },
          text: sourceText,
        ),
      ),
      
      const SizedBox(height: 20),
      
      // Übersetzungsbutton mit Animation
      AnimationManager.fadeIn(
        controller: _fadeInController,
        begin: 0.0,
        end: 1.0,
        curve: Curves.easeIn,
        child: AnimationManager.pulsingButton(
          controller: _pulseController,
          minScale: 0.97,
          maxScale: 1.03,
          child: ActionButton(
            text: 'Übersetzen',
            isLoading: isTranslating,
            onPressed: _translateText,
          ),
        ),
      ),
      
      const SizedBox(height: 20),
      
      // Übersetzungsergebnis mit Animation
      if (translatedText.isNotEmpty)
        AnimationManager.fadeScale(
          controller: _translationController,
          beginScale: 0.95,
          beginOpacity: 0.0,
          child: TranslationResult(
            translatedText: translatedText,
            isLoading: isTranslating,
          ),
        ),
    ];

    return Scaffold(
      body: AnimatedBlueprintBackground(
        gridOpacity: 0.15,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: uiElements,
            ),
          ),
        ),
      ),
    );
  }
} 