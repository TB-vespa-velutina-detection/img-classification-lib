import 'package:image/image.dart' as image_lib;

/// A model class that holds the necessary data for performing image inference.
///
/// This class encapsulates the image to be processed, the address of the
/// TensorFlow Lite interpreter, the labels for classification, the input
/// tensor shape, and the output tensor shape.
///
/// [image]: The image to be processed.
/// [interpreterAddress]: The memory address of the TensorFlow Lite interpreter.
/// [labels]: The list of labels for classification.
/// [inputShape]: The shape of the input tensor.
/// [outputShape]: The shape of the output tensor.
class InferenceModel {
  image_lib.Image? image;
  int interpreterAddress;
  List<String> labels;
  List<int> inputShape; // i.e. [1, 224, 224, 3]
  List<int> outputShape; //i.e. [1, 1000]

  InferenceModel(this.image, this.interpreterAddress,
      this.labels, this.inputShape, this.outputShape);
}