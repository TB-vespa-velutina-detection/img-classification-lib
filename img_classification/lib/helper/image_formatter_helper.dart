import 'package:image/image.dart';

class ImageFormatterHelper {
  static List<List<List<double>>> toResizedMatrix(
      Image image, int newWidth, int newHeight) {
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
          return [
            (pixel.r / 127.5) - 1,
            (pixel.g / 127.5) - 1,
            (pixel.b / 127.5) - 1,
          ];
        },
      ),
    );
    return imageMatrix;
  }
}
