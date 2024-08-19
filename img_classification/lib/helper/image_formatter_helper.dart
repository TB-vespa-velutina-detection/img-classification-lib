import 'package:image/image.dart';
import 'package:img_classification/model/option_enum.dart';

class ImageFormatterHelper {
  /// Convert an image to a 3D matrix of RGB pixel values.
  static List<List<List<num>>> toResizedMatrix(
      Image image, int newWidth, int newHeight,
      [NormalizeOption option = NormalizeOption.none]) {
    Image imageInput = copyResize(
      image,
      width: newWidth,
      height: newHeight,
    );

    // RGB value of each pixel in image
    final imageMatrix = List.generate(
      imageInput.height,
      (y) => List.generate(
        imageInput.width,
        (x) {
          final pixel = imageInput.getPixel(x, y);
          return _normalizePixel(pixel.r, pixel.g, pixel.b, option);
        },
      ),
    );
    return imageMatrix;
  }

  /// Normalize pixel values based on the given option.
  static List<num> _normalizePixel(
      num r, num g, num b, NormalizeOption option) {
    switch (option) {
      case NormalizeOption.none:
        return [r, g, b];
      case NormalizeOption.zero_to_one:
        return [(r / 255), (g / 255), (b / 255)];
      case NormalizeOption.minus_one_to_one:
        return [
          (r / 127.5) - 1,
          (g / 127.5) - 1,
          (b / 127.5) - 1,
        ];
    }
  }
}
