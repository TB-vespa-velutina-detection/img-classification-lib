import 'dart:math';

class PredictionUtils {
  static Map<String, double> mapScoreWithLabel(List<num> predictions,
      List<String> labels, bool isBinary, double threshold) {
    if (predictions.isEmpty) {
      return {};
    }
    if (isBinary) {
      return _mapScoreWithLabelBinary(predictions, labels, threshold);
    } else {
      return _mapScoreWithLabel(predictions, labels);
    }
  }

  static Map<String, double> _mapScoreWithLabel(
      List<num> predictions, List<String> labels) {
    var maxIter = max(predictions.length, labels.length);

    // Set classification map {label: points}
    var classification = <String, double>{};
    // Transform every value to % and assign to corresponding label
    for (var i = 0; i < maxIter; i++) {
      classification[labels[i]] = predictions[i].toDouble();
    }

    return classification;
  }

  static Map<String, double> _mapScoreWithLabelBinary(
      List<num> predictions, List<String> labels, double threshold) {
    if (predictions.length != 1) {
      throw ArgumentError('Binary classification only supports one output.');
    }
    if (labels.length != 2) {
      throw ArgumentError('Binary classification requires exactly two labels.');
    }

    // Set classification map {label: points}
    var classification = <String, double>{};
    // Associate the prediction to the correct label
    var labelIndex = predictions[0] > threshold ? 1 : 0;
    classification[labels[labelIndex]] = predictions[0].toDouble();

    return classification;
  }
}
