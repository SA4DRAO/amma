import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amma/util/providers/speech_providers.dart';
import 'package:just_audio/just_audio.dart';

class FlashcardViewPage extends ConsumerStatefulWidget {
  final String imgUrl;
  final String description;
  final String language;
  final String? audioUrl;

  const FlashcardViewPage({
    super.key,
    required this.imgUrl,
    required this.description,
    required this.language,
    this.audioUrl,
  });

  @override
  ConsumerState<FlashcardViewPage> createState() => _FlashcardViewPageState();
}

class _FlashcardViewPageState extends ConsumerState<FlashcardViewPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isListening = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isCustomAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeechAndTTS();
    _initializeAudioPlayer();
  }

  Future<void> _initializeSpeechAndTTS() async {
    final speechToText = ref.read(speechToTextProvider);
    await speechToText.initialize();
    final flutterTts = ref.read(flutterTtsProvider);
    await flutterTts.setLanguage(widget.language);
  }

  void _initializeAudioPlayer() {
    if (widget.audioUrl != null) {
      _audioPlayer.setUrl(widget.audioUrl!);
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isCustomAudioPlaying = false;
          });
        }
      });
    }
  }

  Future<void> _startListening() async {
    final speechToText = ref.read(speechToTextProvider);
    if (await speechToText.initialize()) {
      setState(() {
        _isListening = true;
      });
      speechToText.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
            _isListening = false;

            if (result.recognizedWords.toLowerCase() ==
                widget.description.toLowerCase()) {
              _showCorrectWordDialog();
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

  Future<void> _playAudio() async {
    if (widget.audioUrl != null) {
      setState(() {
        _isCustomAudioPlaying = true;
      });
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } else {
      _speakText();
    }
  }

  void _speakText() {
    final flutterTts = ref.read(flutterTtsProvider);
    final ttsSettings = ref.watch(ttsSettingsProvider);
    flutterTts.setSpeechRate(ttsSettings.speed);
    flutterTts.setPitch(ttsSettings.pitch);
    flutterTts.speak(widget.description);
  }

  void _showCorrectWordDialog() {
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

  @override
  Widget build(BuildContext context) {
    final ttsSettings = ref.watch(ttsSettingsProvider);
    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) async {
        await _audioPlayer.stop();
      },
      child: Scaffold(
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
                      onPressed:
                          _isListening ? _stopListening : _startListening,
                      child: Text(
                          _isListening ? 'Stop Listening' : 'Start Listening'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCustomAudioPlaying ? null : _playAudio,
                      child: Text(widget.audioUrl != null
                          ? (_isCustomAudioPlaying
                              ? 'Playing...'
                              : 'Play Audio')
                          : 'Speak Text'),
                    ),
                  ),
                ],
              ),
              if (widget.audioUrl == null) ...[
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
