import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ListeningNotifier extends StateNotifier<ListeningState> {
  final stt.SpeechToText _speechToText;

  ListeningNotifier()
      : _speechToText = stt.SpeechToText(),
        super(ListeningState());

  void startListening({required String description}) async {
    if (state.isListening) {
      stopListening();
      return;
    }
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == stt.SpeechToText.listeningStatus) {
          state = state.copyWith(
            isListening: true,
            microphoneColor: Colors.red,
            textColor: Colors.red,
          );
        }
      },
      onError: (error) {
        stopListening();
      },
    );
    if (available) {
      _speechToText.listen(
        localeId: state.locale,
        onResult: (result) {
          String newText = result.recognizedWords;
          List<String> words = newText.toLowerCase().split(' ');
          Color newTextColor = state.textColor;
          if (words.contains(description.toLowerCase())) {
            newTextColor = Colors.green;
            stopListening();
          }
          state = state.copyWith(
            text: newText,
            textColor: newTextColor,
            microphoneColor: Colors.blue,
          );
        },
      );
    } else {
      stopListening();
    }
  }

  void stopListening() {
    _speechToText.stop();
    state = state.copyWith(
      isListening: false,
      microphoneColor: Colors.blue,
    );
  }

  void setLocale({required String newLocale}) {
    state = state.copyWith(locale: newLocale);
  }

  void reset() {
    stopListening();
    state = state.copyWith(
      isListening: false,
      microphoneColor: Colors.blue,
      textColor: Colors.red,
      text: '',
    );
  }
}

class ListeningState {
  final bool isListening;
  final Color microphoneColor;
  final String text;
  final String locale;
  final Color textColor;

  ListeningState({
    this.isListening = false,
    this.microphoneColor = Colors.blue,
    this.text = '',
    this.locale = 'en_US',
    this.textColor = Colors.red,
  });

  ListeningState copyWith({
    bool? isListening,
    Color? microphoneColor,
    String? text,
    String? locale,
    Color? textColor,
  }) {
    return ListeningState(
      isListening: isListening ?? this.isListening,
      microphoneColor: microphoneColor ?? this.microphoneColor,
      text: text ?? this.text,
      locale: locale ?? this.locale,
      textColor: textColor ?? this.textColor,
    );
  }
}

final listeningProvider =
    StateNotifierProvider<ListeningNotifier, ListeningState>((ref) {
  return ListeningNotifier();
});
