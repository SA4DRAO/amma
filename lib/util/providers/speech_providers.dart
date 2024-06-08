import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

final ttsSettingsProvider = Provider<TTSSettings>((ref) {
  return TTSSettings(
    speed: 0.7, // Default speed
    pitch: 0.8, // Default pitch
  );
});
final flutterTtsProvider = Provider<FlutterTts>((ref) {
  final flutterTts = FlutterTts();
  flutterTts.setLanguage('en-US');
  return flutterTts;
});

final speechToTextProvider = Provider<SpeechToText>((ref) {
  final speechToText = SpeechToText();
  return speechToText;
});

class TTSSettings {
  double speed;
  double pitch;

  TTSSettings({
    required this.speed,
    required this.pitch,
  });

  void setSpeed(double speed) {
    this.speed = speed;
  }

  void setPitch(double pitch) {
    this.pitch = pitch;
  }
}
