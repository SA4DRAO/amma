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
    final speechToText = ref.watch(speechToTextProvider);
    if (await speechToText.initialize()) {
      setState(() {
        _isListening = true;
      });
      speechToText.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
            _isListening = false;

            // Check if the recognized word matches the description
            if (result.recognizedWords.toLowerCase() ==
                widget.description.toLowerCase()) {
              // Show dialog with smiley face
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Correct Word Detected!'),
                    content: const Text('😊'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              );
            }
          });
        },
        localeId: widget.language,
      );
    }
  }

  void _stopListening() {
    final speechToText = ref.read(speechToTextProvider);
    speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _speakText() {
    final flutterTts = ref.read(flutterTtsProvider);
    final ttsSettings = ref.watch(ttsSettingsProvider);
    flutterTts.setSpeechRate(ttsSettings.speed);
    flutterTts.setPitch(ttsSettings.pitch);
    flutterTts.speak(widget.description);
  }

  @override
  Widget build(BuildContext context) {
    final ttsSettings = ref.watch(ttsSettingsProvider);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.description),
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
            Text('TTS Speed: ${ttsSettings.speed.toStringAsFixed(2)}'),
            Slider(
              value: ttsSettings.speed,
              min: 0.1,
              max: 2.0,
              onChanged: (value) {
                ref.read(ttsSettingsProvider.notifier).setSpeed(value);
              },
            ),
            const SizedBox(height: 20),
            Text('TTS Pitch: ${ttsSettings.pitch.toStringAsFixed(2)}'),
            Slider(
              value: ttsSettings.pitch,
              min: 0.5,
              max: 2.0,
              onChanged: (value) {
                ref.read(ttsSettingsProvider.notifier).setPitch(value);
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
