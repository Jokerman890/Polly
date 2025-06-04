import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../lib/translation_service.dart';
import '../lib/services/api_service.dart';
import '../lib/services/storage_service.dart';
import '../lib/models/translation_result.dart';

class FakeApiService extends ApiService {
  TranslationResult? response;
  Exception? error;

  @override
  Future<TranslationResult> translateText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    String? formality,
    Map<String, String>? glossary,
  }) async {
    if (error != null) throw error!;
    return response!;
  }
}

class FakeStorageService extends StorageService {
  TranslationResult? lastSaved;
  List<TranslationResult> offline = [];

  @override
  Future<bool> saveTranslation(TranslationResult translation) async {
    lastSaved = translation;
    return true;
  }

  @override
  Future<List<TranslationResult>> getAllTranslations() async {
    return offline;
  }
}

void main() {
  group('TranslationService', () {
    test('returns online translation', () async {
      final api = FakeApiService();
      final storage = FakeStorageService();
      final container = ProviderContainer(overrides: [
        translationServiceProvider.overrideWith(
          (ref) => TranslationService(ref, apiService: api, storageService: storage),
        ),
      ]);
      final service = container.read(translationServiceProvider);

      final result = TranslationResult(
        originalText: 'hello',
        translatedText: 'hallo',
        sourceLanguage: 'en',
        targetLanguage: 'de',
        timestamp: DateTime.now(),
      );
      api.response = result;

      final translation = await service.translateText(
        text: 'hello',
        sourceLanguage: 'en',
        targetLanguage: 'de',
      );

      expect(translation, result);
      expect(storage.lastSaved, result);
      expect(container.read(translationStatusProvider), TranslationStatus.success);
    });

    test('falls back to offline translation when requested', () async {
      final api = FakeApiService();
      final storage = FakeStorageService();
      final container = ProviderContainer(overrides: [
        translationServiceProvider.overrideWith(
          (ref) => TranslationService(ref, apiService: api, storageService: storage),
        ),
      ]);
      final service = container.read(translationServiceProvider);

      final offline = TranslationResult(
        originalText: 'hello',
        translatedText: 'hallo',
        sourceLanguage: 'en',
        targetLanguage: 'de',
        timestamp: DateTime.now(),
      );
      storage.offline = [offline];

      final translation = await service.translateText(
        text: 'hello',
        sourceLanguage: 'en',
        targetLanguage: 'de',
        tryOffline: true,
      );

      expect(translation?.translatedText, offline.translatedText);
      expect(translation?.isOffline, true);
      expect(container.read(translationStatusProvider), TranslationStatus.offline);
    });
  });
}
