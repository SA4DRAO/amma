import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FlashcardNotifier
    extends StateNotifier<List<QueryDocumentSnapshot<Map<String, dynamic>>>> {
  FlashcardNotifier() : super([]);

  Future<void> loadFlashcards(User user) async {
    final flashcardsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('flashcards');

    final snapshot = await flashcardsRef.get();
    state = snapshot.docs;
  }

  Future<void> deleteFlashcard(
      User user, String docId, String? imageUrl) async {
    // Delete the image from Firebase Storage if there's a URL
    if (imageUrl != null) {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
    }

    // Delete the flashcard document from Firestore
    final flashcardsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('flashcards');
    await flashcardsRef.doc(docId).delete();

    // Update state
    state = state.where((doc) => doc.id != docId).toList();
  }
}

final flashcardProvider = StateNotifierProvider<FlashcardNotifier,
    List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  return FlashcardNotifier();
});
