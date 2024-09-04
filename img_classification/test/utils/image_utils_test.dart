import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart';
import 'package:img_classification/model/option_enum.dart';
import 'package:img_classification/src/utils/image_utils.dart';

void main() {
  group('ImageFormatterHelper', () {
    test('toResizedMatrix returns correct dimensions (source is bigger thant target)', () {
      final image = Image(width: 10, height: 10);
      final result = ImageUtils.toResizedMatrix(image, 5, 5);
      expect(result.length, 5);
      expect(result[0].length, 5);
    });

    test('toResizedMatrix returns correct dimensions (source is smaller than target)', () {
      final image = Image(width: 5, height: 5);
      final result = ImageUtils.toResizedMatrix(image, 10, 10);
      expect(result.length, 10);
      expect(result[0].length, 10);
    });

    test('toResizedMatrix normalizes pixels correctly with NormalizeOption.none', () {
      final image = Image(width: 2, height: 2);
      image.setPixel(0, 0, ColorInt8.rgb(255, 0, 0));
      image.setPixel(1, 0, ColorInt8.rgb(0, 255, 0));
      image.setPixel(0, 1, ColorInt8.rgb(0, 0, 255));
      image.setPixel(1, 1, ColorInt8.rgb(255, 255, 255));
      final result = ImageUtils.toResizedMatrix(image, 2, 2, NormalizeMethod.none);
      expect(result[0][0], [255, 0, 0]);
      expect(result[0][1], [0, 255, 0]);
      expect(result[1][0], [0, 0, 255]);
      expect(result[1][1], [255, 255, 255]);
    });

    test('toResizedMatrix normalizes pixels correctly with NormalizeOption.zero_to_one', () {
      final image = Image(width: 2, height: 2);
      image.setPixel(0, 0, ColorInt8.rgb(255, 0, 0));
      image.setPixel(1, 0, ColorInt8.rgb(0, 255, 0));
      image.setPixel(0, 1, ColorInt8.rgb(0, 0, 255));
      image.setPixel(1, 1, ColorInt8.rgb(255, 255, 255));
      final result = ImageUtils.toResizedMatrix(image, 2, 2, NormalizeMethod.zero_to_one);
      expect(result[0][0], [1.0, 0.0, 0.0]);
      expect(result[0][1], [0.0, 1.0, 0.0]);
      expect(result[1][0], [0.0, 0.0, 1.0]);
      expect(result[1][1], [1.0, 1.0, 1.0]);
    });

    test('toResizedMatrix normalizes pixels correctly with NormalizeOption.minus_one_to_one', () {
      final image = Image(width: 2, height: 2);
      image.setPixel(0, 0, ColorInt8.rgb(255, 0, 0));
      image.setPixel(1, 0, ColorInt8.rgb(0, 255, 0));
      image.setPixel(0, 1, ColorInt8.rgb(0, 0, 255));
      image.setPixel(1, 1, ColorInt8.rgb(255, 255, 255));
      final result = ImageUtils.toResizedMatrix(image, 2, 2, NormalizeMethod.minus_one_to_one);
      expect(result[0][0], [1.0, -1.0, -1.0]);
      expect(result[0][1], [-1.0, 1.0, -1.0]);
      expect(result[1][0], [-1.0, -1.0, 1.0]);
      expect(result[1][1], [1.0, 1.0, 1.0]);
    });

    test('toResizedMatrix throws error on empty', () {
      final image = Image(width: 0, height: 0);
      expect(() => ImageUtils.toResizedMatrix(image, 2, 2), throwsRangeError);
    });
  });
}