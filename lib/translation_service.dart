import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/translation_result.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';

/// Der Status einer Übersetzungsanfrage
enum TranslationStatus {
  idle,
  loading,
  success,
  error,
  offline,
}

/// Provider für den Übersetzungsstatus
final translationStatusProvider = StateProvider<TranslationStatus>((ref) => TranslationStatus.idle);

/// Provider für Fehlerinformationen
final translationErrorProvider = StateProvider<String?>((ref) => null);

/// Provider für die letzte Übersetzung
final lastTranslationResultProvider = StateProvider<TranslationResult?>((ref) => null);

/// Historien-Provider für Quellsprache
final recentSourceLanguagesProvider = StateProvider<List<String>>((ref) => ['de', 'en', 'ru', 'uk']);

/// Historien-Provider für Zielsprache
final recentTargetLanguagesProvider = StateProvider<List<String>>((ref) => ['en', 'de', 'ru', 'uk']);

/// Der Übersetzungsdienst, der alle Übersetzungsfunktionen verwaltet
class TranslationService {
  final ApiService _apiService;
  final StorageService _storageService;
  final Ref _ref;

  TranslationService(
    this._ref, {
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService();

  /// Methode zum Übersetzen von Text
  Future<TranslationResult?> translateText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    String? formality,
    Map<String, String>? glossary,
    bool tryOffline = false,
  }) async {
    if (text.trim().isEmpty) {
      return null;
    }

    _ref.read(translationStatusProvider.notifier).state = TranslationStatus.loading;

    try {
      // Wenn offline angefordert oder Netzwerkproblem, versuche offline
      if (tryOffline) {
        final offlineResult = await _lookupOfflineTranslation(
          text: text,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        );

        if (offlineResult != null) {
          _ref.read(translationStatusProvider.notifier).state = TranslationStatus.offline;
          _ref.read(lastTranslationResultProvider.notifier).state = offlineResult;
          return offlineResult;
        }
      }

      // Online-Übersetzung
      final result = await _apiService.translateText(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        formality: formality,
        glossary: glossary,
      );

      // Speichere das Ergebnis lokal
      await _storageService.saveTranslation(result);

      // Aktualisiere die Status-Provider
      _ref.read(translationStatusProvider.notifier).state = TranslationStatus.success;
      _ref.read(lastTranslationResultProvider.notifier).state = result;
      _updateRecentLanguages(sourceLanguage, targetLanguage);

      return result;
    } catch (e) {
      debugPrint('Übersetzungsfehler: $e');

      // Versuche offline, wenn noch nicht versucht
      if (!tryOffline) {
        final offlineResult = await _lookupOfflineTranslation(
          text: text,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        );

        if (offlineResult != null) {
          _ref.read(translationStatusProvider.notifier).state = TranslationStatus.offline;
          _ref.read(lastTranslationResultProvider.notifier).state = offlineResult;
          return offlineResult;
        }
      }

      // Wenn alles fehlschlägt, melde Fehler
      _ref.read(translationStatusProvider.notifier).state = TranslationStatus.error;
      _ref.read(translationErrorProvider.notifier).state = e.toString();
      return null;
    }
  }

  /// Suche nach einer ähnlichen Übersetzung im Offline-Speicher
  Future<TranslationResult?> _lookupOfflineTranslation({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    // Suche nach exakt gleicher Übersetzung
    final allTranslations = await _storageService.getAllTranslations();
    
    for (final translation in allTranslations) {
      if (translation.sourceLanguage == sourceLanguage &&
          translation.targetLanguage == targetLanguage &&
          translation.originalText.trim() == text.trim()) {
        return translation.copyWith(isOffline: true);
      }
    }

    // Keine passende Übersetzung gefunden
    return null;
  }

  /// Sprachen tauschen
  void swapLanguages(String sourceLanguage, String targetLanguage) {
    _updateRecentLanguages(sourceLanguage, targetLanguage);
  }

  /// Aktualisiert die kürzlich verwendeten Sprachen
  void _updateRecentLanguages(String sourceLanguage, String targetLanguage) {
    // Aktualisiere Quellsprachen-Verlauf
    final recentSourceLanguages = List<String>.from(_ref.read(recentSourceLanguagesProvider));
    if (recentSourceLanguages.contains(sourceLanguage)) {
      recentSourceLanguages.remove(sourceLanguage);
    }
    recentSourceLanguages.insert(0, sourceLanguage);
    if (recentSourceLanguages.length > 5) {
      recentSourceLanguages.removeLast();
    }
    _ref.read(recentSourceLanguagesProvider.notifier).state = recentSourceLanguages;

    // Aktualisiere Zielsprachen-Verlauf
    final recentTargetLanguages = List<String>.from(_ref.read(recentTargetLanguagesProvider));
    if (recentTargetLanguages.contains(targetLanguage)) {
      recentTargetLanguages.remove(targetLanguage);
    }
    recentTargetLanguages.insert(0, targetLanguage);
    if (recentTargetLanguages.length > 5) {
      recentTargetLanguages.removeLast();
    }
    _ref.read(recentTargetLanguagesProvider.notifier).state = recentTargetLanguages;
  }

  /// Hole gespeicherte Übersetzungen
  Future<List<TranslationResult>> getSavedTranslations() async {
    return await _storageService.getAllTranslations();
  }

  /// Suche in gespeicherten Übersetzungen
  Future<List<TranslationResult>> searchSavedTranslations(String query) async {
    return await _storageService.searchTranslations(query);
  }
}

/// Provider für den Übersetzungsdienst
final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService(ref);
}); 