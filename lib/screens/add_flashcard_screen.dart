import 'package:amma/util/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

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
  String _selectedLanguage = 'English'; // Default language

  final List<String> _languages = ['English', 'Telugu', 'Hindi'];

  @override
  void initState() {
    super.initState();
    if (widget.doc != null) {
      final data = widget.doc!.data() as Map<String, dynamic>;
      _annotationController.text = data['annotation'];
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
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          minimumAspectRatio: 1.0,
        ),
      ],
    );
    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  Future<void> _saveFlashcard() async {
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
      if (_image != null) {
        final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('users/$userId/flashcards/$fileName');
        await storageRef.putFile(_image!);
        imageUrl = await storageRef.getDownloadURL();
      }

      final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
      final flashcardsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('flashcards');

      if (widget.doc == null) {
        // Create new flashcard
        await flashcardsRef.add({
          'imageUrl': imageUrl,
          'annotation': _annotationController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'language': _getLocaleFromLanguage(_selectedLanguage),
        });
      } else {
        // Update existing flashcard
        final data = widget.doc!.data() as Map<String, dynamic>;
        await widget.doc!.reference.update({
          'imageUrl': imageUrl ?? data['imageUrl'],
          'annotation': _annotationController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'language': _getLocaleFromLanguage(_selectedLanguage),
        });
      }

      // Check if the widget is still mounted before showing the SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flashcard saved successfully')),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      // Check if the widget is still mounted before showing the SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save flashcard: $e')),
        );
      }
    } finally {
      // Check if the widget is still mounted before updating state
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
        return 'en';
      case 'Telugu':
        return 'te';
      case 'Hindi':
        return 'hi';
      default:
        return 'en'; // Default to English
    }
  }

  @override
  Widget build(BuildContext context) {
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
}
