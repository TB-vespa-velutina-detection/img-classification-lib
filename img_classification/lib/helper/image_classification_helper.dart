import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:img_classification/model/image_classification_option.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../src/model/inference_model.dart';
import '../src/worker/inference_worker.dart';

class ImageClassificationHelper {
  late ImageClassificationOption _options;
  late Interpreter interpreter;
  late List<String> labels;
  late InferenceWorker inferenceWorker;
  late Tensor inputTensor;
  late Tensor outputTensor;

  InterpreterOptions? _loadOptions(ImageClassificationOption options) {
    final interpreterOptions = InterpreterOptions();

    if (options.numThreads != 1) {
      interpreterOptions.threads = options.numThreads;
    }

    if (options.useGpu) {
      if (Platform.isAndroid) {
        interpreterOptions.addDelegate(GpuDelegateV2());
      } else if (Platform.isIOS) {
        interpreterOptions.addDelegate(GpuDelegate());
      }
    }

    if (options.useXnnPack) {
      interpreterOptions.addDelegate(XNNPackDelegate());
    }

    return interpreterOptions;
  }

  // Load model
  Future<void> _loadModel(
      String modelAssetPath, ImageClassificationOption options) async {
    final interpreterOptions = _loadOptions(options);

    // Load model from assets
    interpreter = await Interpreter.fromAsset(modelAssetPath,
        options: interpreterOptions);
    // Get tensor input shape [1, 224, 224, 3]
    inputTensor = interpreter.getInputTensors().first;
    // Get tensor output shape [1, 1000]
    outputTensor = interpreter.getOutputTensors().first;

    log('input shape $inputTensor');
    log('ouput shape $outputTensor');
    log('Interpreter loaded successfully');
  }

  // Load labels from assets
  Future<void> _loadLabels(String labelsAssetPath, String separator) async {
    final labelTxt = await rootBundle.loadString(labelsAssetPath);
    labels = labelTxt.split(separator);
  }

  Future<void> initHelper(
      {required String modelAssetPath,
      required String labelsAssetPath,
      String separator = '\n',
      ImageClassificationOption? options}) async {
    //TODO: bug...
    // if (inferenceWorker != null) {
    //   inferenceWorker.close();
    // }
    _options = options ?? ImageClassificationOption();
    _loadModel(modelAssetPath, _options);
    _loadLabels(labelsAssetPath, separator);
    inferenceWorker = await InferenceWorker.spawn();
  }

  // inference still image
  Future<Map<String, double>?> inferenceImage(String imgPath) async {
    // If no InfereceWorker, then the helper was never initialized
    if (inferenceWorker == null) {
      throw StateError(
          'InfereceWorker not initialized. Try to call initHelper() on your ImageClassificationHelper');
    }

    // Read image bytes from file
    final imageData = File(imgPath).readAsBytesSync();
    final Image image = decodeImage(imageData)!;

    // Init inferenceModel
    var model = InferenceModel(
        image,
        interpreter.address,
        labels,
        inputTensor.shape,
        outputTensor.shape,
        normalizeMethod: _options.normalizeMethod,
        isBinary: _options.isBinary,
        binaryThreshold: _options.binaryThreshold);

    return await inferenceWorker.inferenceImage(model);
  }
}
