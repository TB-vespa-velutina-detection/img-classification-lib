import 'package:img_classification/model/option_enum.dart';

/// A class representing options for image classification.
///
/// This class holds various configuration options that can be used to
/// customize the behavior of an image classification model.
// [numThreads]: The number of threads to use (default is 1).
// [useGpu]: Whether to use GPU (default is false).
// [useXnnPack]: Whether to use XNNPACK (default is false).
// [isBinary]: Whether the classification is binary (default is false).
// [binaryThreshold]: The threshold for binary classification (default is 0.5).
class ImageClassificationOption {
  final int numThreads;
  final bool useGpu;
  final bool useXnnPack;
  final NormalizeMethod normalizeMethod;
  final bool isBinary;
  final double binaryThreshold;

  ImageClassificationOption({
    this.numThreads = 1,
    this.useGpu = false,
    this.useXnnPack = false,
    this.normalizeMethod = NormalizeMethod.none,
    this.isBinary = false,
    this.binaryThreshold = 0.5
  });
}