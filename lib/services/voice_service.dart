import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Reads screens aloud and listens for spoken numbers or crop names, so people
/// who cannot read easily can still use the app. Every call fails quietly:
/// voice is a help, never a requirement.
class VoiceService extends ChangeNotifier {
  FlutterTts? _tts;
  SpeechToText? _stt;
  bool _speaking = false;
  bool _listening = false;
  bool? _sttAvailable;

  bool get isSpeaking => _speaking;
  bool get isListening => _listening;

  Future<void> speak(String text, {required String language}) async {
    if (text.trim().isEmpty) return;
    try {
      _tts ??= FlutterTts();
      final tts = _tts!;
      await tts.stop();
      final available = await tts.isLanguageAvailable(language);
      await tts.setLanguage(available == true ? language : 'hi-IN');
      await tts.setSpeechRate(0.45);
      tts.setCompletionHandler(() {
        _speaking = false;
        notifyListeners();
      });
      _speaking = true;
      notifyListeners();
      await tts.speak(text);
    } catch (e) {
      debugPrint('TTS unavailable: $e');
      _speaking = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
      await _stt?.stop();
    } catch (_) {}
    _speaking = false;
    _listening = false;
    notifyListeners();
  }

  /// Listens once and returns what was heard (or null). [localeId] like hi_IN.
  Future<String?> listen({required String localeId, Duration max = const Duration(seconds: 8)}) async {
    try {
      _stt ??= SpeechToText();
      _sttAvailable ??= await _stt!.initialize(onError: (e) => debugPrint('STT error: $e'));
      if (_sttAvailable != true) return null;
      String? heard;
      _listening = true;
      notifyListeners();
      await _stt!.listen(
        localeId: localeId,
        listenFor: max,
        pauseFor: const Duration(seconds: 3),
        onResult: (r) {
          heard = r.recognizedWords;
        },
      );
      final until = DateTime.now().add(max + const Duration(seconds: 1));
      while (_stt!.isListening && DateTime.now().isBefore(until)) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      await _stt!.stop();
      return heard;
    } catch (e) {
      debugPrint('Speech input unavailable: $e');
      return null;
    } finally {
      _listening = false;
      notifyListeners();
    }
  }

  /// Pulls the first number out of spoken text, including Devanagari/Bengali digits.
  static double? numberFrom(String? spoken) {
    if (spoken == null) return null;
    const native = {
      '०': '0', '१': '1', '२': '2', '३': '3', '४': '4', '५': '5', '६': '6', '७': '7', '८': '8', '९': '9',
      '০': '0', '১': '1', '২': '2', '৩': '3', '৪': '4', '৫': '5', '৬': '6', '৭': '7', '৮': '8', '৯': '9',
    };
    var s = spoken;
    native.forEach((k, v) => s = s.replaceAll(k, v));
    final m = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(s.replaceAll(' ', ''));
    return m == null ? null : double.tryParse(m.group(0)!.replaceAll(',', '.'));
  }
}
