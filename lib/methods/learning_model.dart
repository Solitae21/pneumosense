import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'dart:typed_data';

class PneumoniaDetector {
  dynamic _interpreter;

  Future<File> getFile(String fileName) async {
    final appDir = await getTemporaryDirectory();
    final appPath = appDir.path;
    final fileOnDevice = File('$appPath/$fileName');
    final rawAssetFile = await rootBundle.load(fileName);
    final rawBytes = rawAssetFile.buffer.asUint8List();
    await fileOnDevice.writeAsBytes(rawBytes, flush: true);
    return fileOnDevice;
  }

  Future<void> loadModel() async {
    // Load the model using Interpreter instead of deprecated Tflite.loadModel

    _interpreter = await tfl.Interpreter.fromAsset(
        'assets/converted_pneumosensemodel2.tflite');

    // Allocate tensors for performance
    _interpreter.allocateTensors();
  }

  Future<String> predict({
    required double tempAvg,
    required double pulseAvg,
    required double oxyAvg,
  }) async {
    // Ensure model is loaded
    if (_interpreter == null) {
      throw Exception('Model not loaded. Please call loadModel() first.');
    }

    final inputs = [
      Float32List.fromList([tempAvg, oxyAvg, pulseAvg])
    ];

    // Use appropriate output structure and allocate tensors
    var outputs = Map<int, Object>.from({
      0: [
        [0.5]
      ],
      1: [
        [0.5]
      ]
    });
// Allocate memory for output tensors

    // Run inference with correct method (assuming single output)
    _interpreter.runForMultipleInputs(inputs, outputs);
    final probabilityList =
        outputs[0] as List<List<double>>; // Assuming nested list
    final probability = probabilityList[0][0]; // Access first element

    String diagnosis = probability > 0.5 ? 'Pneumonia' : 'Normal';
    String formattedProbability = probability.toStringAsFixed(2);
    print('Probability: ${formattedProbability}');
    print('Model result: $diagnosis');
    _interpreter.close();
    return formattedProbability;
  }
}
