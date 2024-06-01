import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

final flutterTtsProvider = Provider((ref) => FlutterTts());

final speechToTextProvider = Provider((ref) => SpeechToText());
