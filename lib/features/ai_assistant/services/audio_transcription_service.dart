import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../core/utils/app_logger.dart';
import '../models/ai_server_config.dart';
import '../repositories/ai_assistant_repository.dart';
import 'ai_secret_vault.dart';

/// Service transkripsi audio suara mikrofon INMP441 ESP32-S3 (PCM 16-bit Mono 8000 Hz)
/// ke teks menggunakan multi-tier fallback:
/// 1. Custom / Local Server (OpenAI-compatible `/v1/audio/transcriptions`)
/// 2. Groq Whisper Cloud (`whisper-large-v3-turbo`, latensi sangat cepat ~250ms)
/// 3. Fallback Groq Whisper (`whisper-large-v3`)
class AudioTranscriptionService {
  AudioTranscriptionService({http.Client? httpClient})
    : _client = httpClient ?? http.Client();

  final http.Client _client;

  static AudioTranscriptionService? _instance;
  static AudioTranscriptionService get instance =>
      _instance ??= AudioTranscriptionService();

  /// Konversi byte PCM 16-bit Mono (mis. 8000 Hz dari INMP441)
  /// menjadi file WAV lengkap dengan header RIFF standar 44-byte.
  Uint8List convertPcmToWav(
    Uint8List pcmBytes, {
    int sampleRate = 8000,
    int numChannels = 1,
    int bitsPerSample = 16,
  }) {
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final blockAlign = numChannels * (bitsPerSample ~/ 8);
    final subChunk2Size = pcmBytes.length;
    final chunkSize = 36 + subChunk2Size;

    final header = ByteData(44);
    // RIFF header
    header.setUint8(0, 0x52); // 'R'
    header.setUint8(1, 0x49); // 'I'
    header.setUint8(2, 0x46); // 'F'
    header.setUint8(3, 0x46); // 'F'
    header.setUint32(4, chunkSize, Endian.little);
    header.setUint8(8, 0x57); // 'W'
    header.setUint8(9, 0x41); // 'A'
    header.setUint8(10, 0x56); // 'V'
    header.setUint8(11, 0x45); // 'E'

    // "fmt " sub-chunk
    header.setUint8(12, 0x66); // 'f'
    header.setUint8(13, 0x6D); // 'm'
    header.setUint8(14, 0x74); // 't'
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 untuk PCM)
    header.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);

    // "data" sub-chunk
    header.setUint8(36, 0x64); // 'd'
    header.setUint8(37, 0x61); // 'a'
    header.setUint8(38, 0x74); // 't'
    header.setUint8(39, 0x61); // 'a'
    header.setUint32(40, subChunk2Size, Endian.little);

    final wav = Uint8List(44 + pcmBytes.length);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, wav.length, pcmBytes);
    return wav;
  }

  /// Transkripsi byte PCM audio menjadi teks pertanyaan jemaah.
  Future<String> transcribePcm(
    Uint8List pcmBytes, {
    String? language,
  }) async {
    if (pcmBytes.isEmpty || pcmBytes.length < 320) {
      AppLogger.debug(
        'PCM audio buffer terlalu pendek (${pcmBytes.length} bytes)',
        tag: 'AudioTranscription',
      );
      return '';
    }

    final wavBytes = convertPcmToWav(pcmBytes);
    final lang = language ?? 'id';

    // TIER 1: Custom / Local Server (jika dikonfigurasi pengguna di aplikasi)
    if (Get.isRegistered<AiAssistantRepository>()) {
      final repo = Get.find<AiAssistantRepository>();
      final config = repo.currentConfig;
      if (!config.isGroq && !config.isOpenRouter && !config.isPlaceholder) {
        try {
          final customResult = await _transcribeWithOpenAiEndpoint(
            endpoint: config.audioTranscriptionsUri,
            apiKey: config.effectiveApiKey,
            wavBytes: wavBytes,
            model: 'whisper-1',
            language: lang,
          );
          if (customResult.isNotEmpty) return customResult;
        } catch (e) {
          AppLogger.warn(
            'Custom/Local transcription server gagal, fallback ke Groq: $e',
            tag: 'AudioTranscription',
          );
        }
      }
    }

    // TIER 2: Groq Whisper Cloud (whisper-large-v3-turbo, ~250ms)
    try {
      final groqResult = await _transcribeWithOpenAiEndpoint(
        endpoint: Uri.parse(
          '${AiServerConfig.groqBaseUrl}${AiServerConfig.audioTranscriptionsPath}',
        ),
        apiKey: AiSecretVault.groqApiKey,
        wavBytes: wavBytes,
        model: 'whisper-large-v3-turbo',
        language: lang,
      );
      if (groqResult.isNotEmpty) return groqResult;
    } catch (e) {
      AppLogger.warn(
        'Groq Whisper Cloud transcription error: $e',
        tag: 'AudioTranscription',
      );
    }

    // TIER 3: Fallback ke Groq model whisper-large-v3
    try {
      final groqFallback = await _transcribeWithOpenAiEndpoint(
        endpoint: Uri.parse(
          '${AiServerConfig.groqBaseUrl}${AiServerConfig.audioTranscriptionsPath}',
        ),
        apiKey: AiSecretVault.groqApiKey,
        wavBytes: wavBytes,
        model: 'whisper-large-v3',
        language: lang,
      );
      if (groqFallback.isNotEmpty) return groqFallback;
    } catch (_) {}

    return '';
  }

  Future<String> _transcribeWithOpenAiEndpoint({
    required Uri endpoint,
    required String apiKey,
    required Uint8List wavBytes,
    required String model,
    required String language,
  }) async {
    final request = http.MultipartRequest('POST', endpoint);
    if (apiKey.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $apiKey';
    }
    request.fields['model'] = model;
    request.fields['language'] = language;
    request.fields['response_format'] = 'json';
    request.fields['temperature'] = '0.0';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        wavBytes,
        filename: 'smartband_audio.wav',
      ),
    );

    final streamedResponse = await _client.send(request).timeout(
      const Duration(seconds: 12),
    );

    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dynamic json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is Map<String, dynamic> && json.containsKey('text')) {
        return (json['text'] as String?)?.trim() ?? '';
      }
    }

    throw Exception(
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }
}

