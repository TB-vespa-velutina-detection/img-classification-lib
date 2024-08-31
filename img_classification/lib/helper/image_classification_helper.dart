import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:img_classification/worker/inference_worker.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../model/inference_model.dart';

class ImageClassificationHelper {
  late final Interpreter interpreter;
  late final List<String> labels;
  late final InferenceWorker inferenceWorker;
  late Tensor inputTensor;
  late Tensor outputTensor;

  // Load model
  Future<void> _loadModel(String modelAssetPath) async {
    final options = InterpreterOptions();

    // Use XNNPACK Delegate
    if (Platform.isAndroid) {
      options.addDelegate(XNNPackDelegate());
    }

    // Use GPU Delegate
    // doesn't work on emulator
    if (Platform.isAndroid) {
      options.addDelegate(GpuDelegateV2());
    }

    // Use Metal Delegate
    if (Platform.isIOS) {
      options.addDelegate(GpuDelegate());
    }

    // Load model from assets
    interpreter = await Interpreter.fromAsset(modelAssetPath);
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

  Future<void> initHelper(String, modelAssetPath, String labelsAssetPath,
      {String separator = '\n'}) async {
    _loadLabels(labelsAssetPath, separator);
    _loadModel(modelAssetPath);
    inferenceWorker = await InferenceWorker.spawn();
  }

  // inference still image
  Future<Map<String, double>?> inferenceImage(Image image) async {
    // Init inferenceModel
    var model = InferenceModel(image, interpreter.address, labels,
        inputTensor.shape, outputTensor.shape);

    return await inferenceWorker.inferenceImage(model);
  }
}
