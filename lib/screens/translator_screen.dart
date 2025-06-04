import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/translation/microphone_input.dart';
import '../features/translation/camera_ocr.dart';
import '../features/translation/document_upload.dart';
import '../features/translation/glossary_control.dart';
import '../models/translation_result.dart';
import '../services/storage_service.dart';
import '../translation_service.dart';
import '../assets_manager.dart';

final sourceLanguageProvider = StateProvider<String>((ref) => 'de');
final targetLanguageProvider = StateProvider<String>((ref) => 'en');
final sourceTextProvider = StateProvider<String>((ref) => '');
final translatedTextProvider = StateProvider<String>((ref) => '');
final currentTabProvider = StateProvider<int>((ref) => 0);
final isOfflineProvider = StateProvider<bool>((ref) => false);

class TranslatorScreen extends ConsumerStatefulWidget {
  const TranslatorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends ConsumerState<TranslatorScreen> {
  final TextEditingController _sourceController = TextEditingController();
  final StorageService _storageService = StorageService();
  final FocusNode _sourceFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, String> _activeGlossary = {};
  bool _isSwapping = false;

  @override
  void initState() {
    super.initState();
    _sourceController.addListener(_updateSourceText);
  }

  void _updateSourceText() {
    ref.read(sourceTextProvider.notifier).state = _sourceController.text;
  }

  void _swapLanguages() {
    if (_isSwapping) return;
    
    setState(() {
      _isSwapping = true;
    });
    
    final sourceLanguage = ref.read(sourceLanguageProvider);
    final targetLanguage = ref.read(targetLanguageProvider);
    
    ref.read(sourceLanguageProvider.notifier).state = targetLanguage;
    ref.read(targetLanguageProvider.notifier).state = sourceLanguage;
    
    final sourceText = _sourceController.text;
    final translatedText = ref.read(translatedTextProvider);
    
    if (translatedText.isNotEmpty) {
      _sourceController.text = translatedText;
      ref.read(translatedTextProvider.notifier).state = sourceText;
    }
    
    // Benachrichtige den Übersetzungsdienst über den Tausch
    ref.read(translationServiceProvider).swapLanguages(sourceLanguage, targetLanguage);
    
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isSwapping = false;
      });
    });
  }

  void _clearText() {
    _sourceController.clear();
    ref.read(translatedTextProvider.notifier).state = '';
  }

  void _performTranslation() async {
    final sourceText = _sourceController.text.trim();
    if (sourceText.isEmpty) return;
    
    final isOffline = ref.read(isOfflineProvider);
    final sourceLanguage = ref.read(sourceLanguageProvider);
    final targetLanguage = ref.read(targetLanguageProvider);
    
    final result = await ref.read(translationServiceProvider).translateText(
      text: sourceText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      glossary: _activeGlossary,
      tryOffline: isOffline,
    );
    
    if (result != null) {
      ref.read(translatedTextProvider.notifier).state = result.translatedText;
    } else {
      final error = ref.read(translationErrorProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Übersetzungsfehler'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('In die Zwischenablage kopiert'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final ClipboardData? clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null && clipboardData.text != null) {
      _sourceController.text = clipboardData.text!;
    }
  }

  void _handleTranslationResult(TranslationResult result) {
    ref.read(translatedTextProvider.notifier).state = result.translatedText;
    _storageService.saveTranslation(result);
  }

  void _handleGlossaryChanged(Map<String, String> glossary, String? name) {
    setState(() {
      _activeGlossary = glossary;
    });
  }

  @override
  void dispose() {
    _sourceController.removeListener(_updateSourceText);
    _sourceController.dispose();
    _sourceFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);
    final sourceLanguage = ref.watch(sourceLanguageProvider);
    final targetLanguage = ref.watch(targetLanguageProvider);
    final translatedText = ref.watch(translatedTextProvider);
    final isOffline = ref.watch(isOfflineProvider);
    final translationStatus = ref.watch(translationStatusProvider);

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: AssetsManager.buildLogo(),
        actions: [
          IconButton(
            icon: Icon(
              isOffline ? Icons.wifi_off : Icons.wifi,
              color: isOffline ? Colors.orangeAccent : Colors.greenAccent,
            ),
            onPressed: () {
              ref.read(isOfflineProvider.notifier).state = !isOffline;
            },
            tooltip: isOffline ? 'Offline-Modus' : 'Online-Modus',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Verlauf anzeigen
            },
            tooltip: 'Verlauf',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Einstellungen öffnen
            },
            tooltip: 'Einstellungen',
          ),
        ],
      ),
      body: Stack(
        children: [
          (() {
            try {
              return AssetsManager.buildBlueprintBackground(context);
            } catch (e) {
              return AssetsManager.buildFallbackBlueprintBackground(context);
            }
          })(),
          SafeArea(
            child: Column(
              children: [
                // Sprachauswahl und Steuerelemente
                Card(
                  margin: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Sprachauswahl
                        Row(
                          children: [
                            // Quellsprache
                            Expanded(
                              child: _buildLanguageSelector(
                                sourceLanguage,
                                (newValue) {
                                  ref.read(sourceLanguageProvider.notifier).state = newValue!;
                                },
                              ),
                            ),
                            
                            // Sprachen tauschen
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: IconButton(
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: _isSwapping
                                      ? const CircularProgressIndicator()
                                      : const Icon(Icons.swap_horiz),
                                ),
                                onPressed: _swapLanguages,
                                tooltip: 'Sprachen tauschen',
                              ),
                            ),
                            
                            // Zielsprache
                            Expanded(
                              child: _buildLanguageSelector(
                                targetLanguage,
                                (newValue) {
                                  ref.read(targetLanguageProvider.notifier).state = newValue!;
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Glossar (kompakte Ansicht)
                        GlossaryControl(
                          onGlossaryChanged: _handleGlossaryChanged,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Hauptinhalt: Text oder andere Eingabearten
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: IndexedStack(
                        index: currentTab,
                        children: [
                          // Text-Übersetzung
                          _buildTextTranslationTab(translatedText, translationStatus),
                          
                          // Spracheingabe
                          MicrophoneInput(
                            sourceLanguage: sourceLanguage,
                            targetLanguage: targetLanguage,
                            glossary: _activeGlossary,
                            onTranslationComplete: _handleTranslationResult,
                          ),
                          
                          // Kamera-OCR
                          CameraOcr(
                            sourceLanguage: sourceLanguage,
                            targetLanguage: targetLanguage,
                            glossary: _activeGlossary,
                            onTranslationComplete: _handleTranslationResult,
                          ),
                          
                          // Dokument-Upload
                          DocumentUpload(
                            sourceLanguage: sourceLanguage,
                            targetLanguage: targetLanguage,
                            glossary: _activeGlossary,
                            onTranslationComplete: _handleTranslationResult,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        selectedIndex: currentTab,
        onDestinationSelected: (index) {
          ref.read(currentTabProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.text_fields),
            label: 'Text',
            tooltip: 'Text übersetzen',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic),
            label: 'Sprache',
            tooltip: 'Spracheingabe',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt),
            label: 'Kamera',
            tooltip: 'Kamera-OCR',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_file),
            label: 'Dokument',
            tooltip: 'Dokument hochladen',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(String value, Function(String?) onChanged) {
    final Map<String, String> languages = {
      'de': 'Deutsch 🇩🇪',
      'en': 'Englisch 🇬🇧',
      'ru': 'Russisch 🇷🇺',
      'uk': 'Ukrainisch 🇺🇦',
      'fr': 'Französisch 🇫🇷',
      'es': 'Spanisch 🇪🇸',
      'it': 'Italienisch 🇮🇹',
      'ja': 'Japanisch 🇯🇵',
      'zh': 'Chinesisch 🇨🇳',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down),
          isExpanded: true,
          elevation: 16,
          dropdownColor: Theme.of(context).colorScheme.surface,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
          onChanged: onChanged,
          items: languages.entries.map<DropdownMenuItem<String>>((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTextTranslationTab(String translatedText, TranslationStatus status) {
    return Column(
      children: [
        // Quelltext-Eingabe
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Originaltext',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearText,
                      tooltip: 'Text löschen',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    controller: _sourceController,
                    focusNode: _sourceFocusNode,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      hintText: 'Text eingeben...',
                      border: InputBorder.none,
                      fillColor: Colors.transparent,
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Symbolzeile mit Übersetzungsschaltfläche
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _sourceController.text.isNotEmpty 
                  ? () => _copyToClipboard(_sourceController.text)
                  : null,
              tooltip: 'Text kopieren',
            ),
            ElevatedButton.icon(
              onPressed: status == TranslationStatus.loading 
                  ? null 
                  : _performTranslation,
              icon: status == TranslationStatus.loading
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.translate),
              label: Text(status == TranslationStatus.loading 
                  ? 'Übersetzt...' 
                  : 'Übersetzen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.paste),
              onPressed: _pasteFromClipboard,
              tooltip: 'Text einfügen',
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Übersetzter Text
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Übersetzung',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        if (status == TranslationStatus.offline)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wifi_off,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Offline',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: translatedText.isNotEmpty 
                              ? () => _copyToClipboard(translatedText)
                              : null,
                          tooltip: 'Übersetzung kopieren',
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: translatedText.isEmpty ? null : () {
                            // Text vorlesen
                          },
                          tooltip: 'Vorlesen',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      translatedText.isEmpty ? 'Übersetzung erscheint hier...' : translatedText,
                      style: TextStyle(
                        fontSize: 16,
                        color: translatedText.isEmpty
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 