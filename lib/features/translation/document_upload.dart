import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../models/translation_result.dart';

final documentProcessingProvider = StateProvider<bool>((ref) => false);
final documentNameProvider = StateProvider<String?>((ref) => null);

class DocumentUpload extends ConsumerStatefulWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final Map<String, String>? glossary;
  final Function(TranslationResult) onTranslationComplete;

  const DocumentUpload({
    Key? key,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.glossary,
    required this.onTranslationComplete,
  }) : super(key: key);

  @override
  ConsumerState<DocumentUpload> createState() => _DocumentUploadState();
}

class _DocumentUploadState extends ConsumerState<DocumentUpload> {
  final ApiService _apiService = ApiService();
  File? _documentFile;

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _documentFile = File(result.files.single.path!);
        });

        ref.read(documentNameProvider.notifier).state = result.files.single.name;
        
        // Automatisch mit der Verarbeitung beginnen
        _processDocument();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Auswählen des Dokuments: $e')),
      );
    }
  }

  Future<void> _processDocument() async {
    if (_documentFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bitte wählen Sie zuerst ein Dokument aus')),
      );
      return;
    }

    ref.read(documentProcessingProvider.notifier).state = true;

    try {
      // Dateiendung prüfen
      final fileExtension = _documentFile!.path.split('.').last.toLowerCase();
      if (fileExtension != 'pdf' && fileExtension != 'docx') {
        throw Exception('Nicht unterstütztes Dokumentformat: $fileExtension');
      }

      // Dokument zur Übersetzung hochladen
      final translationResult = await _apiService.translateDocument(
        document: _documentFile!,
        sourceLanguage: widget.sourceLanguage,
        targetLanguage: widget.targetLanguage,
        glossary: widget.glossary,
      );

      widget.onTranslationComplete(translationResult);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei der Dokumentenverarbeitung: $e')),
      );
    } finally {
      ref.read(documentProcessingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(documentProcessingProvider);
    final documentName = ref.watch(documentNameProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dokumentauswahl und Upload-Bereich
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                _documentFile != null ? Icons.description : Icons.cloud_upload,
                size: 48,
                color: Colors.blue,
              ),
              SizedBox(height: 16),
              Text(
                _documentFile != null
                    ? 'Dokument ausgewählt: $documentName'
                    : 'PDF oder DOCX-Dokument hochladen',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              
              // Lade-Anzeige oder Buttons
              if (isProcessing)
                Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Dokument wird verarbeitet...'),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickDocument,
                      icon: Icon(Icons.file_open),
                      label: Text(_documentFile == null ? 'Dokument auswählen' : 'Anderes Dokument'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    
                    if (_documentFile != null) ...[
                      SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _processDocument,
                        icon: Icon(Icons.translate),
                        label: Text('Übersetzen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
        
        // Dokumentinformationen und Hinweise
        if (_documentFile != null && !isProcessing)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dokumentinformationen:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                _buildInfoRow('Dateiname:', documentName ?? 'Unbekannt'),
                _buildInfoRow('Dateigröße:', _getFileSize(_documentFile!)),
                _buildInfoRow('Format:', _documentFile!.path.split('.').last.toUpperCase()),
                SizedBox(height: 16),
                Text(
                  'Hinweis: Die Verarbeitung großer Dokumente kann einige Zeit in Anspruch nehmen.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getFileSize(File file) {
    try {
      int bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Unbekannt';
    }
  }
} 