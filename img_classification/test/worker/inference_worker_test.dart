import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart';
import 'package:img_classification/src/model/inference_model.dart';
import 'package:img_classification/src/worker/inference_worker.dart';

void main() {
  group('InferenceWorker', () {
    test('InferenceWorker is correctly instantiated', () async {
      final worker = await InferenceWorker.spawn();
      expect(worker, isA<InferenceWorker>());
      worker.close();
    });

    test('InferenceWorker is correctly closed', () async {
      final model = InferenceModel(Image(width: 2, height: 2), 12345,
          ['label1', 'label2'], [2, 2], [2, 2]);
      final worker = await InferenceWorker.spawn();
      worker.close();
      expect(() => worker.inferenceImage(model), throwsStateError);
    });
  });
}
