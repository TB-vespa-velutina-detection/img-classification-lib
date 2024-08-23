import 'dart:async';
import 'dart:isolate';

import 'package:img_classification/helper/image_formatter_helper.dart';
import 'package:img_classification/model/inference_model.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class InferenceWorker {
  // Isolate properties
  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int, Completer<Object?>> _activeRequests =
      {}; // keeps track of requests order
  int _idCounter = 0;
  bool _closed = false;

  Future<Map<String, double>?> inferenceImage(InferenceModel model) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Map<String, double>?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, model));
    return await completer.future;
  }

  static Future<InferenceWorker> spawn() async {
    // Create a receive port and add its initial message handler.
    final initPort = RawReceivePort();
    // Makes sure the isolate is set-up with complete() method
    final connection = Completer<(ReceivePort, SendPort)>.sync();

    // Allow seperation between listening to first message (connection establishment) and listening to commands.
    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((
        ReceivePort.fromRawReceivePort(initPort),
        commandPort,
      ));
    };

    try {
      // Call to initialize the worker ports
      await Isolate.spawn(_startRemoteIsolate, (initPort.sendPort));
    } on Object {
      // Ensure the port is closed if the isolate fails to spawn.
      initPort.close();
      rethrow;
    }

    // Get receive ports from main isolate
    final (ReceivePort receivePort, SendPort sendPort) =
        await connection.future;

    // Instantiate the worker
    return InferenceWorker._(receivePort, sendPort);
  }

  void close() {
    if (!_closed) {
      _closed = true;
      _commands.send('shutdown');
      if (_activeRequests.isEmpty) _responses.close();
    }
  }

  /*------------PRIVATE METHOD--------------*/

  /// Private constructor for the worker.
  InferenceWorker._(this._responses, this._commands) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  /// Handle messages (responses) sent back from the worker isolate
  void _handleResponsesFromIsolate(dynamic message) {
    final (int id, Object? response) = message as (int, Object?);
    final completer = _activeRequests.remove(id)!;

    if (response is RemoteError) {
      completer.completeError(response);
    } else {
      completer.complete(response);
    }
  }

  /// Handle messages (commands) received from the main isolate.
  static void _handleCommandsToIsolate(
      ReceivePort receivePort, SendPort sendPort) {
    receivePort.listen((message) {
      if (message == 'shutdown') {
        receivePort.close();
        return;
      }
      //TODO: Adapt for model inference
      final (int id, InferenceModel model) = message as (int, InferenceModel);
      final matrix = ImageFormatterHelper.toResizedMatrix(
          model.image!, model.inputShape.first, model.outputShape.first);

      final input = [matrix];
      final output = [List<int>.filled(model.outputShape[1], 0)];

      // Run inference
      Interpreter interpreter =
          Interpreter.fromAddress(model.interpreterAddress);
      interpreter.run(input, output);


      //TODO: Isolate this code for better testing
      // Get first output tensor (it contains all predictions)
      final result = output.first;
      int maxScore = result.reduce((a, b) => a + b); // For % score
      // Set classification map {label: points}
      var classification = <String, double>{};
      // Transform every value to % and assign to corresponding label
      for (var i = 0; i < result.length; i++) {
        if (result[i] != 0) {
          // Set label: points
          classification[model.labels[i]] =
              result[i].toDouble() / maxScore.toDouble();
        }
      }

      sendPort.send((id, classification));
    });
  }

  /// Initialize the worker ports
  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    // Send port to main isolate
    sendPort.send(receivePort.sendPort);
    _handleCommandsToIsolate(receivePort, sendPort);
  }
}
