import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/translation_result.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000'; // Ändern für Produktionsumgebung
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // Text übersetzen über GPT
  Future<TranslationResult> translateText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    String? formality,
    Map<String, String>? glossary,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'source_language': sourceLanguage,
          'target_language': targetLanguage,
          'formality': formality,
          'glossary': glossary,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return TranslationResult(
          originalText: text,
          translatedText: data['translated_text'],
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
          timestamp: DateTime.now(),
          glossaryTerms: glossary,
        );
      } else {
        throw Exception('Fehler bei der Übersetzung: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Netzwerkfehler: $e');
    }
  }

  // Audio über Whisper transkribieren und übersetzen
  Future<TranslationResult> translateAudio({
    required File audioFile,
    required String sourceLanguage,
    required String targetLanguage,
    Map<String, String>? glossary,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/speech'));
      
      request.fields['source_language'] = sourceLanguage;
      request.fields['target_language'] = targetLanguage;
      if (glossary != null) {
        request.fields['glossary'] = jsonEncode(glossary);
      }

      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
        contentType: MediaType('audio', 'wav'),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return TranslationResult(
          originalText: data['transcribed_text'],
          translatedText: data['translated_text'],
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
          timestamp: DateTime.now(),
          audioPath: audioFile.path,
          glossaryTerms: glossary,
        );
      } else {
        throw Exception('Fehler bei der Audioverarbeitung: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Audioverarbeitungsfehler: $e');
    }
  }

  // OCR-Ergebnisse übersetzen
  Future<TranslationResult> translateOcrText({
    required String ocrText,
    required String sourceLanguage,
    required String targetLanguage,
    Map<String, String>? glossary,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/ocr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': ocrText,
          'source_language': sourceLanguage,
          'target_language': targetLanguage,
          'glossary': glossary,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return TranslationResult(
          originalText: ocrText,
          translatedText: data['translated_text'],
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
          timestamp: DateTime.now(),
          glossaryTerms: glossary,
        );
      } else {
        throw Exception('Fehler bei der OCR-Übersetzung: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('OCR-Übersetzungsfehler: $e');
    }
  }

  // Dokumente übersetzen (PDF, DOCX)
  Future<TranslationResult> translateDocument({
    required File document,
    required String sourceLanguage,
    required String targetLanguage,
    Map<String, String>? glossary,
  }) async {
    try {
      String fileExtension = document.path.split('.').last.toLowerCase();
      if (fileExtension != 'pdf' && fileExtension != 'docx') {
        throw Exception('Nicht unterstütztes Dokumentformat: $fileExtension');
      }

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/document'));
      
      request.fields['source_language'] = sourceLanguage;
      request.fields['target_language'] = targetLanguage;
      if (glossary != null) {
        request.fields['glossary'] = jsonEncode(glossary);
      }

      request.files.add(await http.MultipartFile.fromPath(
        'document',
        document.path,
        contentType: MediaType(
          'application',
          fileExtension == 'pdf' ? 'pdf' : 'vnd.openxmlformats-officedocument.wordprocessingml.document',
        ),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return TranslationResult(
          originalText: data['document_name'] ?? document.path.split('/').last,
          translatedText: data['translated_text'],
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
          timestamp: DateTime.now(),
          glossaryTerms: glossary,
        );
      } else {
        throw Exception('Fehler bei der Dokumentenübersetzung: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Dokumentenübersetzungsfehler: $e');
    }
  }
} 