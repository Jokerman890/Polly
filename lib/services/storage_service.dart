import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation_result.dart';

class StorageService {
  static const String _translationsKey = 'saved_translations';
  static const String _glossaryKey = 'saved_glossary';
  static const int _maxStoredTranslations = 100;

  // Übersetzung lokal speichern
  Future<bool> saveTranslation(TranslationResult translation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedTranslations = prefs.getStringList(_translationsKey) ?? [];
      
      // Konvertiere TranslationResult zu JSON-String
      final translationJson = jsonEncode(translation.toJson());
      
      // Maximale Anzahl gespeicherter Übersetzungen prüfen
      if (savedTranslations.length >= _maxStoredTranslations) {
        savedTranslations.removeAt(0);  // Entferne älteste Übersetzung
      }
      
      savedTranslations.add(translationJson);
      return await prefs.setStringList(_translationsKey, savedTranslations);
    } catch (e) {
      print('Fehler beim Speichern der Übersetzung: $e');
      return false;
    }
  }

  // Alle gespeicherten Übersetzungen abrufen
  Future<List<TranslationResult>> getAllTranslations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedTranslations = prefs.getStringList(_translationsKey) ?? [];
      
      return savedTranslations.map((jsonStr) {
        final Map<String, dynamic> json = jsonDecode(jsonStr);
        return TranslationResult.fromJson(json);
      }).toList();
    } catch (e) {
      print('Fehler beim Abrufen der Übersetzungen: $e');
      return [];
    }
  }

  // Nach Text suchen in gespeicherten Übersetzungen
  Future<List<TranslationResult>> searchTranslations(String query) async {
    final allTranslations = await getAllTranslations();
    query = query.toLowerCase();
    
    return allTranslations.where((translation) {
      return translation.originalText.toLowerCase().contains(query) || 
             translation.translatedText.toLowerCase().contains(query);
    }).toList();
  }

  // Übersetzungen für bestimmte Sprachen filtern
  Future<List<TranslationResult>> filterTranslationsByLanguages({
    String? sourceLanguage,
    String? targetLanguage,
  }) async {
    final allTranslations = await getAllTranslations();
    
    return allTranslations.where((translation) {
      bool matchesSource = sourceLanguage == null || 
                           translation.sourceLanguage == sourceLanguage;
      bool matchesTarget = targetLanguage == null || 
                           translation.targetLanguage == targetLanguage;
      
      return matchesSource && matchesTarget;
    }).toList();
  }

  // Bestimmte Übersetzung löschen
  Future<bool> deleteTranslation(TranslationResult translation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedTranslations = prefs.getStringList(_translationsKey) ?? [];
      
      // Suche nach Übersetzung mit gleichem Inhalt und Zeitstempel
      final updatedTranslations = savedTranslations.where((jsonStr) {
        final Map<String, dynamic> json = jsonDecode(jsonStr);
        final savedTranslation = TranslationResult.fromJson(json);
        
        return !(savedTranslation.originalText == translation.originalText &&
                savedTranslation.translatedText == translation.translatedText &&
                savedTranslation.timestamp.toString() == translation.timestamp.toString());
      }).toList();
      
      if (updatedTranslations.length < savedTranslations.length) {
        return await prefs.setStringList(_translationsKey, updatedTranslations);
      }
      return false;
    } catch (e) {
      print('Fehler beim Löschen der Übersetzung: $e');
      return false;
    }
  }

  // Alle Übersetzungen löschen
  Future<bool> clearAllTranslations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_translationsKey);
    } catch (e) {
      print('Fehler beim Löschen aller Übersetzungen: $e');
      return false;
    }
  }

  // Benutzerdefiniertes Glossar speichern
  Future<bool> saveGlossary(Map<String, String> glossary, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> savedGlossaries = {};
      
      final savedGlossariesStr = prefs.getString(_glossaryKey);
      if (savedGlossariesStr != null) {
        savedGlossaries = jsonDecode(savedGlossariesStr);
      }
      
      savedGlossaries[name] = glossary;
      return await prefs.setString(_glossaryKey, jsonEncode(savedGlossaries));
    } catch (e) {
      print('Fehler beim Speichern des Glossars: $e');
      return false;
    }
  }

  // Alle gespeicherten Glossare abrufen
  Future<Map<String, Map<String, String>>> getAllGlossaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGlossariesStr = prefs.getString(_glossaryKey);
      
      if (savedGlossariesStr == null) return {};
      
      final Map<String, dynamic> savedGlossaries = jsonDecode(savedGlossariesStr);
      Map<String, Map<String, String>> result = {};
      
      savedGlossaries.forEach((name, terms) {
        result[name] = Map<String, String>.from(terms);
      });
      
      return result;
    } catch (e) {
      print('Fehler beim Abrufen der Glossare: $e');
      return {};
    }
  }

  // Bestimmtes Glossar löschen
  Future<bool> deleteGlossary(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGlossariesStr = prefs.getString(_glossaryKey);
      
      if (savedGlossariesStr == null) return false;
      
      final Map<String, dynamic> savedGlossaries = jsonDecode(savedGlossariesStr);
      if (savedGlossaries.containsKey(name)) {
        savedGlossaries.remove(name);
        return await prefs.setString(_glossaryKey, jsonEncode(savedGlossaries));
      }
      
      return false;
    } catch (e) {
      print('Fehler beim Löschen des Glossars: $e');
      return false;
    }
  }
} 