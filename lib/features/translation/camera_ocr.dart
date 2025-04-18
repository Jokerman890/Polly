import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import '../../services/ocr_service.dart';
import '../../services/api_service.dart';
import '../../models/translation_result.dart';

final ocrProcessingProvider = StateProvider<bool>((ref) => false);
final extractedTextProvider = StateProvider<String?>((ref) => null);

class CameraOcr extends ConsumerStatefulWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final Map<String, String>? glossary;
  final Function(TranslationResult) onTranslationComplete;

  const CameraOcr({
    Key? key,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.glossary,
    required this.onTranslationComplete,
  }) : super(key: key);

  @override
  ConsumerState<CameraOcr> createState() => _CameraOcrState();
}

class _CameraOcrState extends ConsumerState<CameraOcr> {
  final OcrService _ocrService = OcrService();
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  File? _imageFile;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Initialisieren der Kamera: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _imageFile = File(photo.path);
      });
      _processImage(_imageFile!);
    } catch (e) {
      debugPrint('Fehler beim Aufnehmen des Bildes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kamerafehler: $e')),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        _processImage(_imageFile!);
      }
    } catch (e) {
      debugPrint('Fehler beim Auswählen des Bildes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bildauswahlfehler: $e')),
      );
    }
  }

  Future<void> _processImage(File imageFile) async {
    ref.read(ocrProcessingProvider.notifier).state = true;
    ref.read(extractedTextProvider.notifier).state = null;

    try {
      // Extrahiere Text aus dem Bild
      final extractedText = await _ocrService.extractTextFromImage(imageFile);
      
      if (extractedText.isEmpty) {
        throw Exception('Kein Text erkannt');
      }

      ref.read(extractedTextProvider.notifier).state = extractedText;

      // Übersetze den extrahierten Text
      final translationResult = await _apiService.translateOcrText(
        ocrText: extractedText,
        sourceLanguage: widget.sourceLanguage,
        targetLanguage: widget.targetLanguage,
        glossary: widget.glossary,
      );

      widget.onTranslationComplete(translationResult);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OCR-Fehler: $e')),
      );
    } finally {
      ref.read(ocrProcessingProvider.notifier).state = false;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(ocrProcessingProvider);
    final extractedText = ref.watch(extractedTextProvider);

    return Column(
      children: [
        // Kamera- oder Bildvorschau
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _imageFile != null
                ? Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                  )
                : _isCameraInitialized
                    ? CameraPreview(_cameraController!)
                    : Center(
                        child: Text(
                          'Kamera wird initialisiert...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // Steuerungsknöpfe
        if (!isProcessing)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Kamera-Button
              ElevatedButton.icon(
                onPressed: _isCameraInitialized ? _takePicture : null,
                icon: Icon(Icons.camera_alt),
                label: Text('Foto aufnehmen'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              
              // Galerie-Button
              ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: Icon(Icons.photo_library),
                label: Text('Aus Galerie'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),

        // Ladeindikator
        if (isProcessing)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Text wird erkannt und übersetzt...'),
              ],
            ),
          ),

        // Extrahierter Text
        if (extractedText != null && !isProcessing)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Erkannter Text:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: double.infinity,
                  child: Text(
                    extractedText,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
} 