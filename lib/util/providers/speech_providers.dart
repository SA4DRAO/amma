import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

final ttsSettingsProvider =
    StateNotifierProvider<TTSSettingsNotifier, TTSSettings>((ref) {
  return TTSSettingsNotifier();
});

final flutterTtsProvider = Provider<FlutterTts>((ref) {
  final flutterTts = FlutterTts();
  flutterTts.setLanguage('en-US');
  return flutterTts;
});

final speechToTextProvider = Provider<SpeechToText>((ref) {
  final speechToText = SpeechToText();
  speechToText.initialize();
  return speechToText;
});

class TTSSettings {
  double speed;
  double pitch;

  TTSSettings({
    required this.speed,
    required this.pitch,
  });

  TTSSettings copyWith({
    double? speed,
    double? pitch,
  }) {
    return TTSSettings(
      speed: speed ?? this.speed,
      pitch: pitch ?? this.pitch,
    );
  }
}

class TTSSettingsNotifier extends StateNotifier<TTSSettings> {
  TTSSettingsNotifier() : super(TTSSettings(speed: 0.7, pitch: 0.8));

  void setSpeed(double speed) {
    state = state.copyWith(speed: speed);
  }

  void setPitch(double pitch) {
    state = state.copyWith(pitch: pitch);
  }
}
