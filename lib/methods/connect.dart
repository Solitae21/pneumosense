import 'dart:ffi';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pneumosense/methods/fileManagement.dart';
import 'dart:async';
import 'dart:convert';
import '../pages/home_page/home_page_widget.dart' as homePage;
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';

var tempVal = '0';
var oxyVal = '0';
var pulseVal = '0';
final String wemosIPAddress = '192.168.4.1';
dynamic progress = 0.0;
// void initState() {
//   super.initState();
//   //_getTemp(); // Call your function here
//   _checkConnection();
//   _startTempUpdateTimer();
// }
DateTime now = DateTime.now();

String connectionStatus = 'Not Connected';
dynamic _temp;
String? _toRound;
Future<void> checkConnection() async {
  final String wemosIPAddress =
      '192.168.4.1'; // Replace with your Wemos D1 Mini IP address

  try {
    final response = await http.get(Uri.parse('http://$wemosIPAddress/'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      connectionStatus = 'Connected';
      _temp = jsonData['tempVal'];
      _toRound = _temp.toStringAsFixed(2);
      _temp = double.parse(_toRound!);
      tempVal = _temp.toString();
      print(tempVal);
      oxyVal = jsonData['oxyVal'].toString();
      print(oxyVal);
      pulseVal = jsonData['pulseVal'].toString();
      print(pulseVal);
    } else {
      connectionStatus = 'Not Connected to Wemos D1 Mini';
      tempVal = '0';
      oxyVal = '0';
      pulseVal = '0';
    }
  } catch (e) {
    connectionStatus = 'Error: $e';
    tempVal = '0';
    oxyVal = '0';
    pulseVal = '0';
  }
}

void startTempUpdateTimer() {
  const Duration updateInterval = Duration(seconds: 1);

  Timer.periodic(updateInterval, (Timer timer) async {
    await checkConnection(); // Update temperature periodically
  });
}

Future<void> sendDiagDataToWemos() async {
  // Read the JSON file from assets
  try {
    final diagLog = await FileManager().readJsonFile();
    print(diagLog);
    String jsonData = jsonEncode(diagLog);
    final response = await http.post(
      Uri.parse('http://${wemosIPAddress}/data'),
      body: jsonData,
      headers: {'Content-Type': 'application/json'},
    );

    // Handle response (success or error)
    if (response.statusCode == 200) {
      print('Data sent successfully!');
    } else {
      print('Error sending data: ${response.statusCode}');
    }
  } catch (e) {
    print(e);
  }
  // Send data to Wemos server using http.post
}

void sendInstruction() async {
  final response = await http.post(
    Uri.parse('http://${wemosIPAddress}/endpoint'),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, dynamic>{
      'instruction': 'createJsonFile',
    }),
  );

  if (response.statusCode == 200) {
    print('Instruction sent successfully');
    final jsonData = json.decode(response.body);
    progress = jsonData['progress'];
    print(progress);
  } else {
    print('Failed to send instruction: ${response.statusCode}');
  }
}

Future<int> resetProgress() async {
  try {
    final response = await http.get(Uri.http(wemosIPAddress, '/reset'));

    if (response.statusCode == 200) {
      print('Progress reset successfully');
      return 200;
      // You can add any additional actions here after the reset
    } else {
      print('Failed to reset progress. Status code: ${response.statusCode}');
      return 0;
    }
  } catch (error) {
    print('Error: $error');
    return 0;
  }
}

Future<void> getData() async {
  final String wemosIPAddress =
      '192.168.4.1'; // Replace with your Wemos D1 Mini IP address
  try {
    final response =
        await http.get(Uri.parse('http://$wemosIPAddress/getData'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
    } else {
      connectionStatus = 'Not Connected to Wemos D1 Mini';
    }
  } catch (e) {
    connectionStatus = 'Error: $e';
  }
}

void startDiagnosticTimer(Function updateProgress) {
  const Duration updateInterval = Duration(seconds: 1);

  Timer.periodic(updateInterval, (Timer timer) async {
    await getData(); // Update temperature periodically
  });
}

double getAverage(List<double> value) {
  double average = 0;
  value.forEach((element) {
    average = average + element;
  });
  return average / value.length;
}

String formattedTime() {
  String formattedTime = DateFormat('hh:mm:ss a').format(now);
  return formattedTime;
}

String formattedDate() {
  String formattedDate = DateFormat('MMMM dd,yyyy').format(now);
  return formattedDate;
}

// Future<void> createDiagLog(
//     {required double tempAvg,
//     required double pulseAvg,
//     required double oxyAvg,
//     required String result}) async {
//   final file = File('DiagLog.json');
//   final jsonData = {
//     'temp': tempAvg,
//     'pulse': pulseAvg,
//     'oxy': oxyAvg,
//     'result': result,
//     'date': formattedDate(),
//     'time': formattedTime()
//   };
//   try {
//     // Encode the data
//     final jsonAsString = jsonEncode(jsonData);

//     // Open the file in write mode
//     await file.writeAsString(jsonAsString);
//     print('JSON data written to file: $file');
//   } catch (error) {
//     print('Error writing JSON to file: $error');
//   }
// }


