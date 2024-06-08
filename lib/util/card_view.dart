import 'package:amma/screens/game_screen.dart';
import 'package:amma/util/flashcard_card_view.dart';
import 'package:flutter/material.dart';

class DraggableFlashCard extends StatelessWidget {
  final Content content;

  const DraggableFlashCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
        child: FlashcardCardViewPage(
            imgUrl: content.imageUrl,
            description: content.text,
            language: content.locale));
  }
}
