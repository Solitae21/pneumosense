// // import 'package:tflite/tflite.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// // import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:flutter/services.dart';
// import 'dart:typed_data';

// // Future<void> loadModel() async {
// //   await Tflite.loadModel(
// //     model: 'assets/pneumosensemodel.tflite',
// //     labels: 'assets/labels.txt',
// //   );
// // }

// // Uint8List convertDoublesToUint8List(List<double> doubles) {
// //   List<int> intValues = doubles.map((double value) => value.toInt()).toList();
// //   return Uint8List.fromList(intValues);
// // }

// // void predict(
// //     {required double tempAvg,
// //     required double pulseAvg,
// //     required double oxyAvg}) async {
// //   // var inputs = {
// //   //   'rectal_temp': tempAvg,
// //   //   'pulse': pulseAvg,
// //   //   'respiratory_rate': oxyAvg,
// //   // };
// //   double rectal_temp = tempAvg;
// //   double pulse = pulseAvg;
// //   double respiratory_rate = oxyAvg;

// //   // var input = inputs.values.toList();

// //   // var output = await Tflite.runModelOnBinary(
// //   //   binary: Float32List.fromList(input),
// //   //   numResults: 1,
// //   //   threshold: 0.05,
// //   //   asynch: true,
// //   // );

// //   Uint8List inputBytes =
// //       convertDoublesToUint8List([rectal_temp, pulse, respiratory_rate]);

// //   List<dynamic>? result = await Tflite.runModelOnBinary(
// //     binary: inputBytes,
// //     numResults: 2, // Assuming two classes: normal and pneumonia
// //   );

// //   if (result != null && result.isNotEmpty) {
// //     // Access the result
// //     double normalProbability = result[0];
// //     double pneumoniaProbability = result[1];

// //     // Interpret the result
// //     String diagnosis;
// //     if (normalProbability > pneumoniaProbability) {
// //       diagnosis = 'Normal';
// //     } else {
// //       diagnosis = 'Pneumonia';
// //     }

// //     print('Model result: $diagnosis');
// //     print(normalProbability);
// //     print(pneumoniaProbability);
// //   }
// // }



