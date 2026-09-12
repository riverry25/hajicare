import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

class PhraseItem {
  final String indonesian;
  final String transliteration;
  final String arabic;
  final String category;
  final bool isUrgent;

  const PhraseItem({
    required this.indonesian,
    required this.transliteration,
    required this.arabic,
    required this.category,
    this.isUrgent = false,
  });
}

class CommunicationController extends GetxController {
  late FlutterTts _tts;
  final isSpeaking = false.obs;
  final activePhrase = ''.obs;

  final List<PhraseItem> phrases = const [
    PhraseItem(
      indonesian: 'Tolong, saya butuh dokter',
      transliteration: "Musa'adah, ahtaju tabiban",
      arabic: 'مساعدة، أحتاج طبيباً',
      category: 'Darurat & Kesehatan',
      isUrgent: true,
    ),
    PhraseItem(
      indonesian: 'Saya merasa sakit',
      transliteration: 'Ana mareed',
      arabic: 'أنا مريض',
      category: 'Darurat & Kesehatan',
      isUrgent: false,
    ),
    PhraseItem(
      indonesian: 'Dimana rumah sakit?',
      transliteration: 'Ayna al-mustashfa?',
      arabic: 'أين المستشفى؟',
      category: 'Darurat & Kesehatan',
      isUrgent: false,
    ),
    PhraseItem(
      indonesian: 'Saya tersesat',
      transliteration: "Ana dae'e",
      arabic: 'أنا ضائع',
      category: 'Arah & Lokasi',
      isUrgent: true,
    ),
    PhraseItem(
      indonesian: 'Dimana pintu keluar?',
      transliteration: 'Ayna al-makhraj?',
      arabic: 'أين المخرج؟',
      category: 'Arah & Lokasi',
      isUrgent: false,
    ),
    PhraseItem(
      indonesian: 'Boleh minta air?',
      transliteration: "Mumaakin maa'?",
      arabic: 'ممكن ماء؟',
      category: 'Umum',
      isUrgent: false,
    ),
    PhraseItem(
      indonesian: 'Terima kasih',
      transliteration: 'Shukran',
      arabic: 'شكراً',
      category: 'Umum',
      isUrgent: false,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _initTts();
  }

  void _initTts() {
    _tts = FlutterTts();
    _tts.setLanguage('ar-SA');
    _tts.setStartHandler(() {
      isSpeaking.value = true;
    });
    _tts.setCompletionHandler(() {
      isSpeaking.value = false;
      activePhrase.value = '';
    });
    _tts.setErrorHandler((_) {
      isSpeaking.value = false;
      activePhrase.value = '';
    });
  }

  Future<void> speak(String text) async {
    activePhrase.value = text;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    isSpeaking.value = false;
    activePhrase.value = '';
  }

  @override
  void onClose() {
    _tts.stop();
    super.onClose();
  }
}
