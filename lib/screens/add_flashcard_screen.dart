import 'package:amma/util/providers/auth_provider.dart';
import 'package:amma/util/providers/suggestions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

final audioRecordingProvider = StateProvider<String?>((ref) => null);

class AddFlashcardScreen extends ConsumerStatefulWidget {
  final DocumentSnapshot? doc;

  const AddFlashcardScreen({super.key, this.doc});

  @override
  AddFlashcardScreenState createState() => AddFlashcardScreenState();
}

class AddFlashcardScreenState extends ConsumerState<AddFlashcardScreen> {
  File? _image;
  final TextEditingController _annotationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _selectedLanguage = 'English';
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  final List<String> _languages = [
    'English',
    'Telugu',
    'Hindi',
    'Kannada',
    'Tamil',
    'Malayalam',
    'Marathi',
    'Bengali',
    'Gujarati',
    'Arabic',
    'Urdu'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.doc != null) {
      final data = widget.doc!.data() as Map<String, dynamic>;
      _annotationController.text = data['annotation'];
      _selectedLanguage = _getLanguageFromLocale(data['language']);
      ref.read(audioRecordingProvider.notifier).state = data['audioUrl'];
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    if (pickedFile != null) {
      File? croppedFile = await _cropImage(File(pickedFile.path));
      setState(() {
        if (croppedFile != null) {
          _image = croppedFile;
        }
      });
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.purple,
          toolbarWidgetColor: Colors.black,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          minimumAspectRatio: 1.0,
        ),
      ],
    );
    if (croppedFile != null) {
      ref
          .read(imageLabelSuggestionsProvider.notifier)
          .updateInputImage(InputImage.fromFilePath(croppedFile.path));
      await ref
          .read(imageLabelSuggestionsProvider.notifier)
          .processImageLabelsForSelectedImage();
      return File(croppedFile.path);
    }
    return null;
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final String filePath =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: filePath);
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
      if (path != null) {
        ref.read(audioRecordingProvider.notifier).state = path;
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _saveFlashcard() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an image')),
      );
      return;
    }

    if (_annotationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an annotation')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      String? audioUrl;

      final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}';

      // Compressing and uploading the image
      List<int> compressedImage = await FlutterImageCompress.compressWithList(
        _image!.readAsBytesSync(),
        minHeight: 480,
        minWidth: 480,
        quality: 30,
      );

      Uint8List compressedUint8List = Uint8List.fromList(compressedImage);

      final imageStorageRef = FirebaseStorage.instance
          .ref()
          .child('users/$userId/flashcards/${fileName}_image.jpg');
      await imageStorageRef.putData(compressedUint8List);

      imageUrl = await imageStorageRef.getDownloadURL();

      // Uploading audio if available
      final audioPath = ref.read(audioRecordingProvider);
      if (audioPath != null) {
        final audioFile = File(audioPath);
        final audioStorageRef = FirebaseStorage.instance
            .ref()
            .child('users/$userId/flashcards/${fileName}_audio.m4a');
        await audioStorageRef.putFile(audioFile);
        audioUrl = await audioStorageRef.getDownloadURL();
      }

      final flashcardsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('flashcards');

      final flashcardData = {
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'annotation': _annotationController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'language': _getLocaleFromLanguage(_selectedLanguage),
      };

      if (widget.doc == null) {
        // Create new flashcard
        await flashcardsRef.add(flashcardData);
      } else {
        // Update existing flashcard
        await widget.doc!.reference.update(flashcardData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flashcard saved successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save flashcard: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getLocaleFromLanguage(String language) {
    switch (language) {
      case 'English':
        return 'en_US';
      case 'Telugu':
        return 'te_IN';
      case 'Hindi':
        return 'hi_IN';
      case 'Kannada':
        return 'kn_IN';
      case 'Tamil':
        return 'ta_IN';
      case 'Malayalam':
        return 'ml_IN';
      case 'Marathi':
        return 'mr_IN';
      case 'Bengali':
        return 'bn_IN';
      case 'Gujarati':
        return 'gu_IN';
      case 'Arabic':
        return 'ar';
      case 'Urdu':
        return 'ur_IN';
      default:
        return 'en_US';
    }
  }

  String _getLanguageFromLocale(String locale) {
    switch (locale) {
      case 'en_US':
        return 'English';
      case 'te_IN':
        return 'Telugu';
      case 'hi_IN':
        return 'Hindi';
      case 'kn_IN':
        return 'Kannada';
      case 'ta_IN':
        return 'Tamil';
      case 'ml_IN':
        return 'Malayalam';
      case 'mr_IN':
        return 'Marathi';
      case 'bn_IN':
        return 'Bengali';
      case 'gu_IN':
        return 'Gujarati';
      case 'ar':
        return 'Arabic';
      case 'ur_IN':
        return 'Urdu';
      default:
        return 'English';
    }
  }

  @override
  Widget build(BuildContext context) {
    var suggestions = ref.watch(imageLabelSuggestionsProvider).suggestions;
    final audioPath = ref.watch(audioRecordingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doc == null ? 'Add Flashcard' : 'Edit Flashcard'),
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.black),
                      ),
                      child: _image != null
                          ? Image.file(_image!)
                          : widget.doc != null
                              ? Image.network(
                                  (widget.doc!.data()
                                      as Map<String, dynamic>)['imageUrl'],
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text('Take Picture'),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: suggestions.map((label) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          _annotationController.text = label;
                        },
                        child: Chip(
                          label: Text(label),
                          backgroundColor: Colors.purple,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
                items: _languages.map((language) {
                  return DropdownMenuItem<String>(
                    value: language,
                    child: Text(language),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Language',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _annotationController,
                decoration: const InputDecoration(labelText: 'Annotation'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    child: Text(
                        _isRecording ? 'Stop Recording' : 'Start Recording'),
                  ),
                  Text(audioPath != null ? 'Audio Recorded' : 'No Audio'),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveFlashcard,
                child: Text(
                    widget.doc == null ? 'Add Flashcard' : 'Save Flashcard'),
              ),
              const SizedBox(height: 20),
              if (_isLoading) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _annotationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
}
