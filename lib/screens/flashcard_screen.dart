import 'package:amma/screens/add_flashcard_screen.dart';
import 'package:amma/screens/settings_screen.dart';
import 'package:amma/util/providers/auth_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key});

  @override
  FlashcardScreenState createState() => FlashcardScreenState();
}

class FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  late Future<void> _refreshFuture;

  @override
  void initState() {
    super.initState();
    _refreshFuture = _fetchFlashcards();
  }

  Future<void> _fetchFlashcards() async {
    // Simulating a fetch delay
    await Future.delayed(const Duration(seconds: 1));
    return;
  }

  @override
  Widget build(BuildContext context) {
    final User? user = ref.watch(firebaseAuthProvider).currentUser;

    if (user == null) {
      // If the user is not logged in, display a login screen or handle the case appropriately
      return const Scaffold(
        body: Center(
          child: Text(
            'Please log in',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final flashcardsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('flashcards');

    Future<void> deleteFlashcard(String docId, String? imageUrl) async {
      try {
        // Delete the image from Firebase Storage if there's a URL
        if (imageUrl != null) {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        }

        // Delete the flashcard document from Firestore
        await flashcardsRef.doc(docId).delete();

        // Show a confirmation snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flashcard deleted')),
        );
      } catch (e) {
        // Show an error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete flashcard')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Flashcards',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ));
            },
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _refreshFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: flashcardsRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final flashcards = snapshot.data?.docs ?? [];

              if (flashcards.isEmpty) {
                return const Center(
                  child: Text(
                    'No flashcards found',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }

              return PageView(
                children: [
                  GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getGridCrossAxisCount(context),
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                    ),
                    itemCount: flashcards.length,
                    itemBuilder: (context, index) {
                      final data =
                          flashcards[index].data() as Map<String, dynamic>;
                      final docId = flashcards[index].id; // Get the document ID

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          elevation: 5.0,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(data['imageUrl']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      data['annotation'],
                                      style: const TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 5.0,
                                right: 5.0,
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AddFlashcardScreen(
                                              doc: flashcards[index],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        await deleteFlashcard(
                                            docId, data['imageUrl']);
                                        setState(() {
                                          flashcards.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const AddFlashcardScreen(),
          ));
        },
      ),
    );
  }

  int _getGridCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return 4; // For larger screens like tablets and laptops
    } else {
      return 2; // For smaller screens like phones
    }
  }
}
