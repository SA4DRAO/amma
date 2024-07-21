import 'package:amma/util/flashcard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:amma/screens/add_flashcard_screen.dart';
import 'package:amma/screens/settings_screen.dart';
import 'package:amma/util/providers/auth_provider.dart';

final flashcardsStreamProvider = StreamProvider.family<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>, User>((ref, user) {
  final flashcardsRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('flashcards');
  return flashcardsRef.snapshots().map(
        (snapshot) => snapshot.docs,
      );
});

final flashcardDeletionProvider =
    AutoDisposeFutureProvider.family<void, String>((ref, docId) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return;

  final flashcardData = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('flashcards')
      .doc(docId)
      .get();

  final imageUrl = flashcardData.data()?['imageUrl'];

  try {
    // Delete the image from Firebase Storage if there's a URL
    if (imageUrl != null) {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
    }

    // Delete the flashcard document from Firestore
    await flashcardData.reference.delete();
  } catch (e) {
    // Handle error
  }
});

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key});

  @override
  FlashcardScreenState createState() => FlashcardScreenState();
}

class FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = ref.watch(firebaseAuthProvider).currentUser;

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

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'My Flashcards',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildFlashcardContent(user),
          const SettingsScreen(),
          const AddFlashcardScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AddFlashcardScreen()));
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 60.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {
                  setState(() {
                    _currentIndex = 0; // Navigate to the flashcards tab
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  setState(() {
                    _currentIndex = 1; // Navigate to the settings tab
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlashcardContent(User user) {
    return Consumer(
      builder: (context, ref, child) {
        final flashcards = ref.watch(flashcardsStreamProvider(user));
        return flashcards.when(
          data: (flashcards) {
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
                    final data = flashcards[index].data();
                    final docId = flashcards[index].id;
                    return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return FlashcardViewPage(
                                imgUrl: data['imageUrl'],
                                description: data['annotation'],
                                language: data['language'],
                                audioUrl: data['audioUrl'],
                              );
                            }));
                          },
                          child: Card(
                            elevation: 5.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(data['imageUrl']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0.0,
                                  left: 0.0,
                                  right: 0.0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(15.0),
                                        bottomRight: Radius.circular(15.0),
                                      ),
                                    ),
                                    child: Text(
                                      data['annotation'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 5.0,
                                  right: 5.0,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                        ),
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
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                        onPressed: () async {
                                          try {
                                            final deleteFlashcard = ref.read(
                                                flashcardDeletionProvider(
                                                    docId));
                                            deleteFlashcard;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Flashcard deleted')),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Failed to delete flashcard')),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ));
                  },
                ),
              ],
            );
          },
          error: (error, stackTrace) => Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
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
