import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

final imageLabelSuggestionsProvider = StateNotifierProvider<
    ImageLabelSuggestionsNotifier, ImageLabelSuggestionsState>((ref) {
  final inputImage =
      InputImage.fromFilePath(""); // Example: Provide a default image path here
  final options = ImageLabelerOptions(confidenceThreshold: 0.5);

  return ImageLabelSuggestionsNotifier(inputImage, options);
});

class ImageLabelSuggestionsNotifier
    extends StateNotifier<ImageLabelSuggestionsState> {
  late InputImage inputImage;
  final ImageLabelerOptions options;
  ImageLabelSuggestionsNotifier(this.inputImage, this.options)
      : super(ImageLabelSuggestionsState());

  Future<void> processImageLabels() async {
    final imageLabeler = ImageLabeler(options: options);
    final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
    state = state.copyWith(labels: labels);

    final List<String> suggestions =
        labels.map((label) => label.label).toList();
    state = state.copyWith(suggestions: suggestions);
  }

  // Function to update the input image
  void updateInputImage(InputImage newInputImage) {
    inputImage = newInputImage;
  }

  // Function to process image labels with the updated input image
  Future<void> processImageLabelsForSelectedImage() async {
    await processImageLabels();
  }
}

class ImageLabelSuggestionsState {
  final List<ImageLabel> labels;
  final List<String> suggestions;

  ImageLabelSuggestionsState({
    this.labels = const [],
    this.suggestions = const [],
  });

  ImageLabelSuggestionsState copyWith({
    List<ImageLabel>? labels,
    List<String>? suggestions,
  }) {
    return ImageLabelSuggestionsState(
      labels: labels ?? this.labels,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}
