import 'package:flutter_test/flutter_test.dart';
import 'package:img_classification/src/utils/prediction_utils.dart';

void main() {
  group('PredictionUtils.mapScoreWithLabel', () {
    test('returns correct map for non-binary classification when predictions are empty',
        () {
      var predictions = <num>[];
      var labels = ['A', 'B'];
      var result = PredictionUtils.mapScoreWithLabel(predictions, labels, false, 0);
      expect(result, {});
    });

    test('throws ArgumentError when labels are empty',
            () {
          var predictions = [0.1, 0.2];
          var labels = <String>[];
          expect(
                  () =>
                  PredictionUtils.mapScoreWithLabel(predictions, labels, false, 0),
              throwsArgumentError);
        });

    test('throws ArgumentError when labels are lower than predictions', () {
      var predictions = [0.1, 0.2];
      var labels = ['A'];
      expect(
          () =>
              PredictionUtils.mapScoreWithLabel(predictions, labels, false, 0),
          throwsArgumentError);
    });

    test('returns correct map for non-binary classification with matching predictions and labels', () {
      var predictions = [0.1, 0.2];
      var labels = ['A', 'B'];
      var result = PredictionUtils.mapScoreWithLabel(predictions, labels, false, 0);
      expect(result, {'A': 0.1, 'B': 0.2});
    });

    test(
        'throws ArgumentError for binary classification if multiple predictions',
        () {
      var predictions = [0.1, 0.2];
      var labels = ['A', 'B'];
      expect(
          () => PredictionUtils.mapScoreWithLabel(predictions, labels, true, 0),
          throwsArgumentError);
    });

    test(
        'throws ArgumentError for binary classification if not exactly two labels',
        () {
      var predictions = [0.1, 0.2];
      var labels = ['A'];
      expect(
          () => PredictionUtils.mapScoreWithLabel(predictions, labels, true, 0),
          throwsArgumentError);
    });

    test('returns correct map for binary classification above threshold', () {
      var predictions = [0.7];
      var labels = ['A', 'B'];
      var result =
          PredictionUtils.mapScoreWithLabel(predictions, labels, true, 0.5);
      expect(result, {'B': 0.7});
    });

    test('returns correct map for binary classification below threshold', () {
      var predictions = [0.3];
      var labels = ['A', 'B'];
      var result =
          PredictionUtils.mapScoreWithLabel(predictions, labels, true, 0.5);
      expect(result, {'A': 0.3});
    });
  });
}
