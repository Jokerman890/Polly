import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class OcrService {
  final TextRecognizer _textRecognizer;
  
  OcrService() : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      String extractedText = recognizedText.text;
      
      if (extractedText.isEmpty) {
        return '';
      }
      
      return extractedText;
    } catch (e) {
      debugPrint('Fehler bei der OCR-Textextraktion: $e');
      throw Exception('OCR-Fehler: $e');
    }
  }

  Future<Map<String, dynamic>> extractTextWithBlocks(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      final List<Map<String, dynamic>> textBlocks = [];
      
      for (TextBlock block in recognizedText.blocks) {
        final Map<String, dynamic> blockData = {
          'text': block.text,
          'rect': {
            'left': block.boundingBox.left,
            'top': block.boundingBox.top,
            'right': block.boundingBox.right,
            'bottom': block.boundingBox.bottom,
          },
          'lines': <Map<String, dynamic>>[],
        };
        
        for (TextLine line in block.lines) {
          final Map<String, dynamic> lineData = {
            'text': line.text,
            'rect': {
              'left': line.boundingBox.left,
              'top': line.boundingBox.top,
              'right': line.boundingBox.right,
              'bottom': line.boundingBox.bottom,
            },
          };
          
          blockData['lines'].add(lineData);
        }
        
        textBlocks.add(blockData);
      }
      
      return {
        'fullText': recognizedText.text,
        'blocks': textBlocks,
      };
    } catch (e) {
      debugPrint('Fehler bei der detaillierten OCR-Textextraktion: $e');
      throw Exception('Detaillierter OCR-Fehler: $e');
    }
  }

  // Extraktion für eine bestimmte Sprache
  Future<String> extractTextFromImageWithLanguage(File imageFile, String languageHint) async {
    // ML Kit unterstützt keine direkte Sprachauswahl, daher Fallback auf Standardextraktion
    // In einer erweiterten Version könnte ein sprachspezifischer OCR-Service verwendet werden
    return extractTextFromImage(imageFile);
  }

  // Aufräumen der Ressourcen
  void dispose() {
    _textRecognizer.close();
  }
} 