import 'dart:async';
import 'dart:isolate';

import 'package:image/image.dart' as image_lib;

class InferenceWorker {
  // Isolate properties
  final SendPort _commands;
  final ReceivePort _responses;
  bool _closed = false;
  final Map<int, Completer<Object?>> _activeRequests = {}; // keeps track of requests order
  int _idCounter = 0;
  // Task specific properties

  Future<Object?> parseJson(String message) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, message));
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
      print('--- port closed --- ');
    }
  }


  /*------------PRIVATE METHOD--------------*/

  /// Private constructor for the worker.
  InferenceWorker._(this._responses, this._commands) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  /// Handle messages (responses) sent back from the worker isolate
  /// This is where the response from the worker isolate is handled.
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
      final (int id, String jsonText) = message as (int, String);
      try {
        final jsonData = "toto";
        sendPort.send((id, jsonData));
      } catch (e) {
        sendPort.send((id, RemoteError(e.toString(), '')));
      }
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

/// A model class that holds the necessary data for performing image inference.
///
/// This class encapsulates the image to be processed, the address of the
/// TensorFlow Lite interpreter, the labels for classification, the input
/// tensor shape, and the output tensor shape. It also includes a `SendPort`
/// for sending the inference results back to the main isolate.
///
/// [image]: The image to be processed.
/// [interpreterAddress]: The memory address of the TensorFlow Lite interpreter.
/// [labels]: The list of labels for classification.
/// [inputShape]: The shape of the input tensor.
/// [outputShape]: The shape of the output tensor.
/// [responsePort]: The port for sending the inference results back to the main isolate.
class InferenceModel {
  image_lib.Image? image;
  int interpreterAddress;
  List<String> labels;
  List<int> inputShape;
  List<int> outputShape;
  late SendPort responsePort;

  InferenceModel(this.image, this.interpreterAddress,
      this.labels, this.inputShape, this.outputShape);
}

