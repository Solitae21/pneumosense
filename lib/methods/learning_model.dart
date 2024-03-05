// import 'package:tflite/tflite.dart';
// // import 'package:tflite_flutter/tflite_flutter.dart';
// // import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:flutter/services.dart';
// import 'dart:typed_data';

// Future<void> loadModel() async {
//   await Tflite.loadModel(
//     model: 'assets/pneumosensemodel.tflite',
//     labels: 'assets/labels.txt',
//   );
// }

// Uint8List convertDoublesToUint8List(List<double> doubles) {
//   List<int> intValues = doubles.map((double value) => value.toInt()).toList();
//   return Uint8List.fromList(intValues);
// }

// void predict(
//     {required double tempAvg,
//     required double pulseAvg,
//     required double oxyAvg}) async {
//   // var inputs = {
//   //   'rectal_temp': tempAvg,
//   //   'pulse': pulseAvg,
//   //   'respiratory_rate': oxyAvg,
//   // };
//   double rectal_temp = tempAvg;
//   double pulse = pulseAvg;
//   double respiratory_rate = oxyAvg;

//   // var input = inputs.values.toList();

//   // var output = await Tflite.runModelOnBinary(
//   //   binary: Float32List.fromList(input),
//   //   numResults: 1,
//   //   threshold: 0.05,
//   //   asynch: true,
//   // );

//   Uint8List inputBytes =
//       convertDoublesToUint8List([rectal_temp, pulse, respiratory_rate]);

//   List<dynamic>? result = await Tflite.runModelOnBinary(
//     binary: inputBytes,
//     numResults: 2, // Assuming two classes: normal and pneumonia
//   );

//   if (result != null && result.isNotEmpty) {
//     // Access the result
//     double normalProbability = result[0];
//     double pneumoniaProbability = result[1];

//     // Interpret the result
//     String diagnosis;
//     if (normalProbability > pneumoniaProbability) {
//       diagnosis = 'Normal';
//     } else {
//       diagnosis = 'Pneumonia';
//     }

//     print('Model result: $diagnosis');
//     print(normalProbability);
//     print(pneumoniaProbability);
//   }
// }

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

  // No need for convertDoublesToUint8List, as we'll handle data types appropriately

//   Future<String> predict({
//     required double tempAvg,
//     required double pulseAvg,
//     required double oxyAvg,
//   }) async {
//     if (_interpreter == null) {
//       throw Exception('Model not loaded. Please call loadModel() first.');
//     }

//     var inputTemp = Float32List.fromList([tempAvg]);
//     var inputPulse = Float32List.fromList([pulseAvg]);
//     var inputOxyAvg = Float32List.fromList([oxyAvg]);

// // input: List<Object>
//     var inputs = [inputTemp, inputPulse, inputOxyAvg];

//     var output0 = Float32List.fromList([50.0]);
//     var output1 = Float32List.fromList([50.0]);

// // output: Map<int, Object>
//     var outputs = {0: output0, 1: output1};
// // output: Map<int, Object>
//     // Map<int, Object?> outputs = {0: null, 1: null};

//     _interpreter.runForMultipleInputs(inputs, outputs);

//     // Process output for prediction
//     final normalProbability = outputs[0];
//     final pneumoniaProbability = outputs[1];

//     String diagnosis = 'testing if working';
//     // if (normalProbability > pneumoniaProbability) {
//     //   diagnosis = 'Normal';
//     // } else {
//     //   diagnosis = 'Pneumonia';
//     // }

//     // print('Model result: $diagnosis');
//     print('Normal probability: $normalProbability');
//     print('Pneumonia probability: $pneumoniaProbability');

//     return diagnosis;
//   }

  // Future<String> predict({
  //   required double tempAvg,
  //   required double pulseAvg,
  //   required double oxyAvg,
  // }) async {
  //   try {
  //     // Ensure model is loaded
  //     if (_interpreter == null) {
  //       throw Exception('Model not loaded. Please call loadModel() first.');
  //     }

  //     // Prepare inputs with descriptive variables
  //     final inputTemperature = Float32List.fromList([tempAvg]);
  //     final inputPulseRate = Float32List.fromList([pulseAvg]);
  //     final inputOxygenLevel = Float32List.fromList([oxyAvg]);
  //     final inputs = [inputTemperature, inputPulseRate, inputOxygenLevel];

  //     // Use appropriate output structure and allocate tensors
  //     var output0 = Float32List.fromList([0]);
  //     var output1 = Float32List.fromList([0]);
  //     var outputs = Map<int, Object?>.from({0: output0, 1: output1});
  //     _interpreter.allocateTensors(); // Allocate memory for output tensors

  //     // Run inference
  //     if (_interpreter.runInference(inputs)) {
  //       var outputTensors = _interpreter.getOutputTensors();
  //       outputTensors[0].copyTo(outputs[0]!);

  //       // Process outputs for prediction
  //       final probability = outputs[0] as Float32List; // Cast to expected type

  //       // Determine diagnosis based on probabilities
  //       String diagnosis = probability[0] > 0.5 ? 'Normal' : 'Pneumonia';

  //       print('Normal probability: ${probability[0]}');
  //       // print('Pneumonia probability: ${pneumoniaProbability[0]}');
  //       print('Model result: $diagnosis');

  //       return diagnosis;
  //     } else {
  //       throw Exception('Error running inference on TensorFlow Lite model');
  //     }
  //   } catch (error) {
  //     print('Error during prediction: $error');
  //     return 'Failed to make prediction';
  //   }
  // }

  // Future<String> predict({
  //   required double tempAvg,
  //   required double pulseAvg,
  //   required double oxyAvg,
  // }) async {
  //   try {
  //     // Ensure model is loaded
  //     if (_interpreter == null) {
  //       throw Exception('Model not loaded. Please call loadModel() first.');
  //     }

  //     // Prepare inputs with descriptive variables
  //     // final inputTemperature = Float32List.fromList([tempAvg]);
  //     // final inputPulseRate = Float32List.fromList([pulseAvg]);
  //     // final inputOxygenLevel = Float32List.fromList([oxyAvg]);
  //     // final inputs = [inputTemperature, inputPulseRate, inputOxygenLevel];
  //     final inputs = [
  //       [tempAvg, pulseAvg, oxyAvg]
  //     ];

  //     // Use appropriate output structure and allocate tensors
  //     var outputs = Map<int, Object>.from({
  //       0: [[]],
  //       1: [[]]
  //     });

  //     _interpreter.allocateTensors(); // Allocate memory for output tensors

  //     // Run inference with correct method (assuming single output)
  //     if (_interpreter.runForMultipleInputs(inputs, outputs)) {
  //       // outputs.forEach(
  //       //     (key, value) => print('Output $key: shape ${value.toString()}'));
  //       // Check if key 0 exists (assuming single output)
  //       if (outputs.containsKey(0)) {
  //         // Process output for prediction
  //         final probability =
  //             outputs[0] as Float32List; // Cast to expected type

  //         // Determine diagnosis based on probability
  //         String diagnosis = probability[0] > 0.5 ? 'Normal' : 'Pneumonia';

  //         print('Normal probability: ${probability[0]}');
  //         print('Model result: $diagnosis');

  //         return diagnosis;
  //       } else {
  //         print(
  //             'Output 0 not found in outputs map (model might have unexpected output structure)');
  //         // Consider returning a default prediction string here (optional)
  //         // return 'Model prediction unavailable';
  //       }
  //     } else {
  //       throw Exception('Error running inference on TensorFlow Lite model');
  //     }
  //   } catch (error) {
  //     print('Error during prediction: $error');
  //     return 'Failed to make prediction';
  //   }

  //   // Guaranteed return (prevents potential null return)
  //   return 'Prediction unavailable (should not be reached)'; // Placeholder
  // }

  Future<String> predict({
    required double tempAvg,
    required double pulseAvg,
    required double oxyAvg,
  }) async {
    // Ensure model is loaded
    if (_interpreter == null) {
      throw Exception('Model not loaded. Please call loadModel() first.');
    }

    // Prepare inputs with descriptive variables
    // final inputTemperature = Float32List.fromList([tempAvg]);
    // final inputPulseRate = Float32List.fromList([pulseAvg]);
    // final inputOxygenLevel = Float32List.fromList([oxyAvg]);
    // final inputs = [inputTemperature, inputPulseRate, inputOxygenLevel];
    final inputs = [
      Float32List.fromList([tempAvg, pulseAvg, oxyAvg])
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
    // outputs.forEach(
    //     (key, value) => print('Output $key: shape ${value.toString()}'));
    // Check if key 0 exists (assuming single output)
    // Process output for prediction
    final probabilityList =
        outputs[0] as List<List<double>>; // Assuming nested list
    final probability = probabilityList[0][0]; // Access first element
    // Cast to expected type

    // Determine diagnosis based on probability
    String diagnosis = probability > 0.5 ? 'Pneumonia' : 'Normal';
    String formattedProbability = probability.toStringAsFixed(2);
    print('Probability: ${formattedProbability}');
    print('Model result: $diagnosis');

    return diagnosis;
  }

  // Guaranteed return (prevents potential null return)

  // Prepare input data (assuming model expects raw values)
  // final inputs = Float32List.fromList([tempAvg, pulseAvg, oxyAvg]);

  // Pass input data to model (adjust for multiple tensors if needed)
  // final inputTensor = _interpreter!.getInputTensor(0);
  // final inputDataType = inputTensor.type;
  // final buffer = inputTensor.data;

  // if (inputDataType.value == 1) {
  //   // Use numerical value for float32
  //   final float32List =
  //       Float32List.fromList(inputList); // Convert double list to Float32List
  //   for (int i = 0; i < float32List.length; i++) {
  //     buffer.buffer.asFloat32List()[i] =
  //         float32List[i]; // Assign individual floats
  //   }
  // } else if (inputDataType.value == 0) {
  //   // Handle quantization (adjust based on your model's quantization details)
  //   final uint8List = Uint8List.fromList(
  //     inputList.map((value) => value.round()).toList(),
  //   );
  //   for (int i = 0; i < uint8List.length; i++) {
  //     buffer.buffer.asUint8List()[i] = uint8List[i];
  //   }
  // } else {
  //   throw Exception('Unsupported input data type: ${inputDataType}');
  // }

  // // Run inference
  // _interpreter!.invoke();

  // Get output data (assuming a single output tensor and two classes)
  // final outputTensor = _interpreter!.getOutputTensor(0);
  // final outputList = outputTensor.data as Float32List;

//   Future<String> predict({
//     required double tempAvg,
//     required double pulseAvg,
//     required double oxyAvg,
//   }) async {
//     if (_interpreter == null) {
//       throw Exception('Model not loaded. Please call loadModel() first.');
//     }
//     else{

//     // Prepare input data (assuming model expects raw values)
//     final inputList = Float32List.fromList([tempAvg, pulseAvg, oxyAvg]);

//     var output0 = List<double>.filled(1, 0);
//     var output1 = List<double>.filled(1, 0);

// // output: Map<int, Object>
//     var outputs = {0: output0, 1: output1};
//     _interpreter!.runForMultipleInputs(inputList, outputs);
//     final normalProbability = outputs[0];
//     final pneumoniaProbability = outputs[1];

//     String diagnosis =
//         normalProbability > pneumoniaProbability ? 'Normal' : 'Pneumonia';

//     print('Model result: $diagnosis');
//     print('Normal probability: $normalProbability');
//     print('Pneumonia probability: $pneumoniaProbability');

//     return diagnosis;
//   }
//   }
}
