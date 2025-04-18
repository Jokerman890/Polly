import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/api_service.dart';
import '../../models/translation_result.dart';

final recordingStateProvider = StateProvider<RecordingState>((ref) => RecordingState.idle);
final recordingProgressProvider = StateProvider<double>((ref) => 0.0);

enum RecordingState { idle, recording, processing }

class MicrophoneInput extends ConsumerStatefulWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final Map<String, String>? glossary;
  final Function(TranslationResult) onTranslationComplete;

  const MicrophoneInput({
    Key? key,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.glossary,
    required this.onTranslationComplete,
  }) : super(key: key);

  @override
  ConsumerState<MicrophoneInput> createState() => _MicrophoneInputState();
}

class _MicrophoneInputState extends ConsumerState<MicrophoneInput> {
  late ApiService _apiService;
  final _audioRecorder = Record();
  final _flutterSoundPlayer = FlutterSoundPlayer();
  String? _recordingPath;
  Timer? _progressTimer;
  static const _maxRecordingDuration = 60; // Maximale Aufnahmezeit in Sekunden

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await _flutterSoundPlayer.openPlayer();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  Future<void> _startRecording() async {
    await _requestPermissions();

    if (await _audioRecorder.hasPermission()) {
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/audio_recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      ref.read(recordingStateProvider.notifier).state = RecordingState.recording;
      ref.read(recordingProgressProvider.notifier).state = 0.0;

      // Konfiguriere Aufnahmequalität für Whisper
      final encoder = AudioEncoder.wav;
      final sampleRate = 16000; // Whisper erwartet 16kHz

      await _audioRecorder.start(
        path: _recordingPath!,
        encoder: encoder,
        samplingRate: sampleRate,
        bitRate: 128000,
      );

      // Timer für UI-Fortschrittsanzeige
      _progressTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
        final progress = timer.tick / 10 / _maxRecordingDuration;
        ref.read(recordingProgressProvider.notifier).state = progress > 1.0 ? 1.0 : progress;
        
        if (progress >= 1.0) {
          _stopRecording();
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    _progressTimer?.cancel();
    
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
      ref.read(recordingStateProvider.notifier).state = RecordingState.processing;
      
      if (_recordingPath != null) {
        await _processRecording();
      }
    }
  }

  Future<void> _processRecording() async {
    try {
      final recordedFile = File(_recordingPath!);
      if (!await recordedFile.exists()) {
        throw Exception('Aufnahmedatei nicht gefunden');
      }

      // Sende die Audiodatei zur Transkription und Übersetzung
      final translationResult = await _apiService.translateAudio(
        audioFile: recordedFile,
        sourceLanguage: widget.sourceLanguage,
        targetLanguage: widget.targetLanguage,
        glossary: widget.glossary,
      );

      widget.onTranslationComplete(translationResult);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei der Audioverarbeitung: $e')),
      );
    } finally {
      ref.read(recordingStateProvider.notifier).state = RecordingState.idle;
      ref.read(recordingProgressProvider.notifier).state = 0.0;
    }
  }

  Future<void> _playRecording() async {
    if (_recordingPath != null && await File(_recordingPath!).exists()) {
      await _flutterSoundPlayer.startPlayer(
        fromURI: _recordingPath,
        whenFinished: () {
          setState(() {});
        },
      );
    }
  }

  Future<void> _stopPlayback() async {
    await _flutterSoundPlayer.stopPlayer();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _flutterSoundPlayer.closePlayer();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingStateProvider);
    final recordingProgress = ref.watch(recordingProgressProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 16),
        
        // Fortschrittsanzeige
        if (recordingState == RecordingState.recording)
          LinearProgressIndicator(
            value: recordingProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        
        SizedBox(height: 16),
        
        // Aufnahmesteuerung
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aufnahmeknopf
            if (recordingState == RecordingState.idle)
              ElevatedButton.icon(
                onPressed: _startRecording,
                icon: Icon(Icons.mic, color: Colors.white),
                label: Text('Aufnahme starten'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            
            // Stopp-Knopf
            if (recordingState == RecordingState.recording)
              ElevatedButton.icon(
                onPressed: _stopRecording,
                icon: Icon(Icons.stop, color: Colors.white),
                label: Text('Aufnahme beenden'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            
            SizedBox(width: 16),
            
            // Abspielen-Knopf (wenn Aufnahme vorhanden)
            if (recordingState == RecordingState.idle && _recordingPath != null)
              IconButton(
                onPressed: _flutterSoundPlayer.isPlaying ? _stopPlayback : _playRecording,
                icon: Icon(
                  _flutterSoundPlayer.isPlaying ? Icons.stop : Icons.play_arrow,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
          ],
        ),
        
        // Verarbeitungsindikator
        if (recordingState == RecordingState.processing)
          Column(
            children: [
              SizedBox(height: 16),
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Verarbeite Sprachaufnahme...', style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        
        SizedBox(height: 16),
      ],
    );
  }
} 