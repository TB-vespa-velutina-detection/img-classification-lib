import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:img_classification/model/image_classification_option.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../src/utils/image_utils.dart';
import '../src/utils/prediction_utils.dart';

class ImageClassificationHelper {
  ImageClassificationOption? _options;
  String? _modelAssetPath;
  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  List<String>? _labels;
  Tensor? _inputTensor;
  Tensor? _outputTensor;

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
  Future<void> _loadModel(ImageClassificationOption options) async {
    final interpreterOptions = _loadOptions(options);

    // Load model from assets
    _interpreter = await Interpreter.fromAsset(_modelAssetPath!,
        options: interpreterOptions);
    _isolateInterpreter =
        await IsolateInterpreter.create(address: _interpreter!.address);

    // Get tensor input shape [1, 224, 224, 3]
    _inputTensor = _interpreter!.getInputTensors().first;
    // Get tensor output shape [1, 1000]
    _outputTensor = _interpreter!.getOutputTensors().first;

    log('input shape $_inputTensor');
    log('ouput shape $_outputTensor');
    log('Interpreter loaded successfully');
  }

  // Load labels from assets
  Future<void> _loadLabels(String labelsAssetPath, String separator) async {
    final labelTxt = await rootBundle.loadString(labelsAssetPath);
    _labels = labelTxt.split(separator);
  }

  Future<void> initHelper(
      {required String modelAssetPath,
      required String labelsAssetPath,
      String separator = '\n',
      ImageClassificationOption? options}) async {
    _modelAssetPath = modelAssetPath;
    _options = options ?? ImageClassificationOption();
    _loadModel(_options!);
    _loadLabels(labelsAssetPath, separator);
  }

  // inference still image
  Future<Map<String, double>?> inferenceImage(String imgPath) async {
    // If no Interpreter, then the helper was never initialized
    if (_interpreter == null) {
      throw StateError(
          'Interpreter not initialized. Try to call initHelper() on your ImageClassificationHelper');
    }

    // Read image bytes from file
    final imageData = await File(imgPath).readAsBytes();
    final Image image = decodeImage(imageData)!;

    final matrix = ImageUtils.toResizedMatrix(image, _inputTensor!.shape[1],
        _inputTensor!.shape[2], _options!.normalizeMethod);
    final input = [matrix];
    final output = [List<num>.filled(_outputTensor!.shape[1], 0)];

    // Run inference
    if (_options!.useGpu) {
      //TFLite Flutter does not allow GPU inference outside the caller thread
      _interpreter!.run(input, output);
    } else {
      await _isolateInterpreter!.run(input, output);
    }

    // Get first output tensor (it contains all predictions)
    final result = output.first;
    final classification = PredictionUtils.mapScoreWithLabel(
        result, _labels!, _options!.isBinary, _options!.binaryThreshold);

    return classification;
  }

  Future<void> changeOptions(ImageClassificationOption options) async {
    //Closing previous interpreter
    if (_isolateInterpreter != null) {
      _isolateInterpreter!.close();
    }
    _options = options;
    await _loadModel(options);
  }

  void close() {
    if (_isolateInterpreter != null) {
      _isolateInterpreter!.close();
    }
  }
}
