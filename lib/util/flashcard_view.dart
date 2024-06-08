import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amma/util/providers/speech_providers.dart';

class FlashcardViewPage extends ConsumerStatefulWidget {
  final String imgUrl;
  final String description;
  final String language;

  const FlashcardViewPage({
    super.key,
    required this.imgUrl,
    required this.description,
    required this.language,
  });

  @override
  ConsumerState<FlashcardViewPage> createState() => _FlashcardViewPageState();
}

class _FlashcardViewPageState extends ConsumerState<FlashcardViewPage> {
  final TextEditingController _textController = TextEditingController();
  double _ttsSpeed = 1.0;
  double _ttsPitch = 1.0;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeechAndTTS();
  }

  Future<void> _initializeSpeechAndTTS() async {
    final speechToText = ref.read(speechToTextProvider);
    await speechToText.initialize();
    final flutterTts = ref.read(flutterTtsProvider);
    await flutterTts.setLanguage(widget.language);
  }

  Future<void> _startListening() async {
    final speechToText = ref.read(speechToTextProvider);
    if (await speechToText.initialize(
      onStatus: (status) {
        if (status == 'listening') {
          setState(() => _isListening = true);
        } else {
          setState(() => _isListening = false);
        }
      },
    )) {
      speechToText.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
          });
        },
        localeId: widget.language,
      );
    }
  }

  void _stopListening() {
    final speechToText = ref.read(speechToTextProvider);
    speechToText.stop();
  }

  void _speakText() {
    final flutterTts = ref.read(flutterTtsProvider);
    flutterTts.setSpeechRate(_ttsSpeed);
    flutterTts.setPitch(_ttsPitch);
    flutterTts.speak(widget.description);
  }

  @override
  Widget build(BuildContext context) {
    _ttsSpeed = ref.watch(ttsSettingsProvider).speed;
    _ttsPitch = ref.watch(ttsSettingsProvider).pitch;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech to Text & TTS'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.network(widget.imgUrl),
            const SizedBox(height: 10),
            Text(widget.description),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Recognized Text',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isListening ? _stopListening : _startListening,
                    child: Text(
                        _isListening ? 'Stop Listening' : 'Start Listening'),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _speakText,
                    child: const Text('Speak Text'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('TTS Speed: ${_ttsSpeed.toStringAsFixed(2)}'),
            Slider(
              value: _ttsSpeed,
              min: 0.1,
              max: 2.0,
              onChanged: (value) {
                setState(() {
                  _ttsSpeed = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Text('TTS Pitch: ${_ttsPitch.toStringAsFixed(2)}'),
            Slider(
              value: _ttsPitch,
              min: 0.5,
              max: 2.0,
              onChanged: (value) {
                setState(() {
                  _ttsPitch = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
