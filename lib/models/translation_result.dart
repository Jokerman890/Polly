import 'dart:convert';

class TranslationResult {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime timestamp;
  final String? audioPath;
  final Map<String, String>? glossaryTerms;
  final bool isOffline;

  TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.timestamp,
    this.audioPath,
    this.glossaryTerms,
    this.isOffline = false,
  });

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      originalText: json['originalText'],
      translatedText: json['translatedText'],
      sourceLanguage: json['sourceLanguage'],
      targetLanguage: json['targetLanguage'],
      timestamp: DateTime.parse(json['timestamp']),
      audioPath: json['audioPath'],
      glossaryTerms: json['glossaryTerms'] != null
          ? Map<String, String>.from(json['glossaryTerms'])
          : null,
      isOffline: json['isOffline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'translatedText': translatedText,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'timestamp': timestamp.toIso8601String(),
      'audioPath': audioPath,
      'glossaryTerms': glossaryTerms,
      'isOffline': isOffline,
    };
  }

  TranslationResult copyWith({
    String? originalText,
    String? translatedText,
    String? sourceLanguage,
    String? targetLanguage,
    DateTime? timestamp,
    String? audioPath,
    Map<String, String>? glossaryTerms,
    bool? isOffline,
  }) {
    return TranslationResult(
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      timestamp: timestamp ?? this.timestamp,
      audioPath: audioPath ?? this.audioPath,
      glossaryTerms: glossaryTerms ?? this.glossaryTerms,
      isOffline: isOffline ?? this.isOffline,
    );
  }
} 