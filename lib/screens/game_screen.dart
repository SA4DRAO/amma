import 'package:amma/util/card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swipe_cards/draggable_card.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'dart:math'; // Import this for shuffling

class GameScreen extends ConsumerStatefulWidget {
  final User user;

  const GameScreen({super.key, required this.user});

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends ConsumerState<GameScreen> {
  late MatchEngine _matchEngine;
  late List<SwipeItem> _swipeItems;

  @override
  void initState() {
    super.initState();
    _swipeItems = [];
  }

  Future<void> _initSwipeItems(User user) async {
    // Fetch flashcards from Firestore
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(user.uid)
        .collection('flashcards')
        .get();

    // Shuffle the documents
    List<DocumentSnapshot<Map<String, dynamic>>> shuffledDocs =
        snapshot.docs.toList()..shuffle(Random());

    // Iterate through each shuffled document
    for (var doc in shuffledDocs) {
      Map<String, dynamic>? data = doc.data();

      // Extract properties from the document
      String annotation = data?['annotation'] ?? "";
      String imageUrl = data?['imageUrl'] ?? "";
      String language = data?['language'] ?? "";

      // Check if the item already exists in _swipeItems
      bool alreadyExists = _swipeItems.any((item) =>
          item.content.text == annotation &&
          item.content.imageUrl == imageUrl &&
          item.content.locale == language);

      // If the item doesn't exist, add it to _swipeItems
      if (!alreadyExists) {
        _swipeItems.add(SwipeItem(
          content: Content(
            text: annotation,
            imageUrl: imageUrl,
            locale: language,
          ),
          likeAction: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Easy: $annotation"),
              duration: const Duration(milliseconds: 500),
            ));
          },
          nopeAction: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Difficult: $annotation"),
              duration: const Duration(milliseconds: 500),
            ));
          },
          superlikeAction: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Skipped: $annotation"),
              duration: const Duration(milliseconds: 500),
            ));
          },
          onSlideUpdate: (SlideRegion? region) async {},
        ));
      }
    }

    // Initialize MatchEngine after swipe items are populated
    _matchEngine = MatchEngine(swipeItems: _swipeItems);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initSwipeItems(widget.user),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(), // Show a loading indicator while fetching data
          );
        } else {
          return Column(
            children: [
              Expanded(
                child: SwipeCards(
                  matchEngine: _matchEngine,
                  itemBuilder: (BuildContext context, int index) {
                    return DraggableFlashCard(
                      content: _swipeItems[index].content,
                    );
                  },
                  onStackFinished: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Stack Finished"),
                      duration: Duration(milliseconds: 500),
                    ));
                  },
                  itemChanged: (SwipeItem item, int index) {},
                  upSwipeAllowed: true,
                  fillSpace: true,
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

class Content {
  final String text;
  final String imageUrl;
  final String locale;

  Content({
    required this.text,
    required this.imageUrl,
    required this.locale,
  });
}
